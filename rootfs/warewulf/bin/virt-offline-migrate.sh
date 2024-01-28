#!/bin/bash

# Author: griznog
# Purpose: Do an offline migration of a VM which doesn't use shared storage.

# Usage and errors.
function usage () {
    cat <<- EOF
		Usage: $0 domain hypervisor
		  domain: The guest domain to migrate.
		  hypervisor: The target hypervisor hostname.

		EOF
    if [[ -n "$1" ]]; then 
        echo $1
    fi

    exit 1
}

# Check for xpath requirement.
if ! which xpath > /dev/null 2>&1; then
    usage "Install xpath: 'dnf -y install perl-XML-XPath'"
fi

# Check our arguments.
srcdomain=$1
hypervisor=$2

# Did we get a hypervisor?
if [[ -z ${hypervisor} ]]; then
    usage "Must specify a hypervisor to migrate to."
fi

# Is it a legit hypervisor?
if ! ssh ${hypervisor} virsh list --name > /dev/null 2>&1; then
    usage "No running hypervisor found on ${hypervisor}"
fi

# Is the domain legit?
if ! virsh list --all --name | grep -q ${srcdomain}; then 
    usage "Domain ${srcdomain} not found on this host."
fi

# Check list of existing domains on target for a collision with our migrating
# domain.
domains=( $(ssh ${hypervisor} virsh list --all --name) )
for domain in ${domains[*]}; do
    if [[ ${domain} == ${srcdomain} ]]; then
        usage "${srcdomain} already exists on ${hypervisor}."
    fi
done

# If we reach this point we can be reasonably sure the new hypervisor can be 
# reached and the domain can be created.

# TODO: Check for pass-thru devices, these are highly likely to collide for IB VFs

# Find all the files we need to move.
disks=( $(virsh dumpxml ${srcdomain} | xpath -q -e "/domain/devices/disk/source/@file/" | cut -f2 -d'=' | tr -d '"') )
nvram=$(virsh dumpxml ${srcdomain} | xpath -q -e "/domain/os/nvram/text()")
[[ -n ${nvram} ]] && nvramflag="--nvram"

# Sync domain disk and nvram (if required) to target hypervisor. 
for file in  ${nvram} ${disks[*]}; do
    rsync -av --progress ${file} ${hypervisor}:${file}
done

virsh dumpxml ${srcdomain} | ssh ${hypervisor} "cat > /tmp/${srcdomain}-import.xml" && \
    ssh ${hypervisor} virsh define /tmp/${srcdomain}-import.xml 

if [[ $? -eq 0 ]]; then
    echo "${srcdomain} has been copied to ${hypervisor}"
    echo "Please check for success and then remove the old copy from $(hostname -s) with:"
    echo "virsh undefine ${srcdomain} --storage $(echo ${disks} | tr ' ' ',') ${nvramflag}"
else 
    echo "Migration failed."
fi

#!/bin/bash

# Author: griznog
# Purpose: Archive a virtual machine config and image(s).

# Usage and errors.
function usage () {
    cat <<- EOF
		Usage: $0 domain directory
		  domain: The guest domain to migrate.
		  directory: Directory location to place the archived vm guest.

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
archive_directory=$2

# Make sure the archive location is a directory.
if [[ -z ${archive_directory} ]] || [[ ! -d ${archive_directory} ]]; then
    usage "Must specify a valid archive directory location."
fi

# Is the domain legit?
if ! virsh list --all --name | grep -q ${srcdomain}; then 
    usage "Domain ${srcdomain} not found on this host."
fi

# Find all the files we need to move.
disks=( $(virsh dumpxml ${srcdomain} | xpath -q -e "/domain/devices/disk/source/@file/" | cut -f2 -d'=' | tr -d '"') )
nvram=$(virsh dumpxml ${srcdomain} | xpath -q -e "/domain/os/nvram/text()")
config=/etc/libvirt/qemu/${srcdomain}.xml
[[ -f ${config} ]] || usage "Can't locate VM config file ${config}"

[[ -n ${nvram} ]] && nvramflag="--nvram"

# Tar up all the bits. 
tar -cvf - ${nvram} ${disks[*]} ${config} > ${archive_directory}/${srcdomain}.tar
if [[ $? -eq 0 ]]; then
    echo "${srcdomain} has been archived to ${archive_directory}/${srcdomain}.tar"
else 
    echo "Archiving failed."
fi

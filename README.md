# service-libvirtd

## Description

Add some hooks to control libvirtd startup and configure any SR-IOV devices
that need it.

## Overlay Tags

The following tags can be set in the node config to control the libvirtd setup:

### `ovl_libvirtd_service_enable`

Set to "true" to enable, defaults to false.

### `ovl_libvirtd_sriov_setup'

Controls whether SR-IOV firtual functions are configured, defaults to 'true'

Requires prior setup of the device to be in SR-IOV mode and have some 
number of VFs available. See:

* https://clouddocs.f5.com/cloud/public/v1/kvm/kvm_mellanox.html
* https://docs.nvidia.com/networking/pages/viewpage.action?pageId=43718746
* https://shawnliu.me/post/configuring-sr-iov-for-mellanox-adapters/
* https://enterprise-support.nvidia.com/s/article/HowTo-Configure-SR-IOV-for-ConnectX-4-ConnectX-5-ConnectX-6-with-KVM-Ethernet

Infiniband requires SM for fabric to have virtualization enabled.

* For opensm: `virt_enabled 2`



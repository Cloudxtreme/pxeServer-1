#! /bin/bash
#
# DESIGNED for use with ubuntu 14.04
#
# INSTALL Script for ubuntu diskless PXE Experimental Server
#


init() {
	echo $hostname > /etc/hostname
	echo $hostsln1 > /etc/hosts
	echo $hostsln2 >> /etc/hosts

    hostname $hostname

	apt-get update -y

	apt-get install -y isc-dhcp-server tftpd-hpa syslinux nfs-kernel-server initramfs-tools

	echo "auto lo eth0 eth1
iface lo inet loopback

iface eth0 inet static
    address 192.168.0.1
    netmask 255.255.0.0

iface eth1 inet dhcp" > /etc/network/interfaces


}


configDhcp() {

	echo 'subnet 192.168.0.0 netmask 255.255.0.0 {
        range 192.168.0.1 192.168.5.254;
        filename "/pxelinux.0";
        }' >> /etc/dhcp/dhcpd.conf

    service isc-dhcp-server restart
}

configTftp() {

echo '#Defaults for tftpd-hpa
RUN_DAEMON="yes"
OPTIONS="-l -s /tftpboot"' > /etc/default/tftpd-hpa

    mkdir /tftpboot

    sudo chmod -R 777 /tftpboot
    sudo chown -R nobody /tftpboot

    sudo service tftpd-hpa restart

}

configSyslinux() {

	cp /usr/lib/syslinux/pxelinux.0 /tftpboot/pxelinux.0

    mkdir /tftpboot/pxelinux.cfg/

    touch default

    echo "LABEL linux
KERNEL vmlinuz
APPEND root=/dev/nfs initrd=initrd.img nfsroot=192.168.0.1:/tftpboot/ubuntu/nfs/ ip=dhcp rw" > /tftpboot/pxelinux.cfg/default


}

configNFS() {
	echo "/tftpboot/ubuntu/nfs/ *(rw,no_root_squash,async,insecure)" > /etc/exports

	exportfs -rv
    service nfs-kernel-server restart
}

init
configDhcp
configTftp
configSyslinux
configNFS

reboot


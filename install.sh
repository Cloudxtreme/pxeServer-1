#! /bin/bash

hostname="pxeServer"

hostsln1="127.0.0.1		localhost"
hostsln2="127.0.1.1		pxeServer.phil.dev"

tinycoreUrl="http://tinycorelinux.net/6.x/x86/archive/6.4/TinyCore-6.4.iso"

init() {
	echo $hostname > /etc/hostname
	echo $hostsln1 > /etc/hosts
	echo $hostsln2 >> /etc/hosts

	apt-get update -y

	apt-get install -y isc-dhcp-server xinetd tftpd tftp syslinux nfs-kernel-server

	echo "
	auto lo eth0
	iface lo inet loopback
	iface eth0 inet static
        address 192.168.0.1
        netmask 255.255.0.0
    iface eth0 inet dhcp" > /etc/network/interfaces


}

configDhcp() {

	echo 'filename "pxelinux.0"' > /etc/dhcp/dhcpd.conf
}

configSyslinux() {
	mkdir /tftpboot

	cp /usr/share/syslinux/pxelinux.0 /tftpboot/pxelinux.0

    mkdir /tftpboot/pxelinux.cfg/
    mkdir /tftpboot/tinycore/
    mkdir /tftpboot/tinycore/nfs/

    touch default

    echo "
	default tinycore
    
    label tinycore
    	kernel /tftpboot/tinycore/vmlinux
    	append cde initrd=/tftpboot/tinycore/core.gz nfsmount=192.168.0.1:/tftpboot/tinycore/nfs/ tce=nfs/tce" > /tftpboot/pxelinux.cfg/default

    #/////////////////   download and extract tinycore
    mkdir /temp/
    cd /temp/
    wget $tinycoreUrl
    mkdir /mnt/tinycore
    mount -o loop TinyCore-6.4.iso /mnt/tinycore

    cd /mnt/tinycore/boot/

    cp core.gz /tftpboot/tinycore/
    cp vmlinux /tftpboot/tinycore/

}

configNFS() {
	echo "/tftpboot/tinycore/nfs/ *(rw,no_root_squash)" > /etc/exports
}

configTinyCore() {
	mkdir /tftpboot/tinycore/nfs/tce/
    mkdir /tftpboot/tinycore/nfs/tce/optional


}

init
configDhcp
configSyslinux
configNFS
configTinyCore


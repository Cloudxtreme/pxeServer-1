#! /bin/bash

hostname="pxeServer"

hostsln1="127.0.0.1		localhost"
hostsln2="127.0.1.1		pxeServer      pxeServer.phil.dev"

tinycoreUrl="http://tinycorelinux.net/6.x/x86/archive/6.4/TinyCore-6.4.iso"

init() {
	echo $hostname > /etc/hostname
	echo $hostsln1 > /etc/hosts
	echo $hostsln2 >> /etc/hosts

    hostname $hostname

	apt-get update -y

	apt-get install -y isc-dhcp-server tftpd-hpa syslinux nfs-kernel-server

	echo "auto lo eth1
iface lo inet loopback
iface eth0 inet static
    address 192.168.0.1
    netmask 255.255.0.0

iface eth1 inet dhcp" > /etc/network/interfaces


}

configDhcp() {

	echo 'subnet 192.168.0.0 netmask 255.255.0.0 {
        range 192.168.0.1 192.168.5.254;
        filename "pxelinux.0";
        }' >> /etc/dhcp/dhcpd.conf
}

configTftp() {

echo 'TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure --create"' > /etc/default/tftpd-hpa

    mkdir /tftpboot

    sudo chmod -R 777 /tftpboot
    sudo chown -R nobody /tftpboot

    sudo service xinetd restart

}

configSyslinux() {

	cp /usr/lib/syslinux/pxelinux.0 /tftpboot/pxelinux.0

    mkdir /tftpboot/pxelinux.cfg/
    mkdir /tftpboot/tinycore/
    mkdir /tftpboot/tinycore/nfs/

    touch default

    echo "
default tinycore
    label tinycore
    	kernel /tinycore/vmlinuz
    	append cde initrd=tinycore/core.gz nfsmount=192.168.0.1:/tftpboot/tinycore/nfs/ tftplist=192.168.0.1:/nfs/nfs.list tce=nfs/tce" > /tftpboot/pxelinux.cfg/default

    mkdir /temp/
    cd /temp/
    wget $tinycoreUrl
    mkdir /mnt/tinycore
    mount -o loop TinyCore-6.4.iso /mnt/tinycore

    cd /mnt/tinycore/boot/

    cp core.gz /tftpboot/tinycore/
    cp vmlinuz /tftpboot/tinycore/

}

configNFS() {
	echo "/tftpboot/tinycore/nfs/ *(rw,no_root_squash)" > /etc/exports
}

configTinyCore() {
	mkdir /tftpboot/tinycore/nfs/tce/
    mkdir /tftpboot/tinycore/nfs/tce/optional

    cd /tftpboot/tinycore/nfs/

    wget http://tinycorelinux.net/6.x/x86/tcz/rpcbind.tcz
    wget http://tinycorelinux.net/6.x/x86/tcz/libtirpc.tcz
    wget http://tinycorelinux.net/6.x/x86/tcz/nfs-utils.tcz
    wget http://tinycorelinux.net/6.x/x86/tcz/nano.tcz
    
    wget http://tinycorelinux.net/4.x/x86/tcz/pv.tcz

}

init
configDhcp
configTftp
configSyslinux
configNFS
configTinyCore


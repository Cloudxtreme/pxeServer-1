#! /bin/bash
#
# DESIGNED for use with ubuntu 14.04
#
#http://www.routingloops.co.uk/linux/tftp-on-ubuntu-14-04-lts-server/


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

	apt-get install -y isc-dhcp-server tftpd-hpa syslinux nfs-kernel-server tree

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
        filename "pxelinux.0";
        }' >> /etc/dhcp/dhcpd.conf

    service isc-dhcp-server restart
}

configTftp() {

echo 'TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure --create"' > /etc/default/tftpd-hpa

    mkdir /tftpboot

    sudo chmod -R 777 /tftpboot
    sudo chown -R nobody /tftpboot

    sudo service tftpd-hpa restart

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
    menu default
    	kernel tinycore/vmlinuz
    	append initrd=tinycore/core.gz nfsmount=192.168.0.1:/tftpboot/tinycore/nfs/ tftplist=192.168.0.1:/nfs/tce/onboot.lst tce=nfs/tce
    
    label coreos
      kernel coreOS/coreos_production_pxe.vmlinuz
      append initrd=coreOS/coreos_production_pxe_image.cpio.gz" > /tftpboot/pxelinux.cfg/default


}

configNFS() {
	echo "/tftpboot/tinycore/nfs/ *(rw,no_root_squash)" > /etc/exports

    service nfs-kernel-server restart
}

configTinyCore() {

    mkdir /temp/
    cd /temp/
    wget $tinycoreUrl
    mkdir /mnt/tinycore
    mount -o loop TinyCore-6.4.iso /mnt/tinycore

    cd /mnt/tinycore/boot/

    cp core.gz /tftpboot/tinycore/
    cp vmlinuz /tftpboot/tinycore/

	mkdir /tftpboot/tinycore/nfs/tce/
    mkdir /tftpboot/tinycore/nfs/tce/optional

    cd /mnt/tinycore/cde/

    cp -R * /tftpboot/tinycore/nfs/tce/

    cd /tftpboot/tinycore/nfs/tce/optional

    wget http://tinycorelinux.net/6.x/x86/tcz/rpcbind.tcz
    wget http://tinycorelinux.net/6.x/x86/tcz/libtirpc.tcz
    wget http://tinycorelinux.net/6.x/x86/tcz/nfs-utils.tcz
    wget http://tinycorelinux.net/6.x/x86/tcz/nano.tcz
    
    wget http://tinycorelinux.net/4.x/x86/tcz/pv.tcz
    wget http://distro.ibiblio.org/tinycorelinux/2.x/tcz/sfdisk.tcz
    wget http://distro.ibiblio.org/tinycorelinux/3.x/tcz/grep.tcz
    wget http://distro.ibiblio.org/tinycorelinux/4.x/x86/tcz/sed.tcz
    wget http://distro.ibiblio.org/tinycorelinux/4.x/x86/tcz/bash.tcz
    wget http://distro.ibiblio.org/tinycorelinux/4.x/x86/tcz/ncurses.tcz
    wget http://distro.ibiblio.org/tinycorelinux/4.x/x86/tcz/ncursesw.tcz
    wget http://distro.ibiblio.org/tinycorelinux/4.x/x86/tcz/ntfs-3g.tcz

    wget http://distro.ibiblio.org/tinycorelinux/4.x/x86/tcz/urxvt.tcz


    cd /tftpboot/tinycore/nfs/tce/

    echo 'rpcbind.tcz' >> onboot.lst
    echo 'libtirpc.tcz' >> onboot.lst
    echo 'nfs-utils.tcz' >> onboot.lst
    echo 'nano.tcz' >> onboot.lst

    echo 'pv.tcz' >> onboot.lst
    echo 'sfdisk.tcz' >> onboot.lst
    echo 'grep.tcz' >> onboot.lst
    echo 'sed.tcz' >> onboot.lst
    echo 'bash.tcz' >> onboot.lst
    echo 'ncurses.tcz' >> onboot.lst
    echo 'ncursesw.tcz' >> onboot.lst
    echo 'ntfs-3g.tcz' >> onboot.lst
    echo 'urxvt.tcz' >> onboot.lst

}

configCoreOS() {

    cd /tftpboot/
    mkdir coreOS
    cd coreOS


    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz.sig
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz.sig
    gpg --verify coreos_production_pxe.vmlinuz.sig
    gpg --verify coreos_production_pxe_image.cpio.gz.sig
      

}



init
configDhcp
configTftp
configSyslinux
configNFS
configTinyCore
configCoreOS

reboot

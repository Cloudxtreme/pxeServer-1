#! /bin/bash

hostname="pxeServer"

hostsln1="127.0.0.1		localhost"
hostsln2="127.0.1.1		pxeServer.phil.dev"


init() {
	echo $hostname > /etc/hostname
	echo $hostsln1 > /etc/hosts
	echo $hostsln2 >> /etc/hosts

	apt-get install -y isc-dhcp-server xinetd tftpd tftp syslinux
}


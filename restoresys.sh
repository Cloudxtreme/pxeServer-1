#! /bin/bash

drive=/dev/sda
imagePart=$drive\9


main() {
	while true; do
		clear
		echo """
##############################################################################
# 			  System Imager			     #
##############################################################################
Select an option and this system will reboot after completion :

	c) Create Full Image (WILL ERASE PREVIOUS IMAGE)
	1) Full Restore (WILL ERASE ALL DATA!)
	2) Multicast Receive (WILL ERASE ALL DATA!)
	r) Reboot
		"""
		read -p "Enter an option: " opt


		case "$opt" in

		c)	
			echo "Creating System Image..."

		1)
			echo "Restoring full drive...."
			partDrive
			copyImgs
			#changeHostname
			
			;;
		2)
			echo "Restoring windows and linux from local drive...."
			restoreParts
			#changeHostname
			;;
		3)
			echo "Restoring Windows...."
			resWin
			#changeHostname
			;;
		4)
			echo "Restoring Linux...."
			resLinux
			#changeHostname
			;;
		5)
		    echo "Restoring windows and linux from Network..."
		    partDrive
			netRestore
			#changeHostname
		    ;;
		r)
			echo "Rebooting..."
			reboot
			;;
		esac
		reboot
	done
}

#########################################################
#	Functions
#########################################################

#### Partition Drive ####################################

partDrive() {
    
    echo "Recreating $drive Partition table...."
	# recreate bootcode and GRUB bootloader
	dd if=mbrboot of=$drive 
	
	# import the partition table from file 
	sfdisk $drive -f < partitiontable
	
	echo "Rereading $drive Partition table...."
	# Reread the partition table
	sfdisk -R $drive
	
	# give time for reread
	sleep 5
	}

#### Copy Images ########################################

copyImgs() {
    mp="/mnt/imgStore"
    
	# format the image store partition
	mkfs.ext4 $imagePart
    
    parts=(/dev/sda1 /dev/sda5 /dev/sda7)
	echo Partitions found: ${parts[*]}
	
	# mount the Image store partition
	mkdir $mp
	mount $imagePart $mp
	
# For each partition in the list
	for p in "${parts[@]}"
	do
        if [ p != imagePart ]
        then
        # gets the name of the drive in the format 'sda1'
            pName=`echo $p | sed -e 's/\/dev\///g'`
        
        # using cp copy the images 
            echo "Copying compressed image of $p..." 
            pv $pName.img.gz > $mp/$pName.img.gz
		fi
	done
	
	umount $mp
	rmdir $mp
    }
    
#### Restore Partitions #################################

restoreParts() {
    mp="/mnt/imgStore"
	
	mkdir $mp
	
	mount $imagePart $mp
    
	parts=(/dev/sda1 /dev/sda5 /dev/sda7)
	echo Partitions found: ${parts[*]}
	
# For each partition in the list
	for p in "${parts[@]}"
	do
        if [ p != imagePart ]
        then
        # gets the name of the drive in the format 'sda1' so it can be restored from file
            pName=`echo $p | sed -e 's/\/dev\///g'`
    
        # using dd and gunzip we take an image of the partition and restore it to the drive
            echo "Restoring image of $p..." 
            gunzip -c $mp/$pName.img.gz | pv | dd of=$p bs=4k conv=sync
		fi
	done
	
	umount $mp
	rmdir $mp
	}

#### Restore Windows OS #################################

resWin() {
    mp="/mnt/imgStore"
	
	mkdir $mp
	
	mount $imagePart $mp
    
	parts=(/dev/sda1)
	echo Partitions found: ${parts[*]}
	
# For each partition in the list
	for p in "${parts[@]}"
	do
        if [ p != imagePart ]
        then
        # gets the name of the drive in the format 'sda1' so it can be restored from file
            pName=`echo $p | sed -e 's/\/dev\///g'`
    
        # using dd and gunzip we take an image of the partition and restore it to the drive
            echo "Restoring image of $p..." 
            gunzip -c $mp/$pName.img.gz | pv --size 40g | dd of=$p bs=4k conv=sync
		fi
	done
	
	umount $mp
	rmdir $mp
	}

#### Restore Linux OS ###################################

resLinux() {
    mp="/mnt/imgStore"
	
	mkdir $mp
	
	mount $imagePart $mp
    
	parts=(/dev/sda7)
	echo Partitions found: ${parts[*]}
	
# For each partition in the list
	for p in "${parts[@]}"
	do
        if [ p != imagePart ]
        then
        # gets the name of the drive in the format 'sda1' so it can be restored from file
            pName=`echo $p | sed -e 's/\/dev\///g'`
    
        # using dd and gunzip we take an image of the partition and restore it to the drive
            echo "Restoring image of $p..." 
            gunzip -c $mp/$pName.img.gz | pv --size 15g | dd of=$p bs=4k conv=sync
		fi
	done
	
	umount $mp
	rmdir $mp
	}
	
#### Restore From Network ###############################
	
netRestore() {
    parts=(/dev/sda1 /dev/sda5 /dev/sda7)
    echo Partitions found: ${parts[*]}
	
# For each partition in the list
	for p in "${parts[@]}"
	do

	# gets the name of the drive in the format 'sda1' so it can be restored from file
		pName=`echo $p | sed -e 's/\/dev\///g'`
		
	# using dd and gunzip we take an image of the partition and restore it to the drive
		echo "Restoring image of $p..." 
		gunzip -c $pName.img.gz | pv | dd of=$p bs=4k conv=sync
		
	done
}

	
#### Change the Hostname ################################
	
changeHostname() {
    echo "Changing Windows Name";
    echo "";
    echo "Mounting sda1";
    echo "";

    mountans=`mount | grep /dev/sda1`
    if [ "$mountans" == "" ]; then
        location="/mnt/tmpSda1"
        mkdir $location
        ntfs-3g /dev/sda1 $location
        echo "Windows partition is mounted"
    else
        rocheck=`echo $mountans | grep rw`
        if [ "$rocheck" == "" ]; then
            echo 'ERROR : The Windows partition is read-only. Please unmount it'
            echo 'Abort'
            exit 1
        fi
        location=`echo $mountans | awk '{print $3}'`
        echo "The partition is already mounted on $location"
    fi

    mountans=`mount | grep /dev/sda7`
    if [ "$mountans" == "" ]; then
        location2="/mnt/tmpSda7"
        mkdir $location2
        mount /dev/sda7 $location2
        echo "Linux partition is mounted"
    else
        rocheck=`echo $mountans | grep rw`
        if [ "$rocheck" == "" ]; then
            echo 'ERROR : The Linux partition is read-only. Please unmount it'
            echo 'Abort'
            exit 1
        fi
        location2=`echo $mountans | awk '{print $3}'`
        echo "The partition is already mounted on $location2"
    fi

    echo "Retrieving Network Configuration to associate Name";

    ifconfig eth0 > ipaddress
    var=$(grep 'inet addr:' ipaddress | cut -c 31-33)
    ip=$(grep 'inet addr:' ipaddress | cut -c 21-33)
    mac=$(grep 'HWaddr' ipaddress | cut -c 39-55)

    echo "Changing Name";

    systemFile=$location/Windows/System32/config/SYSTEM
    echo -e "cd ControlSet001\\services\\Tcpip\\Parameters\ned Hostname\nM$var\nq\ny\n" | chntpw $systemFile > /dev/null
    echo -e "cd ControlSet001\\services\\Tcpip\\Parameters\ned NV Hostname\nM$var\nq\ny\n" | chntpw $systemFile > /dev/null
    echo -e "cd ControlSet001\\Control\\ComputerName\\ActiveComputerName\ned ComputerName\nM$var\nq\ny\n" | chntpw $systemFile > /dev/null
    echo -e "cd ControlSet001\\Control\\ComputerName\\ComputerName\ned ComputerName\nM$var\nq\ny\n" | chntpw $systemFile > /dev/null
    echo -e "cd ControlSet002\\services\\Tcpip\\Parameters\ned Hostname\nM$var\nq\ny\n" | chntpw $systemFile > /dev/null
    echo -e "cd ControlSet002\\services\\Tcpip\\Parameters\ned NV Hostname\nM$var\nq\ny\n" | chntpw $systemFile > /dev/null
    echo -e "cd ControlSet002\\Control\\ComputerName\\ActiveComputerName\ned ComputerName\nM$var\nq\ny\n" | chntpw $systemFile > /dev/null
    echo -e "cd ControlSet002\\Control\\ComputerName\\ComputerName\ned ComputerName\nM$var\nq\ny\n" | chntpw $systemFile > /dev/null
    echo "Computer name changed to M$var"

    echo "127.0.0.1 localhost" > $location2/etc/hosts
    echo "127.0.0.1 M$var" >> $location2/etc/hosts
    echo 'M'$var > $location2/etc/hostname
    rm ipaddress

    echo "Unmounting partition";

    if [ "$mountans" == "" ]; then
        umount /mnt/tmpSda1
        umount /mnt/tmpSda7
        rmdir $location
        rmdir $location2
        echo "Partitions unmounted"
    fi

    echo "Dhcp configuration Mac/Ip"
    mkdir /mountSSHFS

    mkdir /root/.ssh

    ssh-keyscan 192.168.0.1 > /root/.ssh/known_hosts
    echo Tigrou007 | sshfs chimay@192.168.0.1:/ /mountSSHFS -o password_stdin



    echo -e "\nhost M$var { \n\t hardware ethernet $mac; \n\t fixed-address $ip; \n} \n" >> /mountSSHFS/etc/dhcp/dhcpd.conf
    echo "Dhcp Configuration Finished"
    umount /mountSSHFS
    rmdir /mountSSHFS
}

main

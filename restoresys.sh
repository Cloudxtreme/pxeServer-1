#! /bin/bash -x

#imagePart=$drive\9


main() {
	while true; do
		pause
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
				read -p "Enter a drive name (/dev/sda): " drive
				drive=${drive:-/dev/sda}
				read -p "Enter a image name (testImg): " name
				name=${name:-testImg}
				echo "image Name: " $name
				echo "Drive Name: " $drive
				
				pause

				# make the directory for the imaging files
				mkdir images
				cd images
				mkdir $name
				chmod 777 $name
				cd $name
				echo Directory Created: $name
				
				partTable
				zeroParts
				imgParts

			;;

		1)
			echo "Restoring full drive...."
			#partDrive
			#copyImgs
			#changeHostname
			
			;;
		2)
			echo "Starting Multicast Receive...."
			#restoreParts
			#changeHostname
			;;
		r)
			echo "Rebooting..."
			reboot
			;;
		esac
		#reboot
	done
}

#########################################################
#	Functions
#########################################################

#########################################################
#	Create Image Functions
#########################################################

partTable() {
	# export the partition table to file 
	echo "exporting $drive Partition table...."
	sfdisk -d $drive > partitiontable
	}

#########################################################

zeroParts() {
	echo "Zeroing free space on partitions..."

#fdisk -l /dev/sdc | grep -o '/dev/sdc*[1-9]'
# Get the list of partitions to be zeroed and add them to an array
# $parts is the array of the partition names (eg. /dev/sda1, etc..)
# maximum partitions 9 change 9 to allow for more
	parts=($(fdisk -l $drive | grep -o "$drive*[1-9]"))
	echo Partitions found: ${parts[*]}
	
# For each partition in the list
	for p in "${parts[@]}"
	do
		echo $p
		
	# make a temp directory
		mkdir /mnt/temp

	# mount the current partition

		mount -t ntfs-3g $p /mnt/temp || mount $p /mnt/temp

	# Zero the empty space
		echo "Creating Zeros"
		dd if=/dev/zero | pv | dd of=/mnt/temp/delete bs=1M

	# Delete the file to restore the free space
		rm /mnt/temp/delete

	# Unmount the current partition
		umount $p
		
	#delete the temp directory
		rmdir /mnt/temp

	done
	}

#########################################################

imgParts() {
	parts=($(fdisk -l $drive | grep -o "$drive*[1-9]"))
	echo Partitions found: ${parts[*]}
	
# For each partition in the list
	for p in "${parts[@]}"
	do

	# gets the name of the drive in the format 'sda1' so it can be saved as a file
		pName=`echo $p | sed -e 's/\/dev\///g'`
		
	# using dd and gzip we take an image of the partition and compress it
		echo "Creating compressed image of $p..." 
		dd if=$p conv=sync,noerror bs=4k | pv | gzip -c > $pName.img.gz
		
	done
	}

##########################################################


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

#########################################################

partTable() {
	# export the partition table to file 
	echo "exporting $drive Partition table...."
	sfdisk -d $drive > partitiontable
	}

#########################################################

zeroParts() {
	echo "Zeroing free space on partitions..."

#fdisk -l /dev/sdc | grep -o '/dev/sdc*[1-9]'
# Get the list of partitions to be zeroed and add them to an array
# $parts is the array of the partition names (eg. /dev/sda1, etc..)
# maximum partitions 9 change 9 to allow for more
	parts=($(fdisk -l $drive | grep -o "$drive*[1-9]"))
	echo Partitions found: ${parts[*]}
	
# For each partition in the list
	for p in "${parts[@]}"
	do
		echo $p
		
	# make a temp directory
		mkdir /mnt/temp

	# mount the current partition

		mount -t ntfs-3g $p /mnt/temp || mount $p /mnt/temp

	# Zero the empty space
		echo "Creating Zeros"
		dd if=/dev/zero | pv | dd of=/mnt/temp/delete bs=1M

	# Delete the file to restore the free space
		rm /mnt/temp/delete

	# Unmount the current partition
		umount $p
		
	#delete the temp directory
		rmdir /mnt/temp

	done
	}

#########################################################

imgParts() {
	parts=($(fdisk -l $drive | grep -o "$drive*[1-9]"))
	echo Partitions found: ${parts[*]}
	
# For each partition in the list
	for p in "${parts[@]}"
	do

	# gets the name of the drive in the format 'sda1' so it can be saved as a file
		pName=`echo $p | sed -e 's/\/dev\///g'`
		
	# using dd and gzip we take an image of the partition and compress it
		echo "Creating compressed image of $p..." 
		dd if=$p conv=sync,noerror bs=4k | pv | gzip -c > $pName.img.gz
		
	done
	}	

pause() {
	read -p "Press [Enter] key to continue..."
}


main

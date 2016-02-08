#! /bin/bash
# createimg.sh: To image a machine to be deployed over many machines
# Author: Phil Stevenson
#
# Dependencies: fdisk, sfdisk, pv, grep, dd, sed

#########################################################
#	Functions
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
#	Main
##########################################################

#if there are 1 or 0 arguments then show usage
if [ $# -eq 0 ] || [ $# -eq 1 ]
then
	echo ""
	echo "./createimage.sh requires 2 arguments"
	echo "Usage: ./createimg.sh <drive> <imagename>"
	echo ""
	exit 1 
# else if there are two arguments
else
	drive=$1
	name=$2

# Create an temp file to store input
# OUTPUT="/tmp/input.txt"
# name = ""
# drive = ""
# >$OUTPUT
# 
# Take user input for name
# dialog --inputbox "Enter the image name:" 8 40 2>$OUTPUT
# Get the data stored in file
# $name=$(<$OUTPUT)
# Take user input for drive
# dialog --inputbox "Enter Storage device name (eg.'/dev/sda'):" 8 40 2>$OUTPUT
# Get the data stored in file
# $drive=$(<$OUTPUT)

# make the directory for the imaging files
	mkdir $name
	chmod 777 $name
	cd $name
	echo Directory Created: $name
	
	partTable
	zeroParts
	imgParts
fi	

#!/bin/bash
cls
echo "Open Gparted"
echo "Create a 512mb FAT32 partition"
echo "This will be your unencrypted boot partition"

#default parition location
encrypt="/dev/"
#user will enter the ending partition such as sda1
echo "Enter ending label for the aproprate partition under /dev/"
read -p "Ex: sda1, nvme0n1p1: " input

#check if there is spaces in the partition that they gave
while [[ $input = *" "* ]]
do
	echo "You can not have spaces in this name: "
	read -p "Enter ending label for the aproprate partition" input
done

#confirm user input
echo "==========================================="
echo "==========================================="
echo "WARNING: this proccess will wipe this partition"
echo "is this $input correct?"
read -p "y/n" confirm

while [ "$confirm" != "y" ]
dowhile ! [[ $input -ge 0 && $storageAmount -gt $input ]]
	do
		read -p "Your response was not a valid to create a home partition: " input
	done
	read -p "Enter ending label for the aproprate partition: " input
	read -p "is this $input correct? y/n" confirm
done

encrypt+="$input"

echo "==========================================="
echo "==========================================="
echo "Enter password to the encrypted volume"
sudo cryptsetup luksFormat $encrypt
echo "==========================================="
echo "==========================================="
echo "Enter password to open the encrypted area for formatting"
sudo cryptsetup luksOpen $encrypt cryptdata

sudo pvcreate /dev/mapper/cryptdata
sudo vgcreate vgcryptdata /dev/mapper/cryptdata

encryptdata="$(lsblk -l -o SIZE /dev/mapper/cryptdata)"

#here we parse the returned string
#this creates an array which bash does by itself
number=($encryptdata)

encryptdata=${number[1]}
#this is the size of the string here
size=${#encryptdata}
#this gets the integer value
storageAmount=${encryptdata:0:(size-1)}
#this gets the G or M specifiying megabytes or gigabytes
storageLetter=${encryptdata:(size-1)}

#if the storage area is in megabytes we quit because it is too small
if [[ storageLetter == "M" ]]
then
	@echo off
	cls
	echo "This partition is too small to create an encrypted area"
	pause
	exit
fi

#ask to create a swap area
echo "==========================================="
echo "==========================================="
echo "Would you like to create a swap area?"
echo "This will alieviate some stress on RAM with memory intensive processes"
echo "This is recommended on systems with low RAM"
echo "For those systems a few Gigabytes are useful"
read -p "Would you like to add SWAP y/n: " input

while [ "$input" != "y" ] && [ "$input" != "n" ]
do
	read -p "Your response was not y/n: " input
done

#the user chooses to add swap partition
if [ "$input" == "y" ]
then

	#add swap in gigabytes
	echo "Enter your swap space in Gigabytes"
	read -p ": " input

	#theres alot to check here so i think this is easier to check and add error messages
	#this is scalable to quickly add things that i may have missed
	
	returnValue=0
	while [[  returnValue -eq 0 ]]
	do
		#random variables i have set here
		remaningArea=storageAmount-input
		
		if [[ $input -le 0 ]]
		then
			read -p "Your input was not a valid swap size: " input
		elif [[ $input -gt $storageAmount ]]
		then
			read -p "Your response was bigger than the total partition size: " input
		elif [[ $remaningArea -le 1 ]]
		then
			echo "Your response was too big"
			echo "Please allow for at least 1 GB of remaning area"
			read -p ": " input
		else
			returnValue=1
		fi
	done

	#the new total partition storage is the current storage minus the swap area
	storageAmount=storageAmount-input

	#creates and formats the swap area with the correct size
	sudo lvcreate -n lvcryptswap -L ${input}g vgcryptdata
	sudo mkswap /dev/mapper/vgcryptdata-lvcryptswap
fi

echo "==========================================="
echo "==========================================="
echo "Would you like to create a seperate partition for home and root?"
read -p "y/n: " input

while [ "$input" != "y" ] && [ "$input" != "n" ]
do
	read -p "Your response was not y/n: " input
done

if [[ $input == "n" ]]
then
	sudo lvcreate -n lvcryptarea -L ${storageAmount}g vgcryptdata
	sudo mkfs.ext4 /dev/mapper/vgcryptdata-lvcryptarea
	
else
	echo "==========================================="
	echo "==========================================="
	echo "Enter the size of the home partition in Gigabytes"
	read -p ": " input

	returnValue=0
	while [[  returnValue -eq 0 ]]
	do
		#random variables i have set here
		remaningArea=storageAmount-input
		
		if [[ $input -le 0 ]]
		then
			read -p "Your input was not a valid swap size: " input
		elif [[ $input -gt $storageAmount ]]
		then
			read -p "Your response was bigger than the total partition size: " input
		elif [[ $remaningArea -le 1 ]]
		then
			echo "Your response was too big"
			echo "Please allow for at least 1 GB of remaning area"
			read -p ": " input
		else
			returnValue=1
		fi
	done

	#creates the home partition
	sudo lvcreate -n lvcrypthome -L ${input}g vgcryptdata
	sudo mkfs.ext4 /dev/mapper/vgcryptdata-lvcrypthome

	#the new total partition storage is the current storage minus the swap area
	storageAmount=storageAmount-input

	#creates the root partition
	sudo lvcreate -n lvcryptroot -L ${storageAmount}g vgcryptdata
	sudo mkfs.ext4 /dev/mapper/vgcryptdata-lvcryptroot
fi
@echo off
echo "==========================================="
echo "==========================================="
echo "FORMATTING IS COMPLETE"
echo "Please run the installer"
pause
exit










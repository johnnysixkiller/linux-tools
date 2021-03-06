#!/bin/bash
# Written by Stephen Davis
echo
echo "****** JOHNNY'S RAPID SETUP ******"
echo
# Decide which ditro is running so that we can utilize the package manager and add users to the sudo privileges group.
if [  -n "$(uname -a | grep Ubuntu)" ]; then
    PACKMAN="apt" 
    GROUP="sudo"
else
    PACKMAN="yum"
    GROUP="wheel"
fi 
# Get user input to assign values to variables.
echo "Enter your domain, without extention. (EX: DIY.LAN): "
read DOMAIN
echo "Enter your username: "
read USERNAME
prompt="Enter your password: "
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt='*'
    PASSWORD+="$char"
done
echo

while :
do
read -p "Enter a mount directory name. DO NOT include '/mnt/' or any preceeding slashes to the directory.
(EX: Instead of '/mnt/your_directory/your_sub_directory>' You would enter 'your_directory/your_sub_directory'" mpath
# Check to make sure we don't send trailing forward slash to the variable string.
if [[ "$mpath" == *\/* ]] || [[ "$mpath" == *\\* ]]
    then
      #pathname1=`dirname "$mpath"`
        dirname1=`basename "$mpath"`
        if [[ -d "${mpath}" && ! -L "${mpath}" ]] ; 
        then
            mkdir -p /mnt/${mpath} /mnt/${dirname1}
        fi
    else
        dirname1=${mpath}
        if [[ -d "${mpath}" && ! -L "${mpath}" ]] ; 
        then
            mkdir -p /mnt/${mpath} /mnt/${dirname1}
        fi
fi
# Write the mount configuration to fstab.
# This command will be run for each directory you mount one at a time.
cmd="sudo -i echo '//${mpath} /mnt/${dirname1} cifs domain=${DOMAIN},username=${USERNAME},password=${PASSWORD},
vers=2.1,iocharset=utf8,noserverino,file_mode=0777,dir_mode=0777,vers=1.0 0 0' >> /etc/fstab"

eval $cmd
read -p "Do you want to add another mount point? <y or n>: " prompt
if [[ $prompt == "n" || $prompt == "N" || $prompt == "no" || $prompt == "No" ]]
    then
        break
fi
done

# Give user the option to add users with sudo priviliges.
read -p "Do you wish to add users with sudo privileges? <y or n>: " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
    then
        echo "Enter a comma-separated list of users with no spaces (EX: jsmith,tjohnson,gnichols): "
        read userslist
        cmd="gpasswd -M ${userslist} ${GROUP}"
        eval $cmd
fi

# Restart the network
/etc/init.d/network restart
read -p "The DNS may take a while to update and recognize the new hostname. Press [ENTER] to reboot the machine."

# Reboot the machine
sudo reboot

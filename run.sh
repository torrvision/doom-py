#!/bin/bash 
# Ensure that you have installed nvidia-docker and the latest nvidia graphics driver!


SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# create fresh SSH keys
rm -Rf ./.sshauth
mkdir ./.sshauth
ssh-keygen -f ./.sshauth/slamdoom.rsa -t rsa -N ''
# ssh-add ./.sshauth/slamdoom.rsa # get too many authentication failures with docker! (FIX THIS)
sudo apt-get install -y sshpass
SPASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
echo $SPASSWORD > ./.sshauth/slamdoom.pass

# Build and run the image
echo "Building image..."
sudo nvidia-docker build --build-arg pass=$SPASSWORD -t doompy .
echo "Removing older image..."
sudo nvidia-docker rm -f doompy0
echo "Running image..."
sudo nvidia-docker run -d -p 51022:22  --name doompy0 \
      -v $SCRIPTPATH/:/doom \
      doompy

# Retrieve IP and port of Docker instance and container
CONTAINERIP=$(sudo nvidia-docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' doompy0);
DOCKERIP=$(/sbin/ifconfig docker0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
echo "CONTAINER IP:":$CONTAINERIP
echo "DOCKER IP:":$DOCKERIP
DOCKERPORTSTRING=$(sudo nvidia-docker port doompy0 22)
DOCKERPORT=${DOCKERPORTSTRING##*:}
echo "DOCKER PUBLISHED PORT 22 -> :":$DOCKERPORT
echo "IdentityFile $SCRIPTPATH/.sshauth/slamdoom.rsa" >> ~/.ssh/config
ssh-keygen -f ~/.ssh/known_hosts -R [$DOCKERIP]:$DOCKERPORT
echo "Login password is: ":$SPASSWORD
#ssh -o StrictHostKeyChecking=no root@$DOCKERIP -X -p $DOCKERPORT
# ssh  -X -p $DOCKERPORT -v -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$DOCKERIP
ssh -o StrictHostKeyChecking=no -X -p $DOCKERPORT root@$DOCKERIP

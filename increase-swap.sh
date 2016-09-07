#!/bin/sh

# courtesy of these fine posts:
# https://gist.github.com/shovon/9dd8d2d1a556b8bf9c82
# http://jeqo.github.io/blog/devops/vagrant-quickstart/

# size of swapfile in megabytes
swapsize=8000

# does the swap file already exist?
grep -q "swapfile" /etc/fstab

# if not then create it
if [ $? -ne 0 ]; then
  echo 'swapfile not found. Adding swapfile.'
  fallocate -l ${swapsize}M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap defaults 0 0' >> /etc/fstab
else
  echo 'swapfile found. No changes made.'
fi

# output results to terminal
df -h
cat /proc/swaps
cat /proc/meminfo | grep Swap

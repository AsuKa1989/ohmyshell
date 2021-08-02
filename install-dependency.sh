#!/bin/bash

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# root权限判定
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

oneinstack_dir=$(dirname "`readlink -f $0`")
pushd ${oneinstack_dir} > /dev/null
. ./include/check_os.sh

${PM} -y install \
wget \
net-tools \
lrzsz \
zip \
unzip \
telnet \
bzip2 \
gawk \
vim \
htop \
iftop \
git \
zsh \
dstat \
tree
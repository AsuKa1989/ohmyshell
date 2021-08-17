#!/bin/bash

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# root权限判定
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

ohmyshell_dir=$(dirname "`readlink -f $0`")
pushd $ohmyshell_dir > /dev/null
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

git clone -b fcg-branch --depth=1 https://gitee.com/AsuKa1989/oh-my-zsh.git ../.oh-my-zsh

cd ../.oh-my-zsh
cp ./my-custom/plugins/zsh-syntax-highlighting.tgz ./custom/plugins && \
cp ./my-custom/.zshrc ../ && \  
tar -xzvf ./custom/plugins/zsh-syntax-highlighting.tgz -C ./custom/plugins/

chsh -s /bin/zsh
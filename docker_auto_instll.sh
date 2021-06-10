#!/bin/bash

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# root权限判定
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

oneinstack_dir=$(dirname "`readlink -f $0`")
pushd ${oneinstack_dir} > /dev/null
. ./include/check_os.sh

if [ "${PM}" == 'apt-get' ];then
  apt-get -y update
  apt-get -y remove docker docker-engine docker.io containerd runc 
  apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu ${Code_Name} stable"
  apt-get -y update
  apt-get -y install docker-ce docker-ce-cli containerd.io

  # 普通用户使用docker
  usermod -aG docker $USER

  #配置镜像仓库
  mkdir -p /etc/docker
  echo '
    {   "registry-mirrors": [
        "https://hub-mirror.c.163.com",
        "https://reg-mirror.qiniu.com",
        "https://registry.docker-cn.com"]
    }' > /etc/docker/daemon.json

  # docker-compose
  curl -L "https://gitee.com/AsuKa1989/ohmyshell/attach_files/732673/download/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose;
  chmod +x /usr/local/bin/docker-compose;

  systemctl restart docker; docker version; docker-compose version
  echo "docker安装完成;)"
fi
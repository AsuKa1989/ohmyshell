#!/bin/bash

# 获取包管理工具
if [ -e "/usr/bin/yum" ]; then
  PM=yum
  if [ -e /etc/yum.repos.d/CentOS-Base.repo ] && grep -Eqi "release 6." /etc/redhat-release; then
    sed -i "s@centos/\$releasever@centos-vault/6.10@g" /etc/yum.repos.d/CentOS-Base.repo
    sed -i 's@centos/RPM-GPG@centos-vault/RPM-GPG@g' /etc/yum.repos.d/CentOS-Base.repo
    [ -e /etc/yum.repos.d/epel.repo ] && rm -f /etc/yum.repos.d/epel.repo
  fi
  if ! command -v lsb_release >/dev/null 2>&1; then
    if [ -e "/etc/euleros-release" ]; then
      yum -y install euleros-lsb
    elif [ -e "/etc/openEuler-release" -o -e "/etc/openeuler-release" ]; then
      if [ -n "$(grep -w '"20.03"' /etc/os-release)" ]; then
        rpm -Uvh https://repo.openeuler.org/openEuler-20.03-LTS-SP1/everything/aarch64/Packages/openeuler-lsb-5.0-1.oe1.aarch64.rpm
      else
        yum -y install openeuler-lsb
      fi
    else
      yum -y install redhat-lsb-core
    fi
    clear
  fi
fi

if [ -e "/usr/bin/apt-get" ]; then
  PM=apt-get
  command -v lsb_release >/dev/null 2>&1 || { apt-get -y update > /dev/null; apt-get -y install lsb-release; clear; }
fi

command -v lsb_release >/dev/null 2>&1 || { echo "${CFAILURE}${PM} source failed! ${CEND}"; kill -9 $$; }

# 获取操作系统和版本
OS=$(lsb_release -is)
if [[ "${OS}" =~ ^CentOS$|^RedHat$|^Rocky$|^Fedora$|^Amazon$|^Alibaba$|^Aliyun$|^EulerOS$|^openEuler$ ]]; then
  LikeOS=CentOS
  CentOS_ver=$(lsb_release -rs | awk -F. '{print $1}' | awk '{print $1}')
  [[ "${OS}" =~ ^Fedora$ ]] && [ ${CentOS_ver} -ge 19 >/dev/null 2>&1 ] && { CentOS_ver=7; Fedora_ver=$(lsb_release -rs); }
  [[ "${OS}" =~ ^Amazon$|^Alibaba$|^Aliyun$|^EulerOS$|^openEuler$ ]] && CentOS_ver=7
elif [[ "${OS}" =~ ^Debian$|^Deepin$|^Uos$|^Kali$ ]]; then
  LikeOS=Debian
  Debian_ver=$(lsb_release -rs | awk -F. '{print $1}' | awk '{print $1}')
  [[ "${OS}" =~ ^Deepin$|^Uos$ ]] && [[ "${Debian_ver}" =~ ^20$ ]] && Debian_ver=10
  [[ "${OS}" =~ ^Kali$ ]] && [[ "${Debian_ver}" =~ ^202 ]] && Debian_ver=10
elif [[ "${OS}" =~ ^Ubuntu$|^LinuxMint$|^elementary$ ]]; then
  LikeOS=Ubuntu
  Ubuntu_ver=$(lsb_release -rs | awk -F. '{print $1}' | awk '{print $1}')
  Code_Name=$(lsb_release -cs)
  if [[ "${OS}" =~ ^LinuxMint$ ]]; then
    [[ "${Ubuntu_ver}" =~ ^18$ ]] && Ubuntu_ver=16
    [[ "${Ubuntu_ver}" =~ ^19$ ]] && Ubuntu_ver=18
    [[ "${Ubuntu_ver}" =~ ^20$ ]] && Ubuntu_ver=20
  fi
  if [[ "${OS}" =~ ^elementary$ ]]; then
    [[ "${Ubuntu_ver}" =~ ^5$ ]] && Ubuntu_ver=18
    [[ "${Ubuntu_ver}" =~ ^6$ ]] && Ubuntu_ver=20
  fi
fi

# 检查操作系统版本
if [ ${CentOS_ver} -lt 6 >/dev/null 2>&1 ] || [ ${Debian_ver} -lt 8 >/dev/null 2>&1 ] || [ ${Ubuntu_ver} -lt 16 >/dev/null 2>&1 ]; then
  echo "${CFAILURE}Does not support this OS, Please install CentOS 6+,Debian 8+,Ubuntu 16+ ${CEND}"
  kill -9 $$
fi

# 获取GCC版本
command -v gcc > /dev/null 2>&1 || $PM -y install gcc
gcc_ver=$(gcc -dumpversion | awk -F. '{print $1}')

# 是否是ARM平台
if uname -m | grep -Eqi "arm|aarch64"; then
  armplatform="y"
  if uname -m | grep -Eqi "armv7"; then
    TARGET_ARCH="armv7"
  elif uname -m | grep -Eqi "armv8"; then
    TARGET_ARCH="arm64"
  elif uname -m | grep -Eqi "aarch64"; then
    TARGET_ARCH="aarch64"
  else
    TARGET_ARCH="unknown"
  fi
fi

# 是否是WSL
if [ "$(uname -r | awk -F- '{print $3}' 2>/dev/null)" == "Microsoft" ]; then
  Wsl=true
fi

# 32 or 64 
if [ "$(getconf WORD_BIT)" == "32" ] && [ "$(getconf LONG_BIT)" == "64" ]; then
  OS_BIT=64
  SYS_BIT_j=x64 #jdk
  SYS_BIT_a=x86_64 #mariadb
  SYS_BIT_b=x86_64 #mariadb
  SYS_BIT_c=x86_64 #ZendGuardLoader
  SYS_BIT_d=x86-64 #ioncube
  [ "${TARGET_ARCH}" == 'aarch64' ] && { SYS_BIT_j=aarch64; SYS_BIT_c=aarch64; SYS_BIT_d=aarch64; }
else
  OS_BIT=32
  SYS_BIT_j=i586
  SYS_BIT_a=x86
  SYS_BIT_b=i686
  SYS_BIT_c=i386
  SYS_BIT_d=x86
  [ "${TARGET_ARCH}" == 'armv7' ] && { SYS_BIT_j=arm32-vfp-hflt; SYS_BIT_c=armhf; SYS_BIT_d=armv7l; }
fi

# 线程数
THREAD=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)

# Percona binary: https://www.percona.com/doc/percona-server/5.7/installation.html#installing-percona-server-from-a-binary-tarball
if [ ${Debian_ver} -lt 9 >/dev/null 2>&1 ]; then
  sslLibVer=ssl100
elif [[ "${CentOS_ver}" =~ ^[6-7]$ ]] && [ "${OS}" != 'Fedora' ]; then
  sslLibVer=ssl101
elif [ ${Debian_ver} -ge 9 >/dev/null 2>&1 ] || [ ${Ubuntu_ver} -ge 16 >/dev/null 2>&1 ]; then
  sslLibVer=ssl102
elif [ ${Fedora_ver} -ge 27 >/dev/null 2>&1 ]; then
  sslLibVer=ssl102
elif [ "${CentOS_ver}" == '8' ]; then
  sslLibVer=ssl1:111
else
  sslLibVer=unknown
fi

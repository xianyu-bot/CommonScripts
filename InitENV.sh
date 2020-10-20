#!/bin/bash


function Init_yumrepo_centos7()
{
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
}

function Init_epelrepo_centos7()
{
    if [[ -d /etc/yum.repos.d/epel.repo ]];then
        mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
        mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
    fi
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
}

function Install_Common_rpm()
{
    yum -y install vim gcc make lrzsz openssl python3 python3-devel
}

function Init_Pypi()
{
    mkdir -p ~/.pip
    touch ~/.pip/pip.conf
cat << EOF > ~/.pip/pip.conf
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
EOF
}


function check_os_support()
{


        ##
        ##  -------------------- Check OS Version --------------
        ##
        RH_RELEASE=$(cat /etc/redhat-release)
       # OS_RELEASE=$(cat /etc/os-release 2>&1 | grep PRETTY_NAME | awk -F[=\"] '{print $3}')
        case ${RH_RELEASE} in
                # SUPPORT centos 7.2 7.3 7.4
                "CentOS Linux release 7."*)
                        OS_INSTALL_VERSION=centos7
                        ;;
                # SUPPORT redhat 7.2 7.3 7.4
                "Red Hat Enterprise Linux Server release 7."*)
                        OS_INSTALL_VERSION=centos7
                        ;;
                # SUPPORT centos 6.x
                "CentOS release 6."*)
                        OS_INSTALL_VERSION=centos6
                        ;;
                # SUPPORT redhat 6.x
                "Red Hat Enterprise Linux Server release 6."*)
                        OS_INSTALL_VERSION=centos6
                        ;;
                *)
                        echo_color red invert "os not support .....please tell us...."
                        exit
                        ;;
        esac
}


####main###
check_os_support
Init_yumrepo_centos7
Init_epelrepo_centos7
Install_Common_rpm
Init_Pypi
#!/bin/bash

#添加iptables服务的查询判断，添加允许vrrp的规则

FONT="\033[32;49;1m"
BACK="\033[39;49;0m"
WARNING="\033[33;49;1m[WARNING]\033[39;49;0m"
CHECK="\033[33;49;1m[CHECK]\033[39;49;0m"
BACKUP="\033[33;49;1m[BACKUP]\033[39;49;0m"
ERROR="\033[31m [ERROR] \033[0m"
OK="\033[32m [OK] \033[0m"
NIC=$(ls /sys/class/net/ | grep -v "`ls /sys/devices/virtual/net/`")

if [ $(rpm -qa | grep -E 'firewalld-filesystem|firewalld' | wc -l) -ge 1 ]; then
	echo -e "$CHECK$FONT Firewalld Install$BACK$OK \n"
else
	echo -e "$CHECK$ERROR Firewalld is Not Install$BACK"
	exit
fi

TCPPORTS=$(/usr/sbin/ss -tnl | awk 'NR>1 {print $4}' | awk -F ':' '{print $NF}' | sort -n | uniq | awk 'BEGIN{ORS=" "}{print $1}')
echo -e "$FONT[1]$BACK Add$FONT TCP$BACK ports to firewalld:$FONT $TCPPORTS $BACK"
UDPPORTS=$(/usr/sbin/ss -unl | awk 'NR>1 {print $4}' | awk -F ':' '{print $NF}' | sort -n | uniq | awk 'BEGIN{ORS=" "}{print $1}')
echo -e "$FONT[2]$BACK Add$FONT UDP$BACK ports to firewalld:$FONT $UDPPORTS $BACK"
echo -e "$FONT[3]$BACK Add$FONT TCP and UDP$BACK ports to firewalld \n"
read -p "please input [3]:" ADDTYPE

if [[ $ADDTYPE == "" ]]; then
	ADDTYPE=3
fi

function backupconfig() {
	backupfile="/etc/firewalld.conf.backup$(date +%Y-%m-%d-%H-%M-%S).tar"
	/usr/bin/tar -zcvf ${backupfile}.gz /etc/firewalld
	if [ $? -eq 0 ]; then
		echo -e "$BACKUP Backup firewalld config $OK backupfile:$backupfile"
	else
		echo -e "$BACKUP Backup firewalld config $ERROR"
		exit
	fi
}

function errorexit() {
	systemctl stop firewalld
	if [ $? -eq 0 ]; then
		echo -e "$ERROR$FONT Stop firewalld Success and exit$BACK"
		exit
	else
		echo -e "$ERROR$FONT Stop firewalld failed and exit$BACK$ERROR"
		exit
	fi
}

function checkfirewalld() {
	if [[ $(/usr/bin/firewall-cmd --state 2>/dev/null) == "running" ]]; then
		echo -e "$CHECK$FONT firewalld is running$BACK$OK \n"
	else
		echo -e "$CHECK firewalld is not running,Now starting firewalld...."
		systemctl start firewalld
		if [ $? -eq 0 ]; then
			echo -e "$CHECK$FONT Start firewalld$BACK$OK \n"
		else
			echo -e "$CHECK$FONT Start firewalld$BACK$ERROR"
			exit
		fi
	fi
}

function checkiptables() {
	service iptables status
	if [[ $? -eq 0 ]]; then
		echo -e "Iptables is running, exit"
		exit
	fi
}

function reloadfirewalld() {
	if [[ $(/usr/bin/firewall-cmd --reload) == "success" ]]; then
		echo -e "${FONT}reload firewalld$BACK $OK \n"
	else
		echo -e "${FONT}reload firewalld$BACK $ERROR"
		errorexit
	fi
}

function checkonbootenable() {
	if [[ $(systemctl is-enabled firewalld) == "enabled" ]]; then
		echo -e "$CHECK$FONT firewalld onboot is enabled$BACK $OK"
	else
		echo -e "$CHECK firewalld onboot is disabled,now enable firewalld onboot..."
		systemctl enable firewalld
		if [ $? -eq 0 ]; then
			echo -e "$CHECK$FONT firewalld onboot enabled$BACK$OK \n"
		else
			echo -e "$CHECK$FONT firewalld onboot enabled$BACK$ERROR"
			exit
		fi
	fi
}

function addtcpports() {
	for i in $TCPPORTS; do
		if [[ $(/usr/bin/firewall-cmd --permanent --add-port=$i/tcp) == "success" ]]; then
			echo -e "Add port $i/tcp $OK"
		else
			echo -e "Add port $i/tcp $ERROR"
			errorexit
		fi
	done
}

function addudpports() {
	for i in $UDPPORTS; do
		if [[ $(/usr/bin/firewall-cmd --permanent --add-port=$i/udp) == "success" ]]; then
			echo -e "Add port $i/udp $OK"
		else
			echo -e "Add port $i/udp $ERROR"
			errorexit
		fi
	done
}

function addvrrp() {
	for i in ${NIC}; do
		if [[ $(/usr/bin/firewall-cmd --direct --permanent --add-rule ipv4 filter INPUT 0 --in-interface ${i} --destination 224.0.0.18 --protocol vrrp -j ACCEPT) == "success" ]]; then
			echo -e "Add vrrp ${OK}"
		else
			echo -e "Add vrrp ${ERROR}"
			errorexit
		fi
	done
}


case $ADDTYPE in
1)
	backupconfig
	echo -e "$FONT Start add TCP ports to Firewalld....$BACK"
	if [ ${#TCPPORTS} -ge 1 ]; then
		checkfirewalld
		addvrrp
		addtcpports
		reloadfirewalld
		checkonbootenable
	else
		echo -e "$ERROR No listening TCP Ports...."
	fi
	;;
2)
	backupconfig
	echo -e "$FONT Start add UDP ports to Firewalld....$BACK"
	if [ ${#UDPPORTS} -ge 1 ]; then
		checkfirewalld
		addvrrp
		addudpports
		reloadfirewalld
		checkonbootenable
	else
		echo -e "$ERROR No listening UDP Ports...."
	fi
	;;
3)
	backupconfig
	echo -e "$FONT Start add TCP and UDP ports to Firewalld....$BACK"
	if [ ${#TCPPORTS} -ge 1 ]; then
		checkiptables
		checkfirewalld
		addvrrp
		addtcpports
		reloadfirewalld
		checkonbootenable
	else
		echo -e "$ERROR No listening TCP Ports...."
	fi
	if [ ${#UDPPORTS} -ge 1 ]; then
		checkiptables
		checkfirewalld
		addudpports
		reloadfirewalld
		checkonbootenable
	else
		echo -e "$ERROR No listening UDP Ports...."
	fi
	;;
*)
	echo -e "$ERROR input error"
	;;
esac

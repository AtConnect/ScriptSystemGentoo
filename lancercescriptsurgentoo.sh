#!/usr/bin/env bash

set -e -o pipefail

#Update of the system only if update has been run without problem

function check_ip()
{    
    if [[ $1 =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$ ]]; then    
    result="true"
    else
    result="false"
    fi
}

function menuip()
{
echo "Please choose the location where you want to install"
echo "1 -> Central Centreon "
echo "2 -> Adapei Poller "
echo "3 -> ATC Poller "
echo "4 -> Lisa2 Poller "
echo "5 -> Another Poller ?"
read -p "Enter your answer : "  rep
case $rep in
1 )
ip="195.135.72.13"
echo "The selected server is Central Centron" 
echo "The authorized ip address is 195.135.72.13"
;;
2 )
ip="195.135.27.61"
echo "The selected server is Adapei Poller" 
echo "The authorized ip address is 195.135.27.61"
;;
3 )
ip="195.135.40.134"
echo "The selected server is ATC Poller" 
echo "The authorized ip address is 195.135.40.134"
;;
4 )
ip="65.39.76.144"
echo "The selected server is Lisa2 Poller " 
echo "The authorized ip address is 65.39.76.144"
;;
5 )
read -p "Enter the ip address if the server : "  ip
if [[ -n $ip ]]; then
  check_ip $ip
fi
if [[ $result != "true" ]]; then
  echo "It's time to know the syntax of an IP..."
  exit 1
fi
echo "The authorized ip address is " $ip
;;
*)    echo "Read the Fucking Manual !"
esac
}
menuip


clear
VERSION=$(uname -r)
if [[ "$VERSION" < 4.* ]]; then
	 exit 1;
fi

function CheckVersion(){
	VERSION=$(uname -r)
	if [[ "$VERSION" < 4.* ]]; then
		exit 1
	fi


function CheckPastInstall(){
	FILE="/usr/local/nagios/etc/command_nrpe.cfg"
	FILE2="/usr/local/nagios/etc/nrpe.cfg"
	if [[ -f $FILE ]] || [[ -f $FILE2 ]]; then
	    exit 1
	fi
}


# shellcheck source=concurrent.lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/concurrent.lib.sh"

success() {
    local args=(
    	- "Checking version of the system"                 CheckVersion\
    	- "The script has been runned in the past"         CheckPastInstall\
        - "Updating System"                                UpdateSystem\
        - "Downloading NRPE"                               DownloadNRPE\
        - "Installation of NRPE"                           InstallNRPE\
        - "Installation of IPTables"                       InstallIptables\
        - "Configuration of NRPE"                          ConfigNRPE\
        - "Installation of NRPE Plugins"                   NRPEPlugins\
        - "Configuration of NRPE Plugins"                  ConfigNRPEPlugins\
        - "Configuration of Sudoers"                       ConfSudoers\
        - "Copying Scripts for Centreon"                   CopyScripts\
        - "End of Installation"                            End\
        --sequential
        
    )

    concurrent "${args[@]}"
}



function UpdateSystem(){
	echo "Update System" >> logs
	emerge --sync
	echo "Install of apps" >> logs		
	emerge sys-devel/gcc sys-libs/glibc net-misc/wget dev-libs/openssl dev-lang/perl dev-libs/openssl sys-process/htop sys-process/iotop
}	


function DownloadNRPE(){
	cd /tmp || exit 1
	wget --no-check-certificate -q -O nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/archive/nrpe-3.2.1.tar.gz >> logs
	tar xzf nrpe.tar.gz >> logs
	cd /tmp/nrpe-nrpe-3.2.1/
}

function InstallNRPE(){
	echo "Install BINARIES and more" >> logs
	cd /tmp/nrpe-nrpe-3.2.1/
	./configure --enable-command-args --enable-ssl
	make all >>logs
	make install-groups-users >> logs
	make install >> logs
	make install-config >> logs
	echo >> /etc/services
	echo '# Nagios services' >> /etc/services
	echo 'nrpe    5666/tcp' >> /etc/services
	
	if [[ "$VERSION" > 4.* ]]; then
		make install-init
		systemctl enable nrpe.service
	elif [[ "$VERSION" < 4.* ]]; then	
		make install-init
		sed -i 's/^command_args=.*/command_args="--config=\/usr\/local\/nagios\/etc\/nrpe.cfg"/g' /etc/init.d/nrpe
		rc-update add nrpe default	
	else
		 exit 1;
	fi
}

function InstallIptables(){
	echo "No IPTables needed" >> logs
	
}

function ConfigNRPE(){
	sed -i -r 's/.*allowed_hosts=127.0.0.1.*/allowed_hosts=127.0.0.1,::1,195.135.72.13/g' /usr/local/nagios/etc/nrpe.cfg
	sed -i -r 's/.*dont_blame_nrpe.*/dont_blame_nrpe=1/g' /usr/local/nagios/etc/nrpe.cfg
	echo "include=/usr/local/nagios/etc/command_nrpe.cfg" >> /usr/local/nagios/etc/nrpe.cfg
	
}

function NRPEPlugins(){
	echo "Install NRPE plugins for NRPE" >> logs
	emerge net-analyzer/nagios-plugins net-analyzer/nagios net-analyzer/net-snmp dev-perl/Net-SNMP sys-devel/gettext	
	cd /tmp ||  exit 1
	# wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz >> logs
	# tar zxf nagios-plugins.tar.gz >> logs
}

function ConfigNRPEPlugins(){
	# cd /tmp/nagios-plugins-release-2.2.1/ ||  exit 1
	# ./tools/setup >> logs
	# ./configure >> logs
	# make >> logs
	# make install >> logs	
	/etc/init.d/nagios start
	
	
}

function ConfSudoers(){
	echo "#Rule for nagios/nrpe" >> /etc/sudoers
	echo "nagios ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
}
function CopyScripts(){
	echo "Installation des scripts wazo payant" >> logs
	cd /tmp/ScriptSystemGentoo ||  exit 1
	cp commandnrpe/command_nrpe.cfg /usr/local/nagios/etc/command_nrpe.cfg
	sed -i -r "s/.*allowed_hosts.*/allowed_hosts=127.0.0.1,::1,${ip}/g" /usr/local/nagios/etc/nrpe.cfg
	cp base/nagisk.pl /usr/local/nagios/libexec/nagisk.pl
	cp base/check_services_wazo.pl /usr/local/nagios/libexec/check_services_wazo.pl
	cp base/checkversionwazo.sh /usr/local/nagios/libexec/checkversionwazo.sh
	cp base/checkuptimewazo.sh /usr/local/nagios/libexec/checkuptimewazo.sh
	cp base/check_stuck_channels.pl /usr/local/nagios/libexec/check_stuck_channels.pl
	cd /usr/local/nagios ||  exit 1
	chmod -R 755 libexec/
}

function End(){
	/etc/init.d/nrpe start
	echo "Finish" >> logs
}


main() {
    if [[ -n "${1}" ]]; then
        "${1}"
    else
        echo
        echo "################################################################################" 
		echo -e "\033[45m#               Installation of NRPE and NAGIOS for Centreon                   #\033[0m"
		echo -e "\033[45m#                     Compatible with Debian 7/8/9 only                        #\033[0m"
		echo "#                    Written by Kévin Perez for AtConnect                       #"
		echo "# The task is in progress, please wait a few minutes while i'm doing your job !#"
		echo "################################################################################" 
		echo "--------------------------------------------------------------------------------"
        success
        
    fi
}
main "${@}"

#/bin/bash
#INFO
#----------------------------------------------------------------
# Coded by jjavieralv
# version 1.0
# git reference: 
# EXPLICACION:
# This script is used to configure microk8s cluster
# using princess_sysadmin
#
#----------------------------------------------------------------
#REQUISITOS
# Ubuntu 18.04 LTS
# USERDblancanieves con permisos sudo
#
#----------------------------------------------------------------
#VARIABLES GLOBALES
USERD='blancanieves'
REPO=''
SSH_ROUTE=''


#INDIVIDUAL FUNCTIONS

function red_messages() {
  #crittical and error messages
  echo -e "\n\033[31m$1\e[0m\n"
}

function green_messages() {
  #starting functions and OK messages
  echo -e "\n\033[32m$1\e[0m\n"
}

function magenta_messages(){
  #what part which is executting
  echo -e "\n\e[45m$1\e[0m\n"
}




## Initial functions
	function check_sudo() {
		#check sudo 
		if [[ $(sudo whoami) -eq 'root' ]];then
			green_messages "Executed as sudo correctly"
		else
			red_messages "Need to execute with sudo :( "
			exit
		fi
	}

	function updates() {
		echo "Update repos and versions"
		sudo apt update
		sudo apt upgrade -y
	}

	function install_others(){
		echo "Install other software"
		sudo apt -y install htop git curl zip pv jq 
	}

	function configure_network(){
		##Network vars
		echo "Network config"
		GATEWAY="$(ip route show dev $ADAPTER|grep default|awk '{print $7}')"
		MASK=
		IP_STATIC="$(ip route show dev $ADAPTER|grep default|awk '{print $7}')"
		BROADCAST="$(ip -o addr show dev $ADAPTER|grep brd|awk '{print $6}')"
	}

	function check_so(){
		echo "Check if SO is Ubuntu 18.04"
		cat /etc/lsb-release |grep 18.04>/dev/null
		if [[ $? -ne 0 ]];then
			red_messages "The SO is NOT Ubuntu 18.04"
			exit
		fi
		green_messages "The SO is Ubuntu 18.04"
	}

	function check_if_installed(){
		echo "Check if all necessary software is installed:"
		installed=(microk8s docker)
		for i in ${installed[@]};do
			echo " -Check if $i is installed"
			if [[ -z "$(which $i)" ]];then
				red_messages "   $i is not installed, exit"
				exit
			else
				echo "   $i is installed"
			fi
		done
	}

## Microk8s functions

	function microk8s_alias(){
		echo "Grant access and create alias"
		sudo usermod -a -G microk8s $USERD
		sudo chown -f -R $USERD~/.kube
		echo "alias kubectl='microk8s kubectl'">>~/.bash_aliases
	}

	function microk8s_addons() {
		echo "Enable microk8s addons"
		sudo microk8s enable dns storage ingress
	}

	function microk8s_dashboard(){
		echo "Configure and enable dashboard"
		sudo microk8s enable dashboard
		
	}

## Config SSH

	function enable_X11() {
		echo "enable X11 and install some apps"
		sudo apt-get install xorg openbox mesa-utils firefox -y

	}

## Install KVM
	function check_virtualization(){
		echo "Check virtualization"
		sudo apt install cpu-checker -y
		kvm-ok
		if [[ -z `kvm-ok|grep "kvm exists"` ]];then
			red_messages "Enable VT-X or AMD-V(usually BIOS or enable in virtual)"
			exit
		else
			echo "Virtualization enabled"
			
		fi
	}

	function install_kvm(){
		echo "Install kvm"
		sudo apt-get -y install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
		sudo service libvirtd start
		sudo update-rc.d libvirtd enable
	}

	function kvm_permissions(){
		echo "Grant kvm permisions"
		sudo usermod -aG libvirt $USERD
		sudo usermod -aG kvm $USERD
		sudo adduser $USERD libvirt-qemu
	}

############ STRUCTURAL FUNCTIONS

function initial_config(){
	magenta_messages " Initial config process: "
	check_so
	check_sudo
	check_if_installed
	updates
	install_others
	download_repo
	#configure_network
}

function microk8s_config(){
	magenta_messages "microk8s config process: "
	microk8s_alias
	microk8s_addons
	microk8s_dashboard
}

function config_ssh(){
	magenta_messages "Config ssh process: "
	enable_X11
	add_sshcerts
	add_sshconfig
}

function kvm_full(){
	magenta_messages "Config KVM: "
	check_virtualization
	install_kvm
	kvm_permissions

}

############ MAIN FUNCTION
function main(){
	initial_config
	#add_users 
	config_ssh
	microk8s_config
	kvm_full
	red_messages "REMEMBER CONFIG STATIC IP"
}

main
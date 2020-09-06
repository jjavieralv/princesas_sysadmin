#/bin/bash
# This script allows you to use Kubernetes Dashboard using firefox and X11


#INDIVIDUAL FUNCTIONS
	trap '' SIGINT SIGQUIT SIGTSTP

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


## Kubernetes dashboard
	function killprocess(){
		ps aux|grep "port-forward -n kube-system service/kubernetes-dashboard 10443:443"|awk '{print $2}'|xargs sudo kill
	}

	function accessdashboard(){
		echo "This simple script allows you to access to dashboard using X11 firefox"
		echo -e "\nUse the following token:\n"
		token=$(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
		sudo microk8s kubectl -n kube-system describe secret $token|grep token:|awk '{print $2}'
		echo -e "\n"
		sudo microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443 &
		firefox https://127.0.0.1:10443
	}


## script functions
	function menu(){
		echo "Script allows you to connect using X11"
		echo "Connect to the server using: ssh -X user@ip"
		echo -e "\n\t 1) Connect to Kubernetes dashboard"
		echo -e "\t 2) Connect to virt-manager"
		echo -e "\t 3) Add new users"
		echo -e "\t 4) Delete users"
		echo -e "\t 5) Exit"
	}

	function select_option(){
		local choice
		read -p "Enter choice [ 1 - 5] " choice
		case $choice in
	  		1) kubernetes_dashboard ;;
	  		2) virt_manager ;;
			3) agregar_usuario;;
			4) delete_users;;
	  		5) exit 1;;
	  		*) red_messages "No valid option selected..." && sleep 2
		esac
	}

## kvm manage
	function virt_execute(){
		sudo virt-manager
	}


## add new users
	function add_user(){
		NAMEUSER=""
		read -p "Enter new user name: " NAMEUSER
		echo "The new user will be.... $NAMEUSER"
		sudo useradd -m -s /bin/bash "$NAMEUSER"
		sudo usermod -aG microk8s $NAMEUSER
		sudo echo "alias kubectl='microk8s kubectl'">>/home/$NAMEUSER/.bash_aliases
		sudo passwd "$NAMEUSER"
	}

## delete users
	function delete_us(){
		NAMEUSER=""
		read -p "Enter name who will be deleted: " NAMEUSER
		sudo userdel -r "$NAMEUSER"
	}


#### STRUCTURAL FUNCTIONS
	function kubernetes_dashboard(){
		killprocess
		accessdashboard
		killprocess
	}

	function virt_manager(){
		virt_execute
	}

	function agregar_usuario(){
		add_user
	}

	function delete_users(){
		delete_us
	}


#### MAIN FUNCTION
	function main(){
		menu
		select_option
	}
main


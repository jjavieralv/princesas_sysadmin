#/bin/bash
# This script allows you to import images and deploy


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

## script functions
	function menu(){
		echo "Script allows you to add image and deploy"
		echo -e "\n\t 1) Import image"
		echo -e "\t 2) How to export your images?"
		echo -e "\t 3) Deploy APP"
		echo -e "\t 4) How to deploy app?"
		echo -e "\t 5) Exit"
	}

	function select_option(){
		local choice
		read -p "Enter choice [ 1 - 5] " choice
		case $choice in
	  		1) import_image ;;
	  		2) how_to_export_image ;;
			3) deploy_app;;
			4) how_to_deploy;;
	  		5) exit 1;;
	  		*) red_messages "No valid option selected..." && sleep 2
		esac
	}

	function import_image(){
		FILE=""
		echo "This allow you to import image" 
		read -p "Write where is your file located Ex: /home/user/image.tar: " FILE
		if test -f "$FILE";then
			echo "Image correct. Adding"
			microk8s ctr image import "$FILE"
			echo "image added"
		fi
	}

	function how_to_export_image(){
		echo 'How to export your images: 
			1º Get an user in the server
			2º Get your local image name and tag with: docker image ls
			3º Export it with: docker save image_name > image_name.tar
			4º Send it to the server using: scp image_name.tar username@ipserver:/home/username
			5º Connect to the server with: ssh username@serverip 
			6º Execute this script and select import image option
			7º Add your imagename:tagname to your variables.json in var image'
	}

	function how_to_deploy(){
		echo 'How to deploy your APP:
			1º If there is a custom image, see option how to export image option
			2º Fill variables.json (no neccesary fill tls or vars variables)
			3º Once you have fill variables.json select option deploy APP'
	}

	function create_namespace(){
		echo -e "\n create namespace"
		echo "# crear Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: $(jq .program $1|tr -d '"')">>"$2"
	}

	function create_serviceaccount(){
		echo -e "\n create serviceaccount"
		echo "---
# Crear el service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $(jq .program $1|tr -d '"') 
  namespace: $(jq .program $1|tr -d '"')">>"$2"
	}

	function create_secrettls(){
		echo -e "\n create secret tls"
		if [[ '""' != "$(jq .tls.crt $1)" ]];then 
			echo "cert detected"
			echo "---
# Crear Secret para el certificado tls
apiVersion: v1
kind: Secret
data:
  tls.crt: $(jq .tls.crt $1|base64)
  tls.key: $(jq .tls.key $1|base64)
metadata:
  name: $(jq .program $1|tr -d '"')-tls
  namespace: $(jq .program $1|tr -d '"')
type: kubernetes.io/tls">>"$2"
		else
			echo "no cert detected"
		fi
	}

	function create_services(){
		echo -e "\n create services"
		echo "---
# Crear servicio para tener acceso a los pods
kind: Service
apiVersion: v1
metadata:
  name: $(jq .program $1|tr -d '"')-svc
  namespace: $(jq .program $1|tr -d '"')
spec:
  selector:
    app: $(jq .program $1|tr -d '"')-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080">>"$2"
	}

	function create_ingress(){
		echo -e "\n create ingress"
		if [[ '""' != "$(jq .tls.crt $1)" ]];then 
			echo "cert detected"
			echo "---
# Crear ingress para enrutado y aplicacion de certificado
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: $(jq .program $1|tr -d '"')-tls-ingress
  namespace: $(jq .program $1|tr -d '"')
spec:
  tls:
  - hosts:
    - $(jq .program $1|tr -d '"').coredumped.es
    secretName: $(jq .program $1|tr -d '"')-tls
  rules:
    - host: $(jq .program $1|tr -d '"').coredumped.es
      http:
        paths:
        - path: /
          backend:
            serviceName: $(jq .program $1|tr -d '"')-svc
            servicePort: 80">>"$2"
		else
			echo "no cert detected"
			echo "---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: $(jq .program $1|tr -d '"')-ingress
  namespace: $(jq .program $1|tr -d '"')
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: $(jq .program $1|tr -d '"').coredumped.es 
    http:
      paths:
      - backend:
          serviceName: $(jq .program $1|tr -d '"')-svc
          servicePort: 80">>"$2"
		fi
	}

	function create_secrets(){
		echo "create secrets"
		if [[ '""' != "$(jq .secrets[0].deploy[0].name $1)" ]];then
			for i in `seq 0 $(( $(jq '.secrets[0].deploy|length' "$1") - 1 ))`;do
				echo "---
apiVersion: v1
kind: Secret
metadata:
  name: $(jq .secrets[0].deploy[$i].name $1|tr -d '"')-secret
  namespace: $(jq .program $1|tr -d '"')
data:
  $(jq .secrets[0].deploy[$i].namekey $1|tr -d '"').key: $(jq .secrets[0].deploy[$i].value $1|tr -d '"'|base64)
type: Opaque">>"$2"
			done
		fi

	}
	function create_deployment(){
		echo -e "\n create deployment"
		echo "---
# Creacion del pod usando la imagen creada
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $(jq .program $1|tr -d '"')-app
  namespace: $(jq .program $1|tr -d '"')
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $(jq .program $1|tr -d '"')-app
  template:
    metadata:
      labels:
        app: $(jq .program $1|tr -d '"')-app
    spec:
      containers:
      - name: $(jq .program $1|tr -d '"')-pod
        image: $(jq .image $1|tr -d '"')
        imagePullPolicy: Always">>"$2"
        if [[ '""' != "$(jq .vars[0].deploy[0].name $1)" || '""' != "$(jq .secrets[0].deploy[0].name $1)" ]];then
        		echo "        env:">>"$2"
        fi

        if [[ '""' != "$(jq .vars[0].deploy[0].name $1)" ]];then
        	for i in `seq 0 $(( $(jq '.vars[0].deploy|length' "$1") - 1 ))`;do
echo "        - name: $(jq .vars[0].deploy[$i].name "$1"|tr -d '"')
          value: $(jq .vars[0].deploy[$i].value "$1")">>"$2"
        	done
    	fi
    	if [[ '""' != "$(jq .secrets[0].deploy[0].name $1)" ]];then
			for i in `seq 0 $(( $(jq '.secrets[0].deploy|length' "$1") - 1 ))`;do
echo "        - name: $(jq .secrets[0].deploy[$i].name "$1"|tr -d '"')
          valueFrom:
            secretKeyRef:
              name: $(jq .secrets[0].deploy[$i].name "$1"|tr -d '"')">>"$2"-secret
              key: $(jq .secrets[0].deploy[$i].namekey $1|tr -d '"').key
              
			done
		fi
echo "        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: '100Mi'
            cpu: '200m'
          limits:
            memory: '512Mi'
            cpu: '1000m'">>"$2"
	}


## Structural functions
	function deploy_app(){
		FILE=""
		echo "This allow you to deploy an APP" 
		read -p "Write where is your file variables.json located Ex: /home/user/variables.json: " FILE
		if test -f "$FILE";then
			echo "File correct finded"
			CONFIG_FILE="config_$(jq .program "$FILE"|tr -d '"')$(date +%y_%m_%d).yaml"
			touch "$CONFIG_FILE"
			create_namespace "$FILE" "$CONFIG_FILE"
			create_serviceaccount "$FILE" "$CONFIG_FILE" 
			create_secrets "$FILE" "$CONFIG_FILE"
			create_secrettls "$FILE" "$CONFIG_FILE" 
			create_services "$FILE" "$CONFIG_FILE" 
			create_ingress "$FILE" "$CONFIG_FILE" 
			create_deployment "$FILE" "$CONFIG_FILE" 
		fi
	}



#### MAIN FUNCTION
	function main(){
		menu
		select_option
	}
main




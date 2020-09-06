# Proceso de instalación

## Leyenda
Como hay variables que no van a estar públicas, como por ejemplo contraseñas, haré referencia a estos datos con la siguiente nomenclatura:

    1. .kp para los valores del keepass.
        Las rutas estarán separadas por .
        Por ejemplo la rute en el keepass /general/claves/pass.txt será referenciada como .kp.general.claves.pass.txt
    


## Antes de instalar

Antes de empezar con la instalación, hay que hacer unos retoques en la BIOS y el sistema RAID.  

    1. Borramos todos los discos y RAIDs montados
    2. Creamos un nuevo RAID 1+0 con todos los discos disponibles
    3. Aplicamos los cambios
    4. Nos aseguramos de que la Virtualización este activada
    5. Guardamos y salimos :)

## Instalación del servidor

Estamos en un servidor, asi que empecemos evitando la tentación de usar la version de escritorio y usemos la de server.  
Usaremos el SO LTS Debian, que lo podremos encontrar [aqui](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.5.0-amd64-netinst.iso)  
Hay muchas guias acerca de como instalar, aun así, en la carpeta [install_SO](install_SO)hay capturas pantalla por pantalla de lo que debes ir haciendo. 

Los único que te puede variar es el nombre y el tamaño del disco en el que vas a instalar. Para el nombre debes seleccionar el disco que te salga, a la hora de que tamaño usar, tan solo pulsa siguiente para seleccionar el tamaño completo del disco.

Ya tenemos nuestro servidor instalado y listo para hacerle perrerias :)

## Configuración del servidor

###Primer arranque
Una vez instalado, vamos a ir ejecutando los siguientes comandos:

1. Logearos como root o cambiar de user usando el comando su
2. Actualizar todo  
    `apt update && apt install`
3. Para evitar que peten la mayoria de scripts que vamos a tirar, instalaremos sudo y algun paquetillo más  
    `apt install sudo net-tools htop git curl zip pv`
4. Ahora, añadiremos el usuario blancanieves a sudo con:  
    `visudo`  
    Aqui añadimos debajo de la linea %sudo para que nos quede asi  
    %sudo ALL=(ALL:ALL) ALL  
    `%blancanieves  ALL=(ALL:ALL) ALL`  
    Guardamos con CTRL + X , yes y enter  
    Probamos que podemos ejecutar sudo desde el user blancanieves

### Establecer una IP estatica

La ip estatica nos sirve para mantener la misma IP en la subred aunque reiniciemos la máquina. Para ello hay que saber:
    G. Gateway
    M. Mascara de red
    I. Ip que queremos tener
    B. Broadcast IP
    N. Network IP
    A. Adaptador de red (eth0, wlan0, enp0s3...)
Como estos datos pueden variar (ver esquema de red), pondré los comandos a seguir utilizando las letras G,M,I... mencionadas anteriormente.

1. Ejecutar el siguiente comando y anotar el nombre del adaptador red que estemos usando (suele set eth0, wlan0 (el lo que sale a la izq del todo))  
        `ip a`
2. Acceder como root al archivo /etc/network/interfaces  
        `sudo nano  /etc/network/interfaces`
        Ahí, y sabiendo todas las anteriores direcciones, dejar el archivo como en el ejemplo installation/config/interfaces  
3. Ejecuta tambien los siguientes comandos para identificar el dns
        `echo "domain localdomain" >> /etc/resolv.conf`
        `echo "search localdomain" >> /etc/resolv.conf`
4. Reiniciar con  
        `sudo reboot`
5. Comprobar que la ip es la que hemos especificado. Usa de nuevo 
        `ip a`

### Crear el user notroot

Es conveniente tener un usuario que no tenga permisos de administación, para que pueda ver pero no tocar. Por ello crearemos este usuario desde root:

1. Ejecutar el comando para la creacion de usuario  
    `sudo adduser notroot`
2. Usamos la contraseña que encontramos en .kp.blancanieves.notroot.pass
3. Creamos la carpeta .ssh y creamos el archivo authorized_keys  
    `sudo mkdir -p /home/notroot/.ssh`  
    `sudo touch /home/notroot/.ssh/authorized_keys`
4. Agregamos los certificados .pub CD_powered y CD_normal al archivo authorized_keys  
    Una vez subidos al server, se pueden agregar con el comando  
    `sudo cat CD_* >> /home/notroot/.ssh/authorized_keys`
5. Listo

### Configurar el SSH

1. Ahora vamos a pegarnos con el SSH. Primero crea la ruta con el comando  
    `mkdir -p /home/blancanieves/.ssh`
2. Ahora, sube tu certificado publico al archivo /home/blancanieves/.ssh/authorized_keys (usa el user blancanieves y el siguiente comando desde tu equipo)  
    `scp tuarchivo blancanieves@ip:/home/blancanieves/.ssh/authorized_keys` 
3. Para facilitar las cosas, copia el archivo sshd_config que te he dejado en la carpeta installation/configs en la ruta del server /etc/ssh/sshd_config  
    `scp installation/configs/sshd_config blancanieves@ip:/home/blancanieves`
4. Conectate al servidor y mueve el archivo sshd_config a la ruta /etc/ssh/sshd_config (necesitaras estar como root)
5. Reinicia el ssh con:  
    `service ssh restart`
6. Ahora prueba a logearte usando tu certificado y el puerto 2222  
    `ssh blancanieves@ip -p 2222`
7. Si todo ha salido bien debes poder conectart sin usar pass :)
8. Recuerda agregar aqui SOLO el certificado CD_powered, encontrarás ambos en el apartado .kp.CDcerts (estan en la pestaña advanced ;) )


## Kubernetes

Una vez que tenemos hecho todo lo anterior, ya estariamos preparados para instalar nuestro Kubernetes y empezar a configurar todo. 

### Instalar Docker

Para instalar kuberntes tan solo sigue estos pasos. De momento esto es común tanto para el nodo maestro(blancanieves) como para el resto. En caso de que haya algún paso que sea solo para los esclavos(enanitos), será indicado.

1. Actualizar la lista de paquetes  
    `sudo apt-get update`  
2. Instalar Docker  
    `sudo apt-get install docker.io`
3. Comprueba que se ha instalado correctamente  
    `docker ––version`
4. Habilita la ejecución de docker al inicio  
    `sudo systemctl enable docker`  
5. Comprueba que este habilitado y corriendo  
    `sudo systemctl status docker`  
6. Si no esta corriendo, arrancalo con este comando  
    `sudo systemctl start docker`
7. Probar que el grupo esta creado  
    `sudo groupadd docker`
8. Agregar blancanieves a ese grupo para no necesitar sudo  
    `sudo usermod -aG docker $USER`
9. Aplicar los cambios  
    `newgrp docker`

### Agregar la clave y los repositorios necesarios

Esta parte es necesaria para comprobar que el software es autentico y poder descargarlo a través de apt

1. Comprueba que curl y gnupg esta instalado 
     `sudo apt-get install curl gnupg` 
2. Agrega la clave a apt  
    `curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add`  
3. Agrega los repositorios. Si no te reconoce el comando, ejecuta el paso 4 en su lugar  
    `sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"`  
4. **SI EL PASO ANTERIOR NO HA FUNCIONADO** Ejecuta los siguientes  
    `sudo apt edit-sources`  
    selecciona nano(opcion 1)
    Ahí, baja hasta abajo y pega(Ctrl+shift+v) la siguiente linea  
    `deb http://apt.kubernetes.io/ kubernetes-xenial main`  
    Guarda con CTRL+X ,y , enter
5. Actualiza el listado de repositorios  
    `sudo apt update`


### Instala Kubertnetes

1. Instalar los paquetes necesarios  
    `sudo apt-get install kubeadm kubelet kubectl`
2. Para no tener problemas en el futuro, deshabilitamos las actualizaciones  automáticas de estos paquetes  
    `sudo apt-mark hold kubeadm kubelet kubectl`
3. Comprueba que este todo instalado correctamente   
    `kubeadm version`

### Configurando arranque de Kubernetes

1. Deshabilitamos la memoria swap para evitar posibles problemas más adelante  
    `sudo swapoff –all` o `sudo swapoff -a`
2. 1. **SI EL COMANDO ANTERIOR FALLA** deshabilitaremos la swap de la siguiente manera  
    `free -h`  
    1. 2. Si aqui **NO** hay una entrada que ponga swap, continua con el paso 2.
    Modifica /etc/fstab y comenta(añade # al principio) a la linea que contenga la palabra swap. Luego guarda  
    `sudo nano /etc/fstab`
3. Asignamos un nombre estático al nodo-master  
    `sudo hostnamectl set-hostname blancanieves`
    2. 1. En caso de que sea un NODO ESCLAVO ejecutar este comando en lugar del anterior  
    `sudo hostnamectl set-hostname enanito1`

### Arrancando Kubernetes

Ahora, desde el nodo master ejecutamos los siguientes comandos  

1. Inicializamos el cluster **LEE EL SIGUIENTE PASO ANTES**  
    `sudo kubeadm init --pod-network-cidr=10.244.0.0/16`
2. **MUY AL LORO** al final nos sale un mensaje que pone *kubeadm join*, haced foto, captura o lo que querais, pero dejad bien guardada y apuntada esa entrada, ya que contiene el token que usaremos para conectar a los "enanitos" al cluster cuando queramos  
3. Creamos el directorio para el cluster  
    `mkdir -p $HOME/.kube`  
    `sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`   
    `sudo chown $(id -u):$(id -g) $HOME/.kube/config`  

### Creando el pod para gestion de Network del cluster

Es una manera de que los pods puedan comunicarse. Usarán la network virtual flannel  
`kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`   

Una vez hecho, comprobamos que todo este funcionando  
`kubectl get pods --all-namespaces`  

### (EXTRA) Agregar workers (enanitos) al cluster

En caso de que quieras agregar más nodos para que se repartan el trabajo en el futuro, se hace así.  
Una vez que en el nodo se ha instalado todo el sistema kubernetes, agrega este pod al cluster así. Desde el nodo worker, ejecuta el siguiente comando, sustituye el token por el token que has guardado en el paso de Arrancando Kubernetes.  
    `kubeadm join --discovery-token tokenquehasguardado --discovery-token-ca-cert-hash sha256:1234..cdef 1.2.3.4:6443`  
Ahora probamos que se haya añadido correctamente.  
    `kubectl get nodes`


### enlaces de interes
https://github.com/calebhailey/homelab/issues/3 (maquinas no arrancan)

### ejemplo de inicio

kubectl run bootcamp --image=docker.io/jocatalin/kubernetes-bootcamp:v1 --port=8080

kubectl expose deployment/bootcamp --type="LoadBalancer" --port 8080

export EXTERNAL_IP=$(kubectl get service bootcamp --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')

export PORT=$(kubectl get services --output=jsonpath='{.items[0].spec.ports[0].port}')

curl "$EXTERNAL_IP:$PORT"


para parchear las conexiones
kubectl patch svc <svc-name> -n <namespace> -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.31.71.218"]}}'
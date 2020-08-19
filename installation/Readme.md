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
    3. Reiniciar con  
        `sudo reboot`
    4. Comprobar que la ip es la que hemos especificado. Usa de nuevo 
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

### Permitir a las IPTABLES ver el trafico puente

Lo primero vamos a hacer va a ser configurar el sistema para que las iptables "vean" correctamente el trafico que esta pasando:

1. Habilita el modulo necesario  
    `sudo modprobe br_netfilter`
2. Comprueba que se ha habilitado (debe devolverte algo)
    `lsmod | grep br_netfilter`
3. a













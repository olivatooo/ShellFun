#!/bin/bash
printf "\n\n/ ---------------- Nginx + Gunicorn + Django v0.1 ----------------------- /\n\n"
if [ "$(id -u)" != "0" ]; then
   echo "Esse script deve ser executado como ROOT" 1>&2
   exit 1
fi
printf "\nDeseja criar um novo usuário para rodar a aplicação Django? Por questões de segurança recomenda-se criar um.[Y/n]:"
read criauser
if [ "$criauser" = "Y" ]
then
	printf "\nDigite o nome do usuário novo a ser criado para rodar a aplicação:"
	read novouser
	printf $novouser
	sudo useradd -m $novouser
	sudo usermod -a -G sudo $novouser
	sudo su $novouser
	cd
fi
sudo apt-get update
sudo apt-get -y install python3 nginx python3-pip python3-dev libpq-dev htop
sudo -H pip3 install --upgrade pip
sudo -H pip3 install virtualenv
printf "\nDigite um nome para o virtualenv, a pasta onde vai estar o seu projeto Django:"
read virtualnovo
mkdir ~/$virtualnovo
cd ~/$virtualnovo
virtualnovo = "${virtualnovo}_env"
virtualenv $virtualnovo
source $virtualnovo/bin/activate
pip3 install django gunicorn psycopg2
django-admin.py startproject $virtualnovo .
nano $virtualnovo/settings.py
cd ~/$virtualnovo
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py createsuperuser
python3 manage.py collectstatic
#python3 manage.py runserver 0:0:0:0:8000
deactivate
sudo cat <<EOT >> /etc/init/gunicorn.conf
description "Gunicorn application server handling myproject"
start on runlevel [2345]
stop on runlevel [!2345]
respawn
setuid $USER
setgid www-data
chdir /home/$novouser/$virtualnovo
exec $virtualnovo/bin/gunicorn --workers 3 --bind unix:/home/$USER/$virtualnovo/$virtualnovo.sock $virtualnovo.wsgi:application
EOT
sudo systemctl start gunicorn.service
sudo nano /etc/nginx/sites-available/myproject
#server {
#    listen 80;
#    server_name server_domain_or_IP;
#
#    location = /favicon.ico { access_log off; log_not_found off; }
#    location /static/ {
#        root /home/user/myproject;
#    }
#
#    location / {
#        include proxy_params;
#        proxy_pass http://unix:/home/user/myproject/myproject.sock;
#    }
#}
sudo ln -s /etc/nginx/sites-available/$virtualnovo /etc/nginx/sites-enabled
sudo nginx -t
if [ "$?" = "0" ]; then
	sudo service nginx restart
else
	echo "Deu erro rapaz!" 1>&2
	exit 1
fi

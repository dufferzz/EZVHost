#!/bin/bash
# This script is ALPHA! It will probably break a lot!
# DO NOT RUN UNLESS YOU HAVE READ THE CODE


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

DEFAULT_FILE=/etc/nginx/sites-available/default
ENABLED=/etc/nginx/sites-enabled/
AVAILABLE=/etc/nginx/sites-available/

init(){
clear


printf "This script is ${RED}ALPHA${NC} Do not NOT in PRODUCTION!\n"

if [ `whoami` != 'root' ]
  then
    printf "${RED}You must run as root to modify nginx config files."
    exit
fi

if [ -f "$DEFAULT_FILE" ]; then
    printf ${GREEN}"$DEFAULT_FILE${NC} exists.\n"
    ask_subdomain
else 
    printf "${RED}ERROR!!${NC}$DEFAULT_FILE does not exist. exiting."
    exit;
fi
}




ask_subdomain(){

read -p 'Desired Subdomain: ' subdomain
printf "You have selected ${GREEN}${subdomain}${NC} is this correct?\n"

select yn in "Yes" "No"; do
    case $yn in
        Yes ) check_file_exists; break;;
        No ) ask_subdomain break;
    esac
done
}




check_file_exists(){
    FILE=${AVAILABLE}/${subdomain}
if [ -f "$FILE" ]; then
    printf "${RED}ERROR!!${NC} $FILE already exists!"
    exit 1;
else 
    printf "\n ${GREEN}$FILE does not exist.. Creating.. ${NC}\n\n"
    ask_hostname
fi
}



ask_hostname(){

read -p 'Host Name (ie: localhost:4001): ' hostname
printf "\nYou have selected ${GREEN}${hostname}${NC} is this correct?\n"

select yn in "Yes" "No"; do
    case $yn in
        Yes ) ask_nginx_questions; break;;
        No ) ask_hostname break;
    esac
done
}

ask_nginx_questions(){
    # ask questions...
    printf "\n Okay, Now some questions about nginx config\n"
    printf "Which headers do you want?\n"
    
    create_vhost_file
}


create_vhost_file(){
    echo "server {
    server_name ${subdomain};
    location / {
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_pass http://${hostname};
    }
}" >> ${AVAILABLE}/${subdomain}
printf "\n${file} created succesfully!\n\n"
create_symlinks
}

create_symlinks(){
    printf "Now creating symlinks for ${GREEN}${FILE}${NC}\n\n"
    ln -s ${FILE} ${ENABLED}/${subdomain}
    ls -la ${ENABLED}
    printf "Symlinks created\n\n"
    check_certbot
}




check_certbot(){
printf "Do you want to run Certbot to expand cert with ${GREEN}${subdomain}${NC}?\n"

select yn in "Yes" "No"; do
    case $yn in
        Yes ) check_website_status; break;;
        No ) printf "HTTP only is bad! As you wish, master.." break;
    esac
done
}


check_website_status(){
    response=$(curl --write-out '%{http_code}' --silent --output /dev/null ${subdomain})
    
if [[ "$response" -ne 200 ]] ; then
  printf "Site status changed to ${GREEN}${response}${NC}\n\n";
  run_certbot
else
  exit 0
fi
}

run_certbot(){
    printf "Running Certbot! \n"
    certbot --expand
}



init
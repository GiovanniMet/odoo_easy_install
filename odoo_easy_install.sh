#!/bin/bash
################################################################
#This Script Install ODOO last relase.                         #
################################################################
# Developed By Giovanni Metitieri, follow me on Github!        #
#                         https://github.com/GiovanniMet/      #
################################################################
# Thanks to:                                                   #
# https://github.com/aschenkels-ictstudio/odoo-install-scripts #
# for the initial relase , this is based on it idea.           #
################################################################
# Version 1.0 alpha                                            #
# Build Date 20/12/2015                                        #
# Support Debian and RHEL based distro.                        #
################################################################

#Here you can edit!
settings(){
    #set the postgress 's odoo user name
    ODOO_USER="odoo"
    #set the admin password
    ODOO_ADMIN="adminpassword"
}

#don't edit from this line to the end!
get_os() {
    # Get OS type and set corresponding variables
    if [ -f /etc/debian_version ]; then
        if [ -x /usr/bin/lsb_release ]; then
            OS_VERSION=`lsb_release -d | awk '{print $2,$3}'`
        else
            OS_VERSION=`cat /etc/debian_version`
        fi
        OS="debian"
        APACHE_NAME="apache2"
    elif [ -f /etc/redhat-release ]; then
        OS="redhat"
        OS_VERSION=`cat /etc/redhat-release`
        APACHE_NAME="httpd"
    else
        cprint YELLOW "[WARNING] Unrecognized operating system. Script now Exit"
        OS="unknown"
        APACHE_NAME="apache2"
        OS_VERSION="unknown"
        exit 1
    fi
    echo "[INFO] System type: ${OS}. Version: ${OS_VERSION}"
}

get_ip(){
    SERVER_IP=$(hostname -I | awk '{print $1}')
}

check_root(){
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

update_server(){
    if [ "$OS" = "debian" ]; then
        apt-get clean
        apt-get update
        apt-get upgrade -y
    else
        yum clean all
        yum update
        yum upgrade -y
    fi
}

postgres_install(){
     if [ "$OS" = "debian" ]; then
        apt-get install -y postgresql postgresql-client
    else
        yum install -y postgresql-server
        postgresql-setup initdb
        systemctl enable postgresql
        systemctl start postgresql
        echo "If problem, go to https://wiki.postgresql.org/wiki/YUM_Installation"
    fi
}

postgres_configure(){
    su - postgres -c "createuser --createdb --no-createrole $ODOO_USER"
}

odoo_easy_install(){
    #install using auto-install script
    if [ "$OS" = "debian" ]; then
        wget -O - https://nightly.odoo.com/odoo.key | apt-key add -
        echo "deb http://nightly.odoo.com/9.0/nightly/deb/ ./" >> /etc/apt/sources.list
        apt-get update
        apt-get install -y odoo
    else
        yum install -y epel-release
        yum-config-manager --add-repo=https://nightly.odoo.com/9.0/nightly/rpm/odoo.repo
        yum install -y odoo
        systemctl enable odoo
        systemctl start odoo
    fi
}

odoo_configure(){
    sed -i s/"; admin_passwd = admin"/"admin_passwd = $ODOO_ADMIN"/g /etc/odoo/openerp-server.conf
    sed -i s/"db_user = .*"/"db_user = $ODOO_USER"/g /etc/odoo/openerp-server.conf

db_user = odoo

}

clean_server(){
    if [ "$OS" = "debian" ]; then
        apt-get autoremove
    else
        yum autoremove
    fi
}

all_done(){
    cat <<- EOF
Install Complete, to check if all work , 
please go to: http://$SERVER_IP:8069

Have a nice day!
EOF
}

main(){
    #Initial operation
    check_root
    settings
    get_os
    update_server
    #Install and configure Postgres database.
    postgres_install
    postgres_configure
    #Install and configure Odoo
    odoo_easy_install
    odoo_configure
    #Clean
    clean_server
    #All Done Message
    get_ip
    all_done
}

main
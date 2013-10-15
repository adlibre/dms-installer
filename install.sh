#!/usr/bin/env bash
# 
# Adlibre DMS Installer v0.1.0
#
# Usage eg: curl -s https://raw.github.com/macropin/dms-installer/master/install.sh | bash -s all
#
# TODO:
#     * Warn if iptables prevent access to http
#     * Better error handling
#     * Add support for opererating systems other than CentOS 6
#     * Allow setting of superuser password

# ------------------------------------------------------------------------------
#
# Config

DEPLOY_ROOT='/srv/www'
DEPLOY_INSTANCE='dms'
DMS_DEPLOY_USER='wwwpub'
DMS_SOURCE_URL='git+git://github.com/adlibre/Adlibre-DMS.git'
SUPERUSER_EMAIL='admin@example.com'

# ------------------------------------------------------------------------------
# Functions

function _install_epel {
    # Install EPEL if not installed
    if ! rpm -q epel-release 1> /dev/null; then
        rpm -U http://download.fedoraproject.org/pub/epel/$(egrep -oe '[0-9]' /etc/redhat-release | head -n1)/$(uname -m)/epel-release-6-8.noarch.rpm;
    fi    
}

function _install_couchdb {
    # Install CouchDB if not installed
    if ! rpm -q couchdb 1> /dev/null; then
        yum -y -q install couchdb
        chkconfig couchdb on
        service couchdb start
    fi
}

function _install_lighttpd {
    # Install lighttpd if not installed
    if ! rpm -q lighttpd lighttpd-fastcgi 1> /dev/null; then
        yum -y -q install lighttpd-fastcgi
        chkconfig lighttpd on
        cp /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.orig
        # Customise the config
        sed -i -e 's@^server.use-ipv6 .*@server.use-ipv6 = "disable"@g' /etc/lighttpd/lighttpd.conf # disable ipv6
        sed -i -e 's@#include_shell \"cat /etc/lighttpd/vhosts.d/\*.conf\"@include_shell \"cat /etc/lighttpd/vhosts.d/*.conf\"@g' /etc/lighttpd/lighttpd.conf # enable vhosts config
        cp /etc/lighttpd/modules.conf /etc/lighttpd/modules.conf.orig
        sed -i -e 's@#  "mod_alias"@  "mod_alias"@g' /etc/lighttpd/modules.conf
        sed -i -e 's@#  "mod_redirect"@  "mod_redirect"@g' /etc/lighttpd/modules.conf
        sed -i -e 's@#  "mod_rewrite"@  "mod_rewrite"@g' /etc/lighttpd/modules.conf
        sed -i -e 's@#  "mod_setenv"@  "mod_setenv"@g' /etc/lighttpd/modules.conf
        cp /etc/lighttpd/modules.conf /etc/lighttpd/modules.conf.orig
        sed -i -e 's@#include "conf.d/compress.conf@include "conf.d/compress.conf@g' /etc/lighttpd/modules.conf
        sed -i -e 's@#include "conf.d/proxy.conf@include "conf.d/proxy.conf@g' /etc/lighttpd/modules.conf
        sed -i -e 's@#include "conf.d/expire.conf@include "conf.d/expire.conf@g' /etc/lighttpd/modules.conf
        sed -i -e 's@#include "conf.d/fastcgi.conf@include "conf.d/fastcgi.conf@g' /etc/lighttpd/modules.conf
        # Make missing dirs
        mkdir -p /var/cache/lighttpd/compress /var/run/lighttpd
        chown -R lighttpd:lighttpd /var/cache/lighttpd/ /var/run/lighttpd
        # Start
        service lighttpd restart        
    fi
}

function _install_python_requirements {
    # Python environment
    if ! rpm -q python-virtualenv python-pip 1> /dev/null; then
        yum -y -q install python-virtualenv python-pip
    fi
    
    # Install gcc & development libs so we can compile PIL later (FIXME: PIL Required?)
    REQS='gcc freetype ghostscript freetype-devel libpng libjpeg-turbo libpng-devel libjpeg-turbo-devel python-devel'
    if ! rpm -q $REQS 1> /dev/null; then
        yum -y -q install $REQS
    fi
    
    # Deployment tools
    if ! rpm -q git 1> /dev/null; then
        yum -y -q install git
    fi
}

function _deploy_dms {

    # Disable selinux
    sed -i -e 's@SELINUX=.*@SELINUX=disabled@g' /etc/selinux/config
    setenforce 0
    
    # Add wwwpub if not exist 
    if ! getent passwd ${DMS_DEPLOY_USER} 1>/dev/null; then
        adduser ${DMS_DEPLOY_USER};
        usermod -G lighttpd,${DMS_DEPLOY_USER} lighttpd  # allow lighttpd to read socket
    fi

    # Create virtualenv root
    if [ ! -d ${DEPLOY_ROOT} ]; then
        mkdir -p ${DEPLOY_ROOT}
        chown ${DMS_DEPLOY_USER}.${DMS_DEPLOY_USER} ${DEPLOY_ROOT}
    fi
    
    # Deploy or redeploy
    if [ ! -d ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} ]; then
        NEW_DEPLOY=true
        # Deploy using Python Bootstrap
        su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT} && curl --silent https://raw.github.com/adlibre/python-bootstrap/master/bootstrap.sh | bash -s ${DEPLOY_INSTANCE} ${DMS_SOURCE_URL}"
    else
        NEW_DEPLOY=false
        # Redeploy
        su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} && source bin/activate && pip install ${DMS_SOURCE_URL}"
    fi
    
    # Link in our Procfile / Deployfile to correct location
    su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} && ln -sf deployment/Deployfile && ln -sf deployment/Procfile" 
    
    # Link in manage.py
    su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT}/${DEPLOY_INSTANCE}/bin && ln -sf ../adlibre_dms/manage.py" 
    
    # Create env file
    if [ ! -f ${DEPLOY_ROOT}/${DEPLOY_INSTANCE}/.env ]; then 
        su ${DMS_DEPLOY_USER} -c "echo 'PATH=\$VIRTUAL_ENV/adlibre_dms:\$PATH' > ${DEPLOY_ROOT}/${DEPLOY_INSTANCE}/.env"
    fi
    
    # Create local settings
    if [ ! -f ${DEPLOY_ROOT}/${DEPLOY_INSTANCE}/adlibre_dms/local_settings.py ]; then
        su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} && cp adlibre_dms/local_settings.py.example adlibre_dms/local_settings.py"
        echo "Created adlibre_dms/local_settings.py from example. You should customise this."
    fi
    
    # Run Deployfile commands
    su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} && ${DEPLOY_ROOT}/${DEPLOY_INSTANCE}/bin/bureaucrat deploy --logpath log" 
    
    if $NEW_DEPLOY; then
        # Create super user
        echo "#"
        echo "# Creating default Super User 'admin' with email '${SUPERUSER_EMAIL}'"
        echo "#"
        su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} && source bin/activate && manage.py createsuperuser --username=admin --email=${SUPERUSER_EMAIL} --noinput --settings=settings_prod"
    fi
    
    # Lighttpd config
    ln -f -s ${DEPLOY_ROOT}/${DEPLOY_INSTANCE}/deployment/lighttpd.conf /etc/lighttpd/vhosts.d/${DEPLOY_INSTANCE}.conf
    service lighttpd reload
    
    # Install Crontab
    # TODO: add check if this is already setup.
    # New Bureaucrat method
    #su ${DMS_DEPLOY_USER} -c "echo '@reboot cd ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} && ${DEPLOY_ROOT}/${DEPLOY_INSTANCE}/bin/bureaucrat restart 1> /dev/null' | crontab"

    su ${DMS_DEPLOY_USER} -c "echo '@reboot ${DEPLOY_ROOT}/${DEPLOY_INSTANCE}/deployment/manage-fcgi.sh restart settings_prod ${DEPLOY_INSTANCE}' | crontab"

}

function show_usage {
    echo "usage: `basename $0` [ all ] [ dms | couchdb ]"
}

function show_banner {
    echo "********************************************************************************"
    echo "                           Adlibre DMS Installer"
    echo "********************************************************************************"
}

# ------------------------------------------------------------------------------
# Tasks

function couchdb_server {

    echo "*** Installing CouchDB ***"
    _install_epel
    _install_couchdb
}

function app_server {
    echo "*** Installing Adlibre DMS Server ***"
    _install_epel
    _install_lighttpd
    _install_python_requirements
    _deploy_dms
}

# ------------------------------------------------------------------------------
# Tests

if [ ! $(whoami) = "root" ]; then
    echo "Error: Must run as root."
    exit 99
fi

if [ "$1" == "" ]; then
    show_usage
    exit 99
fi

if [ "$(egrep -oe '[0-9]' /etc/redhat-release | head -n1)" -ne "6" ]; then
    echo "Error: Must be run on CentOS 6"
    exit 99
fi

# ------------------------------------------------------------------------------
# Main
while test $# -gt 0; do
    case "$1" in
    all)
        show_banner
        couchdb_server
        app_server
        shift
        ;;
    dms)
        show_banner
        app_server
        shift
        ;;
    couchdb)
        show_banner
        couchdb_server
        shift
        ;;
    --)	# Stop option processing.
        shift; break
        ;;
    *)
        echo >&2 "$0: unrecognized option \`$1'"
        show_usage
        exit 99
        ;;
    esac
done

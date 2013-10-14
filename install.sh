#!/usr/bin/env bash
# 
# Adlibre DMS Installer
#

# ------------------------------------------------------------------------------
#
# Config

DEPLOY_ROOT='/srv/www'
DEPLOY_INSTANCE='dms'
DMS_DEPLOY_USER='wwwpub'
DMS_SOURCE_URL='git+git://github.com/macropin/Adlibre-DMS.git'

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
        service lighttpd start
    fi
}

function _install_python_requirements {
    # Python environment
    if ! rpm -q python-virtualenv python-pip 1> /dev/null; then
        yum -y -q install python-virtualenv python-pip
    fi
    
    # Install gcc & development libs so we can compile PIL later (FIXME: PIL Required?)
    if ! rpm -q gcc freetype freetype-devel libpng libjpeg libpng-devel libjpeg-devel python-devel 1> /dev/null; then
        yum -y -q install gcc freetype freetype-devel libpng libjpeg libpng-devel libjpeg-devel python-devel
    fi
    
    # Deployment tools
    if ! rpm -q git 1> /dev/null; then
        yum -y -q install git
    fi
}

function _deploy_dms {
        
    # Add wwwpub if not exist 
    if ! getent passwd ${DMS_DEPLOY_USER} 1>/dev/null; then
        adduser ${DMS_DEPLOY_USER};
    fi

    # Create virtualenv root
    if [ ! -d ${DEPLOY_ROOT} ]; then
        mkdir -p ${DEPLOY_ROOT}
        chown ${DMS_DEPLOY_USER}.${DMS_DEPLOY_USER} ${DEPLOY_ROOT}
    fi

    if [ ! -d ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} ]; then
        # Deploy using Python Bootstrap
        su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT} && curl --silent https://raw.github.com/adlibre/python-bootstrap/master/bootstrap.sh | bash -s ${DEPLOY_INSTANCE} ${DMS_SOURCE_URL}"
    else
        # Redeploy
        su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} && source bin/activate && pip install ${DMS_SOURCE_URL}"
    fi
    
    # Run Deployfile commands
    su ${DMS_DEPLOY_USER} -c "cd ${DEPLOY_ROOT}/${DEPLOY_INSTANCE} && ${DEPLOY_ROOT}/${DEPLOY_INSTANCE}/bin/bureaucrat deploy" 

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

# ------------------------------------------------------------------------------
# Tasks

function couchdb_server {
    echo "*** Installing CouchDB Server ***"
    _install_epel
    _install_couchdb
}

function app_server {
    echo "*** Installing Adlibre DMS App Server ***"
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

# ------------------------------------------------------------------------------
# Main
while test $# -gt 0; do
    case "$1" in
    all)
        couchdb_server
        app_server
        shift
        ;;
    dms)
        app_server
        shift
        ;;
    couchdb)
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

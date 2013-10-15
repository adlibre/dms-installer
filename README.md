# Adlibre DMS Installer

This will install the latest version of Adlibre DMS on a [CentOS 6](http://www.centos.org) minimal
install. 

## Usage

	usage: install.sh [ all ] [ dms | couchdb ]

If you wish to customise the installation please download and review the
default configuration settings at the top of the script.

## Installation

For the simplest install install all the components on a single host with
`install.sh all`.

	[root@centos6 ~]# curl -s https://raw.github.com/adlibre/dms-installer/master/install.sh | bash -s all
	********************************************************************************
							   Adlibre DMS Installer
	********************************************************************************
	*** Installing CouchDB ***
	*** Installing Adlibre DMS Server ***
	Installing git+git://github.com/adlibre/Adlibre-DMS.git in dms.
	  You are installing an externally hosted file. Future versions of pip will default to disallowing externally hosted files.
	
	Virtualenv dms created.
	
	Run
	   $ source dms/bin/activate && cd dms
	to enter the virtual environment and
	   $ deactivate
	to exit the environment.
	Created adlibre_dms/local_settings.py from example. You should customise this.
	Running task syncdb: manage.py syncdb --noinput --settings=settings_prod
	Running task syncplugins: manage.py syncplugins --settings=settings_prod
	Running task collectstatic: manage.py collectstatic --noinput --settings=settings_prod
	#
	# Creating default Super User 'admin' with email 'admin@example.com'
	#
	DMS Version: 1.1.6
	
	Superuser created successfully.
	Reloading lighttpd: [  OK  ]
	#
	# Start / Restarting DMS
	#
	Starting adlibre_dms with settings_prod: DMS Version: 1.1.6

## Upgrade

To upgrade Adlibre DMS with the latest code simply run
`curl -s https://raw.github.com/adlibre/dms-installer/master/install.sh | bash -s dms`

	[root@centos6 ~]# curl -s https://raw.github.com/adlibre/dms-installer/master/install.sh | bash -s dms
	********************************************************************************
							   Adlibre DMS Installer
	********************************************************************************
	*** Installing Adlibre DMS Server ***
	Downloading/unpacking git+git://github.com/adlibre/Adlibre-DMS.git
	  Cloning git://github.com/adlibre/Adlibre-DMS.git to /tmp/pip-ceCIYk-build
	  Running setup.py egg_info for package from git+git://github.com/adlibre/Adlibre-DMS.git
	Requirement already satisfied (use --upgrade to upgrade): Django==1.4.3 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): python-magic==0.4.2 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): django-compressor==1.1.2 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): docutils==0.10 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): couchdbkit==0.6.1 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): django-widget-tweaks==1.0 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): django-taggit==0.9.3 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): django-bcp==0.1.8 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): adlibre-plugins==0.1.1 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): flup==1.0.3.dev-20110405 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): bureaucrat==0.1.0 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): argparse in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): django-log-file-viewer==0.6 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): django-jenkins==0.14.0 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): ghostscript==0.4.1 in ./lib/python2.6/site-packages (from adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): django-appconf>=0.4 in ./lib/python2.6/site-packages (from django-compressor==1.1.2->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): restkit>=3.3 in ./lib/python2.6/site-packages (from couchdbkit==0.6.1->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): reportlab in ./lib/python2.6/site-packages (from django-bcp==0.1.8->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): distribute in ./lib/python2.6/site-packages (from adlibre-plugins==0.1.1->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): coverage>=3.4 in ./lib/python2.6/site-packages (from django-jenkins==0.14.0->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): pylint>=0.23 in ./lib/python2.6/site-packages (from django-jenkins==0.14.0->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): setuptools in ./lib/python2.6/site-packages (from ghostscript==0.4.1->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): six in ./lib/python2.6/site-packages (from django-appconf>=0.4->django-compressor==1.1.2->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): http-parser>=0.8.3 in ./lib/python2.6/site-packages (from restkit>=3.3->couchdbkit==0.6.1->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): socketpool>=0.5.3 in ./lib/python2.6/site-packages (from restkit>=3.3->couchdbkit==0.6.1->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): logilab-common>=0.53.0 in ./lib/python2.6/site-packages (from pylint>=0.23->django-jenkins==0.14.0->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): astroid>=0.24.3 in ./lib/python2.6/site-packages (from pylint>=0.23->django-jenkins==0.14.0->adlibre-dms==1.1.6)
	Requirement already satisfied (use --upgrade to upgrade): unittest2>=0.5.1 in ./lib/python2.6/site-packages (from logilab-common>=0.53.0->pylint>=0.23->django-jenkins==0.14.0->adlibre-dms==1.1.6)
	Cleaning up...
	Running task syncdb: manage.py syncdb --noinput --settings=settings_prod
	Running task syncplugins: manage.py syncplugins --settings=settings_prod
	Running task collectstatic: manage.py collectstatic --noinput --settings=settings_prod
	Reloading lighttpd: [  OK  ]
	#
	# Start / Restarting DMS
	#
	Stopping adlibre_dms: Process(s) Terminated.
	Starting adlibre_dms with settings_prod: DMS Version: 1.1.6
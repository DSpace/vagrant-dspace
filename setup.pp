# Setup Puppet Script
#
# This Puppet script does the following:
# 1. Initializes the VM 
# 2. Installs base DSpace prerequisites (Java, Maven, Ant) via our custom "dspace" Puppet module
# 3. Installs PostgreSQL (via a third party Puppet module)
# 4. Installs Tomcat (via a third party Puppet module)
# 5. Installs DSpace via our custom "dspace" Puppet Module
#
# Tested on:
# - Ubuntu 16.04

# Global default to requiring all packages be installed & apt-update to be run first
Package {
  ensure => latest,                # requires latest version of each package to be installed
  require => Exec["apt-get-update"],
}

# Ensure the rcconf package is installed, we'll use it later to set runlevels of services
package { "rcconf":
  ensure => "installed"
}

# Global default path settings for all 'exec' commands
Exec {
  path => "/usr/bin:/usr/sbin/:/bin:/sbin:/usr/local/bin:/usr/local/sbin",
}


#-----------------------
# Server initialization
#-----------------------
# Add the 'partner' repositry to apt
# NOTE: $lsbdistcodename is a "fact" which represents the ubuntu codename (e.g. 'precise')
file { "partner.list":
  path    => "/etc/apt/sources.list.d/partner.list",
  ensure  => file,
  owner   => "root",
  group   => "root",
  content => "deb http://archive.canonical.com/ubuntu ${lsbdistcodename} partner
              deb-src http://archive.canonical.com/ubuntu ${lsbdistcodename} partner",
  notify  => Exec["apt-get-update"],
}

# Run apt-get update before installing anything
exec {"apt-get-update":
  command => "/usr/bin/apt-get update",
  refreshonly => true, # only run if notified
}

#------------------------------------------------------------
# Initialize base pre-requisites and define global variables.
#------------------------------------------------------------
# Initialize the DSpace module. This actually installs Java/Ant/Maven,
# and globally saves the versions of PostgreSQL and Tomcat we will install below.
#
# NOTE: ANY of these values (or any other parameter of init.pp) can be OVERRIDDEN
# via hiera in your local.yaml file. Just specify the parameter like
# "dspace::[param-name] : [param-value]" in local.yaml.
class { 'dspace':
  java_version       => '8',
  postgresql_version => '9.5',
  tomcat_package     => 'tomcat8',
  owner              => 'vagrant',  # OS user who "owns" DSpace
  db_name            => 'dspace',   # Name of database to use
  db_owner           => 'dspace',   # DB owner account info
  db_owner_passwd    => 'dspace',
  db_admin_passwd    => 'postgres', # DB password for 'postgres' acct
}


#----------------------------------------------------------------
# Create the PostgreSQL database (based on above global settings)
#----------------------------------------------------------------
dspace::postgresql_db { $dspace::db_name :
}

#-----------------------------------------------------
# Install Tomcat instance (based on above global settings)
# Tell it to use owner's ~/dspace/webapps as the webapps location
#-----------------------------------------------------
dspace::tomcat_instance { "/home/${dspace::owner}/dspace/webapps" :
}

#---------------------------------------------------
# Install DSpace in the owner's ~/dspace/ directory
#---------------------------------------------------
dspace::install { "/home/${dspace::owner}/dspace" :
  require => DSpace::Postgresql_db[$dspace::db_name], # Must first have a database
  notify  => Service['tomcat'],                       # Tell Tomcat to reboot after install
}

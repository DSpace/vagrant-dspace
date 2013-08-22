# DSpace initialization script
#
# This Puppet script does the following:
# - installs Java, Maven, Ant
# - installs Git & clones DSpace source code
#
# Tested on:
# - Ubuntu 12.04

# Global default to requiring all packages be installed & apt-update to be run first
Package {
  ensure => latest,                # requires latest version of each package to be installed
  require => Exec["apt-get-update"],
}

# Global default path settings for all 'exec' commands
Exec {
  path => "/usr/bin:/usr/sbin:/bin",
}


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

# Install DSpace pre-requisites (from DSpace module's init.pp)
# If the global fact "java_version" doesn't exist, use default value in 'dspace' module
if $::java_version == undef {
    include dspace
}
else { # Otherwise, pass the value of $::java_version to the 'dspace' module
    class { 'dspace':
       java_version => $::java_version,
    }
}

# Install PostgreSQL package
class { 'postgresql':
  charset => 'UTF8',
}

# Setup/Configure PostgreSQL server
class { 'postgresql::server':
  config_hash => {
    'listen_addresses'           => '*',
    'ip_mask_deny_postgres_user' => '0.0.0.0/32',
    'ip_mask_allow_all_users'    => '0.0.0.0/0',
    'manage_redhat_firewall'     => true,
    'manage_pg_hba_conf'         => true,
    'postgres_password'          => 'dspace',
  },
}

# Create a 'dspace' database
postgresql::db { 'dspace':
  user     => 'dspace',
  password => 'dspace'
}

# Install Tomcat package
include tomcat

# Create a new Tomcat instance
tomcat::instance { 'dspace':
   ensure    => present,
}

# Kickoff a DSpace installation for the 'vagrant' default user
dspace::install { vagrant-dspace:
   owner   => "vagrant",
   require => [Postgresql::Db['dspace'],Tomcat::Instance['dspace']]  # Require that PostgreSQL and Tomcat are setup
}

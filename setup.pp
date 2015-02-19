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
# - Ubuntu 12.04
# - Ubuntu 14.04

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

#--------------------------------------------------
# Initialize base pre-requisites (Java, Maven, Ant)
#--------------------------------------------------
# Initialize the DSpace module in order to install base prerequisites.
# These prerequisites are simply installed via the OS package manager
# in the DSpace module's init.pp script
include dspace

#------------------------
# Install PostgreSQL
#------------------------
# Init PostgreSQL module
# (We use https://github.com/puppetlabs/puppetlabs-postgresql/)
# DSpace requires UTF-8 encoding in PostgreSQL
class { 'postgresql::globals':
  encoding => 'UTF-8',
}

->

# Setup/Configure PostgreSQL server
class { 'postgresql::server':
  ip_mask_deny_postgres_user => '0.0.0.0/32',  # allows postgres use to connect from any IP
  ip_mask_allow_all_users    => '0.0.0.0/0',   # allow other users to connect from any IP
  listen_addresses           => '*',           # accept connections from any IP/machine
  postgres_password          => 'dspace',      # set password for "postgres"
}

->

# Create a 'dspace' database & 'dspace' user account (which owns the database)
postgresql::server::db { 'dspace':
  user     => 'dspace',
  password => 'dspace'
}

#-----------------------
# Install Tomcat
#-----------------------
# Lookup Tomcat installation settings from Hiera
# These settings should all be specified in default.yaml
$tomcat_package = hiera('tomcat_package')
$tomcat_service = hiera('tomcat_service')
$catalina_home  = hiera('catalina_home')
$catalina_base  = hiera('catalina_base')
$catalina_opts  = hiera('catalina_opts')

# Init Tomcat module
# (We use https://github.com/puppetlabs/puppetlabs-tomcat/)
class {'tomcat':
  install_from_source => false,           # Do NOT install from source, we'll use package manager
  catalina_home       => $catalina_home,
  manage_user         => false,           # Don't let Tomcat module manage which user/group to start with, package does this already
  manage_group        => false,
  require             => Class['dspace'], # Require DSpace was initialized, so that Java is installed
}

->

# Create a new Tomcat instance & install from package manager
tomcat::instance { 'default':
  package_name    => $tomcat_package,  # Name of the tomcat package to install
  package_ensure  => installed,        # Ensure package is installed
}

->

# Override the default Tomcat <Host name='localhost'> entry
# and point it at the DSpace webapps directory (so that it loads all DSpace webapps)
tomcat::config::server::host { 'localhost':
  app_base              => '/home/vagrant/dspace/webapps', # Tell Tomcat to load webapps from this directory
  host_ensure           => present,
  catalina_base         => $catalina_base,                 # Tomcat install this pertains to
  additional_attributes => {                               # Additional Tomcat <Host> attributes
    'autoDeploy' => 'true',
    'unpackWARs' => 'true',
                           },
  notify                => Service['tomcat'],              # If changes are made, notify Tomcat to restart
}

->

# Temporarily stop Tomcat, so that we can modify which user it runs as
# (We cannot tweak the Tomcat run-as user while it is running)
exec { 'Stop default Tomcat temporarily':
  command => "service ${tomcat_service} stop",
}

->

# Modify the Tomcat "defaults" file to make Tomcat run as the 'vagrant' user
# NOTE: This seems to be the ONLY way to do this in Ubuntu, which is disappointing
file_line { 'Update Tomcat to run as vagrant user':
  path   => "/etc/default/${tomcat_service}", # File to modify
  line   => "TOMCAT7_USER=vagrant",           # Line to add to file
  match  => "^TOMCAT7_USER=.*$",              # Regex for line to replace (if found)
  notify => Service['tomcat'],                # If changes are made, notify Tomcat to restart
}

->

# Modify the Tomcat "defaults" file to set custom JAVA_OPTS based on the "catalina_opts"
# config in hiera. Again, seems to be the only way to easily do this in Ubuntu.
file_line { 'Update Tomcat run options':
  path   => "/etc/default/${tomcat_service}", # File to modify
  line   => "JAVA_OPTS=\"${catalina_opts}\"", # Line to add to file
  match  => "^JAVA_OPTS=.*$",                 # Regex for line to replace (if found)
  notify => Service['tomcat'],                # If changes are made, notify Tomcat to restart
}

->

# In order for Tomcat to function properly, the entire CATALINA_BASE directory
# and all subdirectories need to be owned by 'vagrant'
file { $catalina_base:
  ensure  => directory,
  owner   => vagrant,   # Change owner to 'vagrant'
  recurse => true,      # Also change owner of subdirectories/files
  links   => follow,    # Follow any links to and change ownership there too
}

->

# This service is auto-created by package manager when installing Tomcat
# But, we just want to make sure it is running & starts on boot
service {'tomcat':
  name   => $tomcat_service,
  enable => 'true',
  ensure => 'running',
}

#---------------------
# Install DSpace
#---------------------
# Lookup DSpace installation settings from Hiera
# These settings should all be specified in default.yaml
$git_repo          = hiera('git_repo')
$git_branch        = hiera('git_branch')
$ant_installer_dir = hiera('ant_installer_dir', '/home/vagrant/dspace-src/dspace/target/dspace-installer')  # Default value, if unspecified in hiera
$mvn_params        = hiera('mvn_params')
$admin_firstname   = hiera('admin_firstname')
$admin_lastname    = hiera('admin_lastname')
$admin_email       = hiera('admin_email')
$admin_passwd      = hiera('admin_passwd')
$admin_language    = hiera('admin_language')

# Check which Git Repo URL to use (SSH vs HTTPS)
# If the configured Git Repo is HTTPS, just use that. The user must want it that way.
# If the configured Git Repo is SSH, check the "git_ssh_status" Fact to see if our SSH connection
# to GitHub is working (=1). If it is not working (!=1), transform it to the HTTPS repo URL.
$final_git_repo = inline_template('<%= @git_repo.include?("https") ? @git_repo : @github_ssh_status.to_i==1 ? @git_repo : @git_repo.split(":")[1].prepend("https://github.com/") %>')

# Notify which GitHub repo we are using
notify { "GitHub Repo": 
  message => "Using DSpace GitHub Repo at ${final_git_repo}"
}

# Kickoff a DSpace installation for the 'vagrant' default user,
# using the specified GitHub repository & branch.
dspace::install { 'vagrant-dspace':
  owner             => vagrant,                          # DSpace should be owned by the default vagrant user
  version           => '6.0-SNAPSHOT',
  git_repo          => $final_git_repo,
  git_branch        => $git_branch,
  mvn_params        => $mvn_params,
  ant_installer_dir => $ant_installer_dir,
  admin_firstname   => $admin_firstname,
  admin_lastname    => $admin_lastname,
  admin_email       => $admin_email,
  admin_passwd      => $admin_passwd,
  admin_language    => $admin_language,
  require           => Postgresql::Server::Db['dspace'], # Require that PostgreSQL is setup
  notify            => Service['tomcat'],
}

# For convenience in troubleshooting Tomcat, let's install Psi-probe
# http://psi-probe.googlecode.com/
$probe_version = "2.3.3"
exec {"Download and install the Psi-probe v${probe_version} war":
  command   => "wget http://psi-probe.googlecode.com/files/probe-${probe_version}.zip && unzip probe-${probe_version}.zip && rm probe-${probe_version}.zip",
  cwd       => "${catalina_base}/webapps",
  creates   => "${catalina_base}/webapps/probe.war",
  user      => "vagrant",
  logoutput => true,
}

->

# add a context fragment file for Psi-probe, and restart tomcat
file { "${catalina_base}/conf/Catalina/localhost/probe.xml" :
  ensure  => file,
  owner   => vagrant,
  group   => vagrant,
  content => template("dspace/probe.xml.erb"),
  notify  => Service['tomcat'],
}

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
# via hiera in 'default.yaml' or your 'local.yaml'. Just specify the parameter like
# "dspace::[param-name] : [param-value]" in local.yaml.
class { 'dspace':
  java_version       => '8',
  postgresql_version => '9.5',
  tomcat_package     => 'tomcat7',
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

#----------------------------------------------------
# Determine the DSpace Git Repo to use (SSH vs HTTPS)
#----------------------------------------------------
# If the configured Git Repo is HTTPS, just use that. The user must want it that way.
# If the configured Git Repo is SSH, check the "git_ssh_status" Fact to see if our SSH connection
# to GitHub is working (=1). This "git_ssh_status" Fact is created in our Vagrantfile.
# If SSH is not working (!=1), transform it to the HTTPS repo URL.
$git_repo = $dspace::git_repo
$final_git_repo = inline_template('<%= @git_repo.include?("https") ? @git_repo : @github_ssh_status.to_i==1 ? @git_repo : @git_repo.split(":")[1].prepend("https://github.com/") %>')

# Notify which GitHub repo we are using
notify { "GitHub Repo":
  message => "Using DSpace GitHub Repo at ${final_git_repo}",
  before  => Dspace::Install["/home/${dspace::owner}/dspace"],
}

#---------------------------------------------------
# Install DSpace in the owner's ~/dspace/ directory
#---------------------------------------------------
dspace::install { "/home/${dspace::owner}/dspace" :
  git_repo => $final_git_repo,
  require => DSpace::Postgresql_db[$dspace::db_name], # Must first have a database
  notify  => Service['tomcat'],                       # Tell Tomcat to reboot after install
}

#---------------------
# Install PSI Probe
#---------------------
# For convenience in troubleshooting Tomcat, let's install Psi-probe
# http://psi-probe.googlecode.com/
$probe_version = "2.4.0.SP1"
exec {"Download and install the PSI Probe v${probe_version} war":
  command   => "wget --quiet --continue https://github.com/psi-probe/psi-probe/releases/download/${probe_version}/probe.war",
  cwd       => "${dspace::catalina_base}/webapps",
  creates   => "${dspace::catalina_base}/webapps/probe.war",
  user      => "vagrant",
  logoutput => true,
  tries     => 3,                            # In case of a network hiccup, try this download 3 times
  require   => File[$dspace::catalina_base], # CATALINA_BASE must exist before downloading
}

->

# Add a context fragment file for Psi-probe, and restart tomcat
file { "${dspace::catalina_base}/conf/Catalina/localhost/probe.xml" :
  ensure  => file,
  owner   => vagrant,
  group   => vagrant,
  content => template("dspace/probe.xml.erb"),
  notify  => Service['tomcat'],
}
->

# Add a "dspace" Tomcat User (password="dspace") who can login to PSI Probe
# (NOTE: This line will only be added after <tomcat-users> if it doesn't already exist there)
file_line { 'Add \'dspace\' Tomcat user for PSI Probe':
  path    => "${dspace::catalina_base}/conf/tomcat-users.xml", # File to modify
  after   => '<tomcat-users>',                         # Add content immediately after this line
  line    => '<role rolename="manager"/><user username="dspace" password="dspace" roles="manager"/>', # Lines to add to file
  notify  => Service['tomcat'],                        # If changes are made, notify Tomcat to restart
}


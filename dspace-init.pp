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

#-----------------
# dspace_prereqs
# Class which initializes the server with the base DSpace prerequisites
#-----------------
class dspace_prereqs($java_version = "7")
{
  # If the global fact "java_version" doesn't exist, default to value passed in
  # NOTE: $jdk_version should end up being set to just "7" (default) or "6"
  if $::java_version == undef {
    $jdk_version = $java_version
  }
  else { # Otherwise, use the value of the "java_version" global fact
    $jdk_version = $::java_version
  }

  # Install Java, based on set $java_version (passed to Puppet in VagrantFile)
  package { "java":
    name => "openjdk-${jdk_version}-jdk",  # Install OpenJDK package (as Oracle JDK tends to require a more complex manual download & unzip)
  }

  # Set Java defaults to point at our Java package
  # NOTE: $architecture is a "fact" automatically set by Puppet's 'facter'.
  exec { "Update alternatives to Java ${jdk_version}":
    command => "update-java-alternatives --set java-1.${jdk_version}.0-openjdk-${architecture}",
    unless => "test \$(readlink /etc/alternatives/java) = '/usr/lib/jvm/java-${jdk_version}-openjdk-${architecture}/jre/bin/java'",
    require => [Package["java"], Package["maven"]],   # Run *after* Maven is installed, since Maven install sometimes changes the java alternative!
    path => "/usr/bin:/usr/sbin:/bin",
  }

  # Install Maven & Ant
  package { "maven": 
    require => Package["java"],
  }
  package { "ant":
    require => Package["java"],
  }
}

#------------
# dspace_src
# Class to obtain DSpace Source Code from Git
#------------
class dspace_src
{  
  # Install Git
  package { "git":
  }

  # Check if our SSH connection to GitHub works. This verifies that SSH forwarding is working right.
  exec { "Verify SSH connection to GitHub works?" :
    command => "ssh -T -oStrictHostKeyChecking=no git@github.com",
    returns => 1,   # If this succeeds, it actually returns '1'. If it fails, it returns '255'
  }

  # Clone DSpace GitHub to ~/dspace-src
  exec { "git clone git@github.com:DSpace/DSpace.git /home/vagrant/dspace-src": 
    require => [Package["git"], Exec["Verify SSH connection to GitHub works?"]],
    logoutput => true,
  }
}

# actually run the classes
include dspace_prereqs
include dspace_src
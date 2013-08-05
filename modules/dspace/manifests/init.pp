# Class: dspace
#
# This class does the following:
# - installs pre-requisites for DSpace (Java, Maven, Ant, Tomcat)
#
# Tested on:
# - Ubuntu 12.04
#
# Parameters:
# - $java => version of Java (6 or 7)
#
# Sample Usage:
# include dspace
#
class dspace ($java_version = "7")
{
    # Default to requiring all packages be installed
    Package {
        ensure => installed,
    }

    # Install Java, based on set $java_version (passed to Puppet in VagrantFile)
    package { "java":
        name => "openjdk-${java_version}-jdk",  # Install OpenJDK package (as Oracle JDK tends to require a more complex manual download & unzip)
    }

    # Set Java defaults to point at our Java package
    # NOTE: $architecture is a "fact" automatically set by Puppet's 'facter'.
    exec { "Update alternatives to Java ${jdk_version}":
        command => "update-java-alternatives --set java-1.${java_version}.0-openjdk-${architecture}",
        unless  => "test \$(readlink /etc/alternatives/java) = '/usr/lib/jvm/java-${java_version}-openjdk-${architecture}/jre/bin/java'",
        require => [Package["java"], Package["maven"]],   # Run *after* Maven is installed, since Maven install sometimes changes the java alternative!
        path    => "/usr/bin:/usr/sbin:/bin",
    }

    # Install Maven & Ant
    package { "maven": 
        require => Package["java"],
    }
    package { "ant":
        require => Package["java"],
    }
    
    # Install Git
    package { "git":
    }

    # Check if our SSH connection to GitHub works. This verifies that SSH forwarding is working right.
    exec { "Verify SSH connection to GitHub works?" :
        command => "ssh -T -oStrictHostKeyChecking=no git@github.com",
        returns => 1,   # If this succeeds, it actually returns '1'. If it fails, it returns '255'
    }
}
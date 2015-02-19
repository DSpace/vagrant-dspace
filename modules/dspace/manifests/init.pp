# Class: dspace
#
# This class does the following:
# - installs pre-requisites for DSpace (Java, Maven, Ant, Tomcat)
#
# Tested on:
# - Ubuntu 12.04
# - Ubuntu 14.04
#
# Parameters:
# - $java => version of Java (6 or 7)
#
# Sample Usage:
# include dspace
#
class dspace($java_version = "7")
{
    # Default to requiring all packages be installed
    Package {
      ensure => installed,
    }

    # Install Maven & Ant which are required to build & deploy, respectively
    # For Maven, do NOT install "recommended" apt-get packages, as this will
    # install OpenJDK 6 and always set it as the default Java alternative
    package { 'maven':
      install_options => ['--no-install-recommends'],
      before          => Package['java'],
    }
    package { "ant":
      before => Package['java'],
    }

    # Install Git, needed for any DSpace development
    package { "git":
    }

    # Java installation directory
    $java_install_dir = "/usr/lib/jvm"

    # OpenJDK version/directory name (NOTE: $architecture is a "fact")
    $java_name = "java-${java_version}-openjdk-${architecture}"

    # Install Java, based on set $java_version (passed to Puppet in VagrantFile)
    package { "java":
      name => "openjdk-${java_version}-jdk",  # Install OpenJDK package (as Oracle JDK tends to require a more complex manual download & unzip)
    }

 ->

    # Set Java defaults to point at OpenJDK
    # NOTE: $architecture is a "fact" automatically set by Puppet's 'facter'.
    exec { "Update alternatives to OpenJDK Java ${java_version}":
      command => "update-java-alternatives --set ${java_name}",
      unless  => "test \$(readlink /etc/alternatives/java) = '${java_install_dir}/${java_name}/jre/bin/java'",
      path    => "/usr/bin:/usr/sbin:/bin",
    }
 
 ->

    # Create a "default-java" symlink (for easier JAVA_HOME setting). Overwrite if existing.
    exec { "Symlink OpenJDK to '${java_install_dir}/default-java'":
      cwd     => $install_dir,
      command => "ln -sfn ${java_name} default-java",
      unless  => "test \$(readlink ${java_install_dir}/default-java) = '${java_name}'",
      path    => "/usr/bin:/usr/sbin:/bin",
    }
}

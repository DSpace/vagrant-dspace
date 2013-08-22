# Definition: dspace::install
#
# Each time this is called, the following happens:
#  - DSpace source is pulled down from GitHub
#  - DSpace Maven build process is run (if it has not yet been run)
#  - DSpace Ant installation process is run (if it has not yet been run)
#
# Tested on:
# - Ubuntu 12.04
#
# Sample Usage:
#
# dspace::install {
#    owner => "vagrant"
# }
#
define dspace::install ($owner,
                        $group             = $owner,
                        $src_dir           = "/home/${owner}/dspace-src", 
                        $install_dir       = "/dspace", 
                        $service_owner     = "tomcat", 
                        $service_group     = "adm",
                        $git_repo          = "git@github.com:DSpace/DSpace.git",
                        $git_branch        = "master",
                        $ant_installer_dir = "/home/${owner}/dspace-src/dspace/target/dspace-4.0-SNAPSHOT-build",
                        $ensure            = present)
{


    # ensure that the install_dir exists, and has proper permissions
    file { "${install_dir}":
        ensure => "directory",
        owner  => "${service_owner}",
        group  => "${service_group}",
        mode   => 1770,
    }

->

    # Ensure a custom ~/.profile exists (with JAVA_HOME & MAVEN_HOME defined)
    file { "/home/${owner}/.profile" :
        ensure  => file,
        owner   => vagrant,
        group   => vagrant,
        content => template("dspace/profile.erb"),
    }
 
->
   
    # Clone DSpace GitHub to ~/dspace-src
    exec { "git clone ${git_repo} ${src_dir}":
        command   => "git clone ${git_repo} ${src_dir}; chown -R ${owner}:${group} ${src_dir}",
        creates   => $src_dir,
        logoutput => true,
        require   => [Package["git"], Exec["Verify SSH connection to GitHub works?"]],
    }

->

    # Checkout the specified branch
    exec { "Checkout branch ${git_branch}" :
       command => "git checkout ${git_branch}",
       cwd     => $src_dir, # run command from this directory
       user    => $owner,
       # Only perform this checkout if the branch EXISTS and it is NOT currently checked out (if checked out it will have '*' next to it in the branch listing)
       onlyif  => "git branch -a | grep -w '${git_branch}' && git branch | grep '^\\*' | grep -v '^\\* ${git_branch}\$'",
    }

->

   # Create a 'vagrant.properties' file which will be used to build the DSpace installer
   # (INSTEAD OF the default 'build.properties' file that DSpace normally uses)
   file { "${src_dir}/vagrant.properties":
     ensure => file,
     owner => $owner,
     group => $group,
     mode => 0644,
     backup => ".puppet-bak",  # If replaced, backup old settings to .puppet-bak
     content => template("dspace/vagrant.properties.erb"),
   }

->

   # Build DSpace installer (This actually just pulls down dependencies via Maven. Nothing is compiled.)
   # (The '-Denv=vagrant' tells Maven to use the vagrant.properties file, which we created above)
   exec { "Build DSpace installer in ${src_dir}":
     command => "mvn -Denv=vagrant package ${mvn_params}",
     cwd => "${src_dir}", # Run command from this directory
     user => $owner,
     creates => $ant_installer_dir, # Only run if Maven target directory doesn't already exist
     timeout => 0, # Disable timeout. This build takes a while!
     logoutput => true,	# Send stdout to puppet log file (if any)
     require => File["${src_dir}/vagrant.properties"], # Since this Maven command refers to the vagrant.properties file, we need to ensure that file is there before we run this step
   }

->

   # Install DSpace (via Ant)
   exec { "Install DSpace to ${dir}":
     command => "ant fresh_install",
     cwd => $ant_installer_dir,	# Run command from this directory
     user => $owner,
     creates => "${install_dir}/webapps/xmlui",	# Only run if XMLUI webapp doesn't yet exist (NOTE: we check for a webapp's existence since this is the *last step* of the install process)
     logoutput => true,	# Send stdout to puppet log file (if any)
     require => Exec["Build DSpace installer in ${src_dir}"]
    # require => File["$ant_installer_dir"], #don't run this step if the Ant Installer Dir doesn't yet exist, wait for it
   } 

->

   # Configure Tomcat via Context Fragments
   file { "/srv/tomcat/dspace/conf/xmlui.xml":
     ensure => file,
     owner => $service_owner,
     group => $service_group,
     mode => 0664,
     backup => ".puppet-bak",  # If replaced, backup old settings to .puppet-bak
     content => template("dspace/xmlui.xml.erb"),
   }
   file { "/srv/tomcat/dspace/conf/jspui.xml":
     ensure => file,
     owner => $service_owner,
     group => $service_group,
     mode => 0664,
     backup => ".puppet-bak",  # If replaced, backup old settings to .puppet-bak
     content => template("dspace/jspui.xml.erb"),
   }
   file { "/srv/tomcat/dspace/conf/solr.xml":
     ensure => file,
     owner => $service_owner,
     group => $service_group,
     mode => 0664,
     backup => ".puppet-bak",  # If replaced, backup old settings to .puppet-bak
     content => template("dspace/solr.xml.erb"),
   }
   file { "/srv/tomcat/dspace/conf/oai.xml":
     ensure => file,
     owner => $service_owner,
     group => $service_group,
     mode => 0664,
     backup => ".puppet-bak",  # If replaced, backup old settings to .puppet-bak
     content => template("dspace/oai.xml.erb"),
   }
   file { "/srv/tomcat/dspace/conf/sword.xml":
     ensure => file,
     owner => $service_owner,
     group => $service_group,
     mode => 0664,
     backup => ".puppet-bak",  # If replaced, backup old settings to .puppet-bak
     content => template("dspace/sword.xml.erb"),
   }
   file { "/srv/tomcat/dspace/conf/swordv2.xml":
     ensure => file,
     owner => $service_owner,
     group => $service_group,
     mode => 0664,
     backup => ".puppet-bak",  # If replaced, backup old settings to .puppet-bak
     content => template("dspace/swordv2.xml.erb"),
   }








}

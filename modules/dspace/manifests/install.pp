# Definition: dspace::install
#
# Each time this is called, the following happens:
#  - DSpace source is pulled down from GitHub
#  - TODO: actually install DSpace
#
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
                        $group    = $owner,
                        $src_dir  = "/home/${owner}/dspace-src", 
                        $git_repo = "git@github.com:DSpace/DSpace.git",
                        $ensure   = present)
{
    # Ensure a custom ~/.profile exists (with JAVA_HOME & MAVEN_HOME defined)
    file { "/home/${owner}/.profile" :
        ensure  => file,
        owner   => vagrant,
        group   => vagrant,
        content => template("dspace/profile.erb"),
    }
    
    # Clone DSpace GitHub to ~/dspace-src
    exec { "git clone ${git_repo} ${src_dir}":
        command => "git clone ${git_repo} ${src_dir}; chown -R ${owner}:${group} ${src_dir}",
        creates => $src_dir,
        logoutput => true,
        require => [Package["git"], Exec["Verify SSH connection to GitHub works?"]],
    }
}
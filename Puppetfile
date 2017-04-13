# Configuration for librarian-puppet (http://librarian-puppet.com/)
# This installs necessary third-party Puppet Modules for us.

# Default forge to download modules from
forge "https://forgeapi.puppetlabs.com"

# Install PuppetLabs Standard Libraries (includes various useful puppet methods)
# See: https://github.com/puppetlabs/puppetlabs-stdlib
mod "puppetlabs-stdlib", "4.16.0"

# Install Puppet Labs PostgreSQL module
# https://github.com/puppetlabs/puppetlabs-postgresql/
mod "puppetlabs-postgresql", "4.8.0"

# Install Puppet Labs Tomcat module
# https://github.com/puppetlabs/puppetlabs-tomcat/
mod "puppetlabs-tomcat", "1.5.0"

# Custom Module to install DSpace
mod "DSpace/dspace",
   :git => "https://github.com/DSpace/puppet-dspace.git"

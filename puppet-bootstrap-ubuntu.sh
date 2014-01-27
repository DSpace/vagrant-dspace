#!/usr/bin/env bash
#
# This bootstraps Puppet & Librarian-Puppet on Ubuntu 12.04 LTS.
# Based on the script at: https://github.com/hashicorp/puppet-bootstrap/
# 
# However, we've updated it to also install and configure librarian-puppet
# https://github.com/rodjek/librarian-puppet  
# We use librarian-puppet to auto-install 3rd party Puppet modules.
#
set -e

# Puppet directory (this is where we want Puppet to be installed & all its main modules)
PUPPET_DIR=/etc/puppet/

# Load up the release information
. /etc/lsb-release

REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"

#--------------------------------------------------------------------
# NO TUNABLES BELOW THIS POINT
#--------------------------------------------------------------------
if [ "$EUID" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# Do the initial apt-get update
echo "Ensure apt-get update has been run..."
apt-get update >/dev/null

# Install wget if we have to (some older Ubuntu versions)
echo "Installing wget..."
apt-get install -y wget >/dev/null

# Install the PuppetLabs repo
echo "Configuring PuppetLabs repo..."
repo_deb_path=$(mktemp)
wget --output-document=${repo_deb_path} ${REPO_DEB_URL} 2>/dev/null
dpkg -i ${repo_deb_path} >/dev/null
apt-get update >/dev/null

# Install Puppet
echo "Installing Puppet..."
apt-get install -y puppet >/dev/null
echo "Puppet installed!"

# Install our custom Puppet config file
cp /vagrant/puppet.conf $PUPPET_DIR

### Start librarian-puppet installation & initialization

# Install Git
echo "Installing Git..."
apt-get install -y git >/dev/null
echo "Git installed!"

# Ensure Puppet directory exists & the 'librarian-puppet' "Puppetfile" is copied there.
if [ ! -d "$PUPPET_DIR" ]; then
  mkdir -p $PUPPET_DIR
fi
# Install our custom librarian-puppet config file
cp /vagrant/Puppetfile $PUPPET_DIR

# Install 'librarian-puppet-maestrodev' (https://github.com/maestrodev/librarian-puppet), 
# which is an improved version of 'librarian-puppet'
if [ "$(gem search -i librarian-puppet-maestrodev)" = "false" ]; then
  echo "Installing librarian-puppet..."
  gem install librarian-puppet-maestrodev --include-dependencies --no-rdoc --no-ri >/dev/null
  echo "librarian-puppet installed!"
  echo "Installing third-party Puppet modules (via librarian-puppet)..."
  cd $PUPPET_DIR && librarian-puppet install --clean
else
  echo "Updating third-party Puppet modules (via librarian-puppet)..."
  cd $PUPPET_DIR && librarian-puppet update
fi


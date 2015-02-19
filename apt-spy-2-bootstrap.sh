#!/bin/sh
# apt-spy-2-bootstrap.sh
# Uses the Ruby gem apt-spy2 to ensure the apt sources.list file is configured appropriately for this location, and that it selects mirrors that are currently functional

# Load up the release information
. /etc/lsb-release

# Do the initial apt-get update
echo "Initial apt-get update..."
apt-get update >/dev/null

echo "Installing 'apt-spy2'. This tool lets us autoconfigure your 'apt' sources.list to a nearby location."
echo "  This may take a while..."

# Ensure dependencies are installed (These are needed to dynamically determine your country code).
# * ruby >= 1.9.2 is needed for apt-spy2
# * zlib1g-dev (zlib) is needed to build apt-spy2 from "native extensions" (needed to install "nokogiri" prerequisite)
# * dnsutils ensures 'dig' is installed (to get IP address)
# * geoip-bin ensures 'geoiplookup' is installed (lets us look up country code via IP)
apt-get install -y ruby1.9.3 zlib1g-dev dnsutils geoip-bin >/dev/null

# Install/Update RubyGems for the provider
echo "Installing RubyGems..."
if [ $DISTRIB_CODENAME != "trusty" ]; then
  apt-get install -y rubygems >/dev/null
fi
gem install --no-ri --no-rdoc rubygems-update
update_rubygems >/dev/null

# Figure out the two-letter country code for the current locale, based on IP address
# First, let's get our public IP address via OpenDNS (e.g. http://unix.stackexchange.com/a/81699)
export CURRENTIP=`dig +short myip.opendns.com @resolver1.opendns.com`

# Next, let's lookup our country code via IP address
export COUNTRY=`geoiplookup $CURRENTIP | awk -F: '{ print $2 }' | awk -F, '{ print $1}' | tr -d "[:space:]"`

#If country code is empty or != 2 characters, then use "US" as a default
if [ -z "$COUNTRY" ] || [ "${#COUNTRY}" -ne "2" ]; then
   COUNTRY = "US"
fi

if [ "$(gem search -i apt-spy2)" = "false" ]; then
  gem install --no-ri --no-rdoc apt-spy2
  echo "... apt-spy2 installed!"
  echo "... Setting 'apt' sources.list for closest mirror to country=$COUNTRY"
  apt-spy2 fix --launchpad --commit --country=$COUNTRY
else
  echo "... Setting 'apt' sources.list for closest mirror to country=$COUNTRY"
  apt-spy2 fix --launchpad --commit --country=$COUNTRY
fi

# apt-spy2 requires running an 'apt-get update' after doing a 'fix'
echo "Re-running apt-get update after sources updated..."
apt-get update >/dev/null
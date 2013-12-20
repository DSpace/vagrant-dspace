#!/bin/sh

# apt-spy-2-bootstrap.sh
# Uses the Ruby gem apt-spy2 to ensure the apt sources.list file is configured appropriately for this location, and that it selects mirrors that are currently functional

# figure out the two-letter country code for the current locale, based on IP address

export CURRENTIP=`curl -s http://ipecho.net/plain`

#TODO verify that you actually have an IP address there, and not some evil text

export COUNTRY=`geoiplookup $CURRENTIP | awk -F:\  '{print $2}' | sed 's/,.*//'`

#TODO verify that country code, and use US if it doesn't look reasonable

if [ "$(gem search -i apt-spy2)" = "false" ]; then
  gem install apt-spy2
  apt-spy2 fix --launchpad --commit --country=$COUNTRY ; true
else
  apt-spy2 fix --launchpad --commit --country=$COUNTRY ; true
fi

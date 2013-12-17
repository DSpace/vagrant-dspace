#!/bin/sh

# apt-spy-2-bootstrap.sh
# Uses the Ruby gem apt-spy2 to ensure the apt sources.list file is configured appropriately for this location, and that it selects mirrors that are currently functional

if [ "$(gem search -i apt-spy2)" = "false" ]; then
  gem install apt-spy2
  apt-spy2 fix
else
  apt-spy2 fix
fi

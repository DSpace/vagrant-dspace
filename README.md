Vagrant + DSpace = vagrant-dspace
=================================

[Vagrant](http://vagrantup.com) can be used to spin up a temporary Virtual Machine (VM) in a variety of providers (VirtualBox, VMWare, AWS, etc).
The Vagrantfile in this folder (along with associated shell scripts) configures a DSpace development environment via Vagrant. 

Advantages for DSpace Development: 
* Using Vagrant would allow someone to spin up an "offline" copy of DSpace on your local machine/laptop for development or demo purposes.
* Vagrant VMs are "throwaway". Can easily destroy and recreate at will for testing purposes (e.g. vagrant destroy; vagrant up)

BIG WARNING: THIS IS STILL A WORK IN PROGRESS. YOUR MILEAGE MAY VARY. NEVER USE THIS IN PRODUCTION.

What Works
----------

* Spins up am Ubuntu VM using Vagrant (VirtualBox backend is only one tested so far.)
* Sync your local Git settings and SSH keys to the VM
* Install some of the basic prerequisites for DSpace Development (namely: Git, Java, Maven)
* Clone DSpace source from GitHub to ~/dspace-src/ (under the default 'vagrant' user account)

What Doesn't Work (Yet)
---------------------------

* Installing/configuring PostgreSQL
* Installing/configuring Tomcat
* Actually compiling/installing/configuring DSpace

I hope that all of these will be coming at some point...but they aren't here yet.

If you want to help, please do. I'd prefer solutions using [Puppet](https://puppetlabs.com/) to setup/install this software, as there are many available Puppet Modules which already claim to help setup Tomcat & PostgreSQL.
Plus, I'm already using Puppet as part of the provisioning of this Vagrant server (see the 'dspace-init.pp' Puppet script in this codebase).

How To Use Vagrant
------------------

1. Install [Vagrant](http://vagrantup.com) (I've only tested with the [VirtualBox](https://www.virtualbox.org/) provider so far)
2. Clone a copy of 'vagrant-dspace' to your local computer
3. `cd [vagrant-dspace]/`
4. `vagrant up`

The `vagrant up` command will initialize a new VM based on the settings in the `Vagrantfile` in that directory.  

In a few short minutes, you'll have a fresh Ubuntu VM that you can SSH into by simply typing `vagrant ssh`. Since SSH Forwarding is enabled,
that Ubuntu VM should have access to your local SSH keys, which allows you to immediately use Git/GitHub.

If you want to destroy the VM at anytime (and start fresh again), just run `vagrant destroy`. No worries, you can always recreate a new VM with another `vagrant up`.

License
-------

This work is licensed under the [DSpace BSD 3-Clause License](http://www.dspace.org/license/), which is just a standard [BSD 3-Clause License](http://opensource.org/licenses/BSD-3-Clause).

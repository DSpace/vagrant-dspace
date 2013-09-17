Vagrant + DSpace = vagrant-dspace
=================================

[Vagrant](http://vagrantup.com) can be used to spin up a temporary Virtual Machine (VM) in a variety of providers (VirtualBox, VMWare, AWS, etc).
The `Vagrantfile` in this folder (along with associated provision scripts) configures a DSpace development environment via Vagrant (and Puppet). 

Some Advantages for DSpace Development: 
* Using Vagrant would allow someone to spin up an "offline" copy of DSpace on your local machine/laptop for development or demo purposes.
* Vagrant VMs are "throwaway". Can easily destroy and recreate at will for testing purposes or as needs arise (e.g. `vagrant destroy; vagrant up`)

This is a collaborative project between [tdonohue](https://github.com/tdonohue/) and [hardyoyo](https://github.com/hardyoyo/).

_BIG WARNING: THIS IS STILL A WORK IN PROGRESS. YOUR MILEAGE MAY VARY. NEVER USE THIS IN PRODUCTION._

How it Works
------------

* Spins up an Ubuntu VM using Vagrant (VirtualBox backend is only one tested so far.)
* Setup SSH Forwarding, so that you can use your SSH key(s) on VM (for GitHub clones/commits)
* Sync your local Git settings (name & email) to VM
* Install some of the basic prerequisites for DSpace Development (namely: Git, Java, Maven)
* Clone DSpace source from GitHub to `~/dspace-src/` (under the default 'vagrant' user account)
* Install/Configure PostgreSQL (Thanks to [hardyoyo](https://github.com/hardyoyo/)!)
   * We install [puppetlabs/postgresql](http://forge.puppetlabs.com/puppetlabs/postgresql) (via [librarian-puppet](http://librarian-puppet.com/)),
     and then use that Puppet module to setup PostgreSQL
* Installs Tomcat (Thanks to [hardyoyo](https://github.com/hardyoyo/)!)
   * We install [tdonohue/puppet-tomcat](https://github.com/tdonohue/puppet-tomcat/) (via [librarian-puppet](http://librarian-puppet.com/)),
     and then use that Puppet module to setup Tomcat
   * WARNING: We are just pulling down the latest "master" code from tdonohue/puppet-tomcat at this time.
* Installs DSpace to `~/dspace/` (under the default 'vagrant' user account). (THANKS to [hardyoyo](https://github.com/hardyoyo/)!)
   * Makes DSpace available via Tomcat (e.g. http://localhost:8080/xmlui/)

**If you want to help, please do.** We'd prefer solutions using [Puppet](https://puppetlabs.com/).

How To Use vagrant-dspace
--------------------------

1. Install [Vagrant](http://vagrantup.com) (Only tested with the [VirtualBox](https://www.virtualbox.org/) provider so far)
2. Clone a copy of 'vagrant-dspace' to your local computer
3. _WINDOWS ONLY_ : Any users of Vagrant from Windows MUST create a GitHub-specific SSH Key (at `~/.ssh/github_rsa`) which is then connected to your GitHub Account. There are two easy ways to do this:
   * Install [GitHub for Windows](http://windows.github.com/) - this will automatically generate a new `~/.ssh/github_rsa` key.
   * OR, manually generate a new `~/.ssh/github_rsa` key and associate it with your GitHub Account. [GitHub has detailed instructions on how to do this.](https://help.github.com/articles/generating-ssh-keys)
   * SIDENOTE: Mac OSX / Linux users do NOT need this, as Vagrant's SSH Key Forwarding works properly from Mac OSX & Linux. There's just a bug in using Vagrant + Windows.
4. `cd [vagrant-dspace]/`
5. `vagrant up`
   * Wait for ~15 minutes while Vagrant & Puppet do all the heavy lifting of cloning GitHub & building & installing DSpace.
6. Once complete, visit `http://localhost:8080/xmlui/` or `http://localhost:8080/jspui/` to see if it worked! _More info below on what to expect._
   * If for you already had something running on port 8080, Vagrant will attempt to use an open port between 2200 and 2250
   
The `vagrant up` command will initialize a new VM based on the settings in the `Vagrantfile` in that directory.  

In a few minutes, you'll have a fresh Ubuntu VM that you can SSH into by simply typing `vagrant ssh`. Since SSH Forwarding is enabled,
that Ubuntu VM should have access to your local SSH keys, which allows you to immediately use Git/GitHub.

What will you get?
------------------

* A running instance of DSpace 'master', on top of latest PostgreSQL and Tomcat 7 (and using Java OpenJDK 7 by default)
   * You can visit this instance at `http://localhost:8080/xmlui/` or `http://localhost:8080/jspui/`. 
   * If you install and configure the [Landrush plugin](https://github.com/phinze/landrush) for Vagrant, you can instead visit http://dspace.vagrant.dev:8080/xmlui/ or http://dspace.vagrant.dev:8080/jspui/
* A fresh Ubuntu virtual server with DSpace GitHub cloned (at `~/dspace-src`) and Java/Maven/Ant/Git installed.
* All "out of the box" DSpace webapps running out of `~/dspace/webapps/`. The full DSpace installation is at `~/dspace/`.
* Tomcat 7 instance installed at `~/tomcat/`
    * Includes [PSI Probe](http://code.google.com/p/psi-probe/) running at `http://localhost:8080/probe/`
* Enough to get you started with developing/building/using DSpace (or debug issues with the DSpace build process, if any pop up)
* A very handy playground for testing multiple-machine configurations of DSpace, and software that might utilize DSpace as a service

It is up to you to [continue the setup](https://wiki.duraspace.org/display/DSDOC3x/Installation#Installation-InstallationInstructions). 
The base install creates an administrator for you. The email is `dspacedemo+admin@gmail.com` and the password is the name of this handy tool you're trying to use, all lower case. 
But, your first step after typing `vagrant ssh` should still probably be to create an administrator:

    ~dspace/bin/dspace create-administrator

It is also worth noting that you can tweak the default [`Vagrantfile`](https://github.com/tdonohue/vagrant-dspace/blob/master/Vagrantfile) to better match your own development environment. 
There's even a few quick settings there to get you started.

If you want to destroy the VM at anytime (and start fresh again), just run `vagrant destroy`. 
No worries, you can always recreate a new VM with another `vagrant up`.

As you develop with vagrant-dspace, from time to time you may want to run a `vagrant destroy` cycle (followed by a fresh `vagrant up`), just to confirm that the Vagrant setup is still doing exactly what you want it to do. 
This cleans out any old experiments and starts fresh with a new base image. If you're just using vagrant-dspace for dspace development, this isn't advice for you. 
But, if you're working on contributing back to vagrant-dspace, do try this from time to time, just to sanity-check your Vagrant and Puppet scripts.

Vagrant Plugin Recommendations
------------------------------

The following Vagrant plugins are not required, but they do make using Vagrant and vagrant-dspace more enjoyable.

* Land Rush: https://github.com/phinze/landrush
* Vagrant-Cachier: https://github.com/fgrehm/vagrant-cachier
* Vagrant-Proxyconf: http://vagrantplugins.com/plugins/vagrant-proxyconf/
* Vagrant-VBox-Snapshot: http://vagrantplugins.com/plugins/vagrant-vbox-snapshot/

What's Next?
------------

Here are a few things we'd like to explore in future version of vagrant-dspace:

* use a CentOS base machine, and make all Puppet provisioning modules compatible with a Yum-based package manager. The current vagrant-dspace project relies on a package only available on Debian-based systems. We'd really like to avoid that dependency in the future.
* Oracle database version (Hardy is busy working on this already, [contact him](https://github.com/hardyoyo/) if you'd like to help).
* [Multi-machine](http://docs.vagrantup.com/v2/multi-machine/index.html) configuration, to demonstrate proper configuration of multi-machine installations of DSpace. One possibility would be to set up a seperate Elastic Search or Solr box, and send usage statistics to that external box. Another possibility would be to explore using an alternate UI based on the REST-API. We recommend that you use the Land Rush Vagrant plugin if you're serrious about exploring a multi-machine Vagrant setup.

License
--------

This work is licensed under the [DSpace BSD 3-Clause License](http://www.dspace.org/license/), which is just a standard [BSD 3-Clause License](http://opensource.org/licenses/BSD-3-Clause).

Vagrant + DSpace = vagrant-dspace
=================================

[Vagrant](http://vagrantup.com) can be used to spin up a temporary Virtual Machine (VM) in a variety of providers ([VirtualBox](http://www.virtualbox.org), [VMWare](http://www.vmware.com/), [Amazon AWS](http://aws.amazon.com/), etc).

Simply put, 'vagrant-dspace' uses Vagrant and [Puppet](http://puppetlabs.com/) to auto-install latest DSpace on the VM provider of your choice (though so far we've mostly tested with VirtualBox).

Some example use cases for 'vagrant-dspace':
* Lets you easily install the latest version of DSpace on a Virtual Machine in order to try it out or test upgrades, etc.
* Lets you easily setup an offline/local copy of DSpace for demos at conferences or similar.
* Lets you quickly setup a DSpace development environment on a Virtual Machine. You'd need to install your IDE of choice, but besides that, everything else is installed for you.
* Vagrant VMs are "throwaway". Can easily destroy the VM and recreate at will for testing purposes or as needs arise (e.g. `vagrant destroy; vagrant up`)

This work began as a collaborative project between [tdonohue](https://github.com/tdonohue/) and [hardyoyo](https://github.com/hardyoyo/), 
but has now been more broadly accepted.

_BIG WARNING: THIS IS STILL A WORK IN PROGRESS. YOUR MILEAGE MAY VARY. NEVER USE THIS IN PRODUCTION._

How it Works
------------

'vagrant-dspace' does all of the following for you:

* Spins up an Ubuntu 12.04 VM using Vagrant
* Installs some of the basic prerequisites for DSpace Development (namely: Git, Java, Maven)
* Clones DSpace source from GitHub to `~/dspace-src/` (under the default 'vagrant' user account)
* Installs/Configures PostgreSQL
   * We install [puppetlabs/postgresql](http://forge.puppetlabs.com/puppetlabs/postgresql) (via [librarian-puppet](http://librarian-puppet.com/)),
     and then use that Puppet module to setup PostgreSQL
* Installs Tomcat to `~/tomcat/` (under the default 'vagrant' user account)
   * We install [tdonohue/puppet-tomcat](https://github.com/tdonohue/puppet-tomcat/) (via [librarian-puppet](http://librarian-puppet.com/)),
     and then use that Puppet module to setup Tomcat
   * WARNING: We are just pulling down the latest "master" code from tdonohue/puppet-tomcat at this time.
* Installs DSpace to `~/dspace/` (under the default 'vagrant' user account).
   * Makes DSpace available via Tomcat (e.g. http://localhost:8080/xmlui/)
* Sets up SSH Forwarding, so that you can use your local SSH key(s) on the VM (for development with GitHub)
* Syncs your local Git settings (name and email from local .gitconfig) to VM (for development with GitHub)

**If you want to help, please do.** We'd prefer solutions using [Puppet](https://puppetlabs.com/).

Requirements
------------

* [Vagrant](http://vagrantup.com/) version 1.3.2 or higher
* [VirtualBox](https://www.virtualbox.org/)
* A GitHub account with an associated SSH key:  As vagrant-dspace was built initially as a developer tool, at this time one must have a GitHub account (and an associated SSH key) in order for 'vagrant-dspace' to be able to download DSpace source from GitHub. Please note, we are working on removing this requirement in the future.

How To Use vagrant-dspace
--------------------------

1. Install [Vagrant](http://vagrantup.com) (Only tested with the [VirtualBox](https://www.virtualbox.org/) provider so far)
2. Clone a copy of 'vagrant-dspace' to your local computer
   * `git clone git@github.com:DSpace/vagrant-dspace.git`
3. _WINDOWS ONLY_ : Any users of Vagrant from Windows MUST create a GitHub-specific SSH Key (at `~/.ssh/github_rsa`) which is then connected to your GitHub Account. There are two easy ways to do this:
   * Install [GitHub for Windows](http://windows.github.com/) - this will automatically generate a new `~/.ssh/github_rsa` key.
   * OR, manually generate a new `~/.ssh/github_rsa` key and associate it with your GitHub Account. [GitHub has detailed instructions on how to do this.](https://help.github.com/articles/generating-ssh-keys)
   * SIDENOTE: Mac OSX / Linux users do NOT need this, as Vagrant's SSH Key Forwarding works properly from Mac OSX & Linux. There's just a bug in using Vagrant + Windows.
4. `cd [vagrant-dspace]/`
5. `vagrant up`
   * Wait for ~15 minutes while Vagrant & Puppet do all the heavy lifting of cloning GitHub & building & installing DSpace.
   * There may be times that vagrant will appear to "stall" for several minutes (especially during the Maven build of DSpace). But, don't worry.
6. Once complete, visit `http://localhost:8080/xmlui/` or `http://localhost:8080/jspui/` in your local web browser to see if it worked! _More info below on what to expect._
   * If you already have something running locally on port 8080, vagrant-dspace will attempt to use the next available port between 8081 and 8100.
   
The `vagrant up` command will initialize a new VM based on the settings in the `Vagrantfile` in that directory.  

Once complete, you'll have a fresh Ubuntu VM that you can SSH into by simply typing `vagrant ssh`. Since SSH Forwarding is enabled,
that Ubuntu VM should have access to your local SSH keys, which allows you to immediately use Git/GitHub.

What will you get?
------------------

* A running instance of [DSpace 'master'](https://github.com/DSpace/DSpace), on top of latest PostgreSQL and Tomcat 7 (and using Java OpenJDK 7 by default)
   * You can visit this instance at `http://localhost:8080/xmlui/` or `http://localhost:8080/jspui/` from your local web browser 
   * If you install and configure the [Landrush plugin](https://github.com/phinze/landrush) for Vagrant, you can instead visit http://dspace.vagrant.dev:8080/xmlui/ or http://dspace.vagrant.dev:8080/jspui/
   * An initial Administrator account is also auto-created:
       * Login: `dspacedemo+admin@gmail.com` , Pwd: 'vagrant'
* A fresh Ubuntu virtual server with DSpace GitHub cloned (at `~/dspace-src/`) and Java/Maven/Ant/Git installed.
* All "out of the box" DSpace webapps running out of `~/dspace/webapps/`. The full DSpace installation is at `~/dspace/`.
* Tomcat 7 instance installed at `~/tomcat/`
   * Includes [PSI Probe](http://code.google.com/p/psi-probe/) running at `http://localhost:8080/probe/`
       * PSI Probe Login: 'dspace', Pwd: 'vagrant'
* Enough to get you started with developing/building/using DSpace (or debug issues with the DSpace build process, if any pop up)
   * Though you may wish to install your IDE of choice.
* A very handy playground for testing multiple-machine configurations of DSpace, and software that might utilize DSpace as a service

It is up to you to [continue the DSpace setup](https://wiki.duraspace.org/display/DSDOC3x/Installation#Installation-InstallationInstructions), as needed. 
 
Your first step should  be to change the default password(s), and/or optionally create a new administrator:

    vagrant ssh
    ~dspace/bin/dspace create-administrator

It is also worth noting that you may choose to tweak the default [`Vagrantfile`](https://github.com/tdonohue/vagrant-dspace/blob/master/Vagrantfile) to better match your own development environment. 
There's even a few quick settings there to get you started.

If you want to destroy the VM at anytime (and start fresh again), just run `vagrant destroy`. 
No worries, you can always recreate a new VM from scratch with another `vagrant up`.

As you develop with 'vagrant-dspace', from time to time you may want to run a `vagrant destroy` cycle (followed by a fresh `vagrant up`), just to confirm that the Vagrant setup is still doing exactly what you want it to do. 
This cleans out any old experiments and starts fresh with a new base image. If you're just using vagrant-dspace for dspace development, this isn't advice for you. 
But, if you're working on contributing back to vagrant-dspace, do try this from time to time, just to sanity-check your Vagrant and Puppet scripts.

Additional Vagrant Plugin Recommendations
-----------------------------------------

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

Tools we use to make this all work
----------------------------------

* [Vagrant](http://vagrantup.com) (obviously)
* [Puppet](http://puppetlabs.com) - To actually clone, build, configure & install DSpace from GitHub
* [Librarian-Puppet](https://github.com/rodjek/librarian-puppet) - Used to install the external Puppet Modules which setup Tomcat & PostgreSQL

Reporting Bugs / Requesting Enhancements
----------------------------------------

Bugs / Issues or requests for enhancements can be reported via the [DSpace Issue Tracker](https://jira.duraspace.org/browse/DS). _Please select the "vagrant-dspace" component when creating your ticket in the issue tracker._

We also encourage you to submit Pull Requests with any recommended changes/fixes. As it is, the 'vagrant-dspace' project is really just a labor of love, and we can use help in making it better.

License
--------

This work is licensed under the [DSpace BSD 3-Clause License](http://www.dspace.org/license/), which is just a standard [BSD 3-Clause License](http://opensource.org/licenses/BSD-3-Clause).

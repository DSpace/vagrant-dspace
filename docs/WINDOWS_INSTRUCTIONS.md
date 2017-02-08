Vagrant-DSpace Windows Installation Instructions
=================================

Setting up [Vagrant](http://vagrantup.com) on Windows can be a challenge, especially if you are new to using VirtualBox on Windows. This document will provide you with detailed, step-by-step instructions on how to get started using Vagrant-DSpace on Windows.

Table of Contents
-----------------

1. [Step 1: Be sure your computer will allow you to run VirtualBox](#step-1-be-sure-your-computer-will-allow-you-to-run-virtualbox)
2. [Step 2: Install Vagrant and Virtualbox](#step-2-install-vagrant-and-virtualbox)
3. [Step 3: Set up a GitHub account with SSH access](#step-3-set-up-a-github-account-with-ssh-access)
4. [Step 4: Setup PuTTY / Pageant for SSH Forwarding](#step-4-set-putty-pageant-for-ssh-forwarding)
6. [Step 5: Fork Vagrant-DSpace and DSpace to your new GitHub account](#step-5-fork-vagrant-dspace-and-dspace-to-your-new-github-account)
7. [Step 6: Configure a .bashrc file for Git BASH](#step-6-configure-a-bashrc-file-for-git-bash)
8. [Step 7: Install some Vagrant plugins](#step-7-install-some-vagrant-plugins)
9. [Step 8: Clone your fork of Vagrant-DSpace using GitHub Desktop](#step-8-clone-your-fork-of-vagrant-dspace-using-github-desktop)
10. [Step 9: Customize your Vagrant-DSpace](#step-9-customize-your-vagrant-dspace)
11. [Step 10: Vagrant Up! ](#step-10-vagrant-up)
12. [Congratulations!](#congratulations)
13. [Reporting Bugs / Requesting Enhancements](#reporting-bugs--requesting-enhancements)
14. [License](#license)


Step 1: Be sure your computer will allow you to run VirtualBox
------------

Before you can start at all, you must ensure [Virtualization support is enabled](http://www.howtogeek.com/213795/how-to-enable-intel-vt-x-in-your-computers-bios-or-uefi-firmware/), if you have a BIOS-based computer (aka a PC). Reportedly, all Intel-based PCs ship with virtualization support disabled. All AMD-based computers ship with virtualization enabled. You should check, no matter what kind of PC you have, if you have a PC. None of this will work if you have virtualization turned off.

Step 2: Install Vagrant and Virtualbox
------------

You know the drill, this part is pretty easy: download the installer, click on the installer, do what you're told.
* [Vagrant](http://vagrantup.com/) version 1.8.3 or above.
* [VirtualBox](https://www.virtualbox.org/)

Step 3: Set up a GitHub account with SSH access
------------
While this step is OPTIONAL, it is recommended if you plan to do any DSpace development (even minor bug fixes or help testing code).
* [A GitHub account](https://help.github.com/articles/signing-up-for-a-new-github-account/) After you get your GitHub account, you may wish to [explore the social features of GitHub](https://help.github.com/articles/be-social/). In particular, you should follow other developers you know or work with. This includes all developers and contributors for projects with which you work. If you ever find a project on GitHub that you think is interesting, you should star it. This will help you find it later, and also helps other people find interesting projects. Likewise, you should check out the projects other people you know have starred. You'll find amazing things.
* Optionally install [GitHub Desktop](https://desktop.github.com/). It just makes working with GitHub easier.
* Create an SSH key and configure it for your GitHub account (if you plan to do any development)
    * [generate a key](https://help.github.com/articles/generating-an-ssh-key/) : GitHub Desktop will generate this key by default as part of the install process, but do verify that it exists.
    * [add this key to your GitHub account](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)

Step 4: Setup PuTTY / Pageant for SSH Forwarding
-------------

If you have GitHub SSH setup, you will WANT SSH forwarding enabled. This lets you be immediately identified with GitHub anytime you wish to add a new commit, etc.

Unfortunately, currently Vagrant has a bug where it only performs SSH Forwarding on Windows IF YOU HAVE PAGEANT running. This bug is in the net-ssh library, and supposedly is [fixed in net-ssh version 4.0.0](https://github.com/net-ssh/net-ssh/issues/192). Once Vagrant updates its dependencies, you may be able to REPLACE this step with using `ssh-agent` on Windows

* Install [PuTTY](http://www.putty.org/)
  * This will install PuTTY and all its utilities to your `Program Files` under a `PuTTY` folder. Pageant (`pageant.exe`) will be included in that directory.
* Run PuTTY Key Generator (`puttygen.exe`). You will need to generate a PuTTY version of your GitHub SSH key (as PuTTY has its own key format)
  * Select "Conversions" -> "Import Key"
  * Select your GitHub key (e.g. `[HOME]/.ssh/github_rsa`), and save it as a PPK file of the same name
* Run Pageant (`pageant.exe`), and add that new PPK key to its list. Pageant may open in your notification area. [This WinSCP guide shows how to add keys to Pageant](https://winscp.net/eng/docs/ui_pageant).
* WARNING: Pageant MUST BE RUNNING for SSH forwarding to work properly. You will likely want to set it up to startup whenever you start Windows. The WinSCP guide provides (above) provides instructions for that, or [this blog post](https://sites.google.com/a/martianpackets.com/martianpackets/Home/puttytips--runpageantonwindowsstartup).

Step 5: Fork Vagrant-DSpace and DSpace to your new GitHub account
------------

* [read how to fork a repository](https://help.github.com/articles/fork-a-repo/)
* [fork Vagrant-DSpace](https://github.com/dspace/vagrant-dspace)
* [fork DSpace](https://github.com/dspace/dspace)

Step 6: Configure a .bashrc file for Git Bash
------------

* An example is provided in the docs folder, just copy `docs/example-bashrc` to `~/.bashrc`. It should not require tweaking, but do verify its content, _don't run it blindly_.
* the example .bashrc file will ensure that when you start the Git BASH shell in GitHub Desktop, the SSH Key Agent will start, and will have the `~/.ssh/github_rsa` key loaded and ready
* You probably have realized that you don't yet have a copy of the `docs/example-bashrc` file cloned to your machine, because cloning Vagrant-DSpace to your machine is the next step. You should be able to download just the file using the following commands in a Git Bash shell:

1. Start a Git Bash Shell by double-clicking the Git Shell shortcut icon on your desktop. Alternately, you can right-click on your desktop, or any Windows Explorer window, and select the "Git Bash here" option.
2. Enter `cd ~ && curl https://raw.githubusercontent.com/DSpace/vagrant-dspace/master/docs/example-bashrc -o .bashrc`
3. Verify the content of the .bashrc file that you just downloaded. Open the file with your favorite code editor, or even Windows Notepad. Git Bash comes with a version of Vim installed, you can use that if you're comfortable with Vim.

Step 7: Install some Vagrant plugins
------------

Since you already have a Git Bash Shell window open (from the previous step) let's just install some useful Vagrant plugins, by typing the following at your Git Bash Shell command line prompt:

```
vagrant plugin install landrush
vagrant plugin install vagrant-cachier
vagrant plugin install vagrant-vbguest
vagrant plugin install vagrant-vbox-snapshot
```
It's OK to exit this Git Bash Sehll window, after you are done installing Vagrant Plugins, by entering `exit` at your Git Bash Shell command line prompt.

Step 8: Clone your fork of Vagrant-DSpace using GitHub Deskktop
------------

1. If it's not already running, start GitHub Desktop by double-clicking the GitHub shortcut icon on your desktop, or launch GitHub from the Start menu.
2. Click the plus/+ icon in the top left menu
3. Select "Clone", enter the Git URL for your fork of Vagrant-DSpace (created in Step 7 above). This URL will look something like: `git@github.com:yourgithubusername/vagrant-dspace.git`. An easy way to find this URL is to navigate to your fork on the GitHub site: `https://github.com/yourgithubusername/vagrant-dspace` and then click the green "Clone or download" button, using the Clone with SSH option.  

Step 9: Customize your Vagrant-DSpace
------------

1. in the `config` folder of Vagrant-DSpace, copy the `local.yaml.example` file to `local.yaml`, and then open the `local.yaml` file in your favorite code editor.
2. Change the configuration for [vm_memory](https://github.com/DSpace/vagrant-dspace/blob/master/config/local.yaml.example#L35) to equal no more than half of your computer's RAM. If you have less than 4GB of RAM on your host computer, you will likely run into trouble, however, Vagrant-DSpace works well on machines with at least 4GB of RAM, and the default value of vm_memory (2048) should be appropriate for most computers.
3. If you have 4 or more cores on your machine, we recommend you set [vb_cpus](https://github.com/DSpace/vagrant-dspace/blob/master/config/local.yaml.example#L45) to at least 2, and at most half of the available cores on your machine.
4. Set the [dspace::git_repo](https://github.com/DSpace/vagrant-dspace/blob/master/config/local.yaml.example#L89) option equal to the URL of your fork of DSpace (created in Step 6 above). This value will look something like: 'git@github.com:yourgithubusername/DSpace.git'
5. Note that you can [select the branch](https://github.com/DSpace/vagrant-dspace/blob/master/config/local.yaml.example#L90) Vagrant-Dspace will initially check out; leave this set to 'master' for now, but know that you *can* change this setting in the future, if you need to.

For a more complete description of the local.yaml file, and all the other configuration options available to you, consult the [How to Tweak Things to your Liking](https://github.com/DSpace/vagrant-dspace/blob/master/README.md#how-to-tweak-things-to-your-liking) section of the README.

Step 10: Vagrant Up!
------------

1. If it's not already running, start GitHub Desktop by double-clicking the GitHub shortcut icon on your desktop, or launch GitHub from the Start menu.
2. In the navigation panel on the left-hand side of GitHub Desktop, right-click the project folder for your fork of Vagrant-DSpace, and select "Git Shell" from the options.
2. At the Git Shell command line prompt, enter `vagrant up`
   * Wait for ~15-40 minutes (depends on your network speed) while Vagrant & Puppet do all the heavy lifting of cloning your fork of DSpace from GitHub & building & installing DSpace.
   * There may be times that vagrant will appear to "stall" for several minutes (especially during the Maven build of DSpace). But, don't worry.
6. Once complete, visit `http://localhost:8080/xmlui/` or `http://localhost:8080/jspui/` in your local web browser to see if it worked! _More info below on what to expect._
   * If you already have something running locally on port 8080, vagrant-dspace will attempt to use the next available port between 8081 and 8100. The default port is also configurable by creating a `config/local.yaml` (see below for more details)

Once complete, you'll have a fresh Ubuntu VM that you can SSH into by simply typing `vagrant ssh` at a GitHub Bash command line.

**
**NOTE:** sometimes when `vagrant up` finishes running, you will see a message like this:

```
Booting VM...
SSH connection was refused! This usually happens if the VM failed to
boot properly. Some steps to try to fix this: First, try reloading your
VM with 'vagrant reload', since a simple restart sometimes fixes things.
If that doesn't work, destroy your VM and recreate it with a 'vagrant destroy'
followed by a 'vagrant up'. If that doesn't work, contact a Vagrant
maintainer (support channels listed on the website) for more assistance.
```

This is normal, the VM just took a while longer to boot than Vagrant wanted to wait. Don't lose hope, you can still run `vagrant ssh` and very likely the machine will be ready for you. Especially if you've wandered off during the `vagrant up` command.
**

From this point, you can continue along with the README document, starting with [What will you get?](https://github.com/DSpace/vagrant-dspace/blob/master/README.md#what-will-you-get).

Congratulations!
------------

You now have a fully functional development environment for DSpace running on your Windows computer!

Reporting Bugs / Requesting Enhancements
----------------------------------------

Bugs / Issues or requests for enhancements can be reported via the [DSpace Issue Tracker](https://jira.duraspace.org/browse/DS). _Please select the "vagrant-dspace" component when creating your ticket in the issue tracker._

We also encourage you to submit Pull Requests with any recommended changes/fixes. As it is, the `vagrant-dspace` project is really just a labor of love, and we can use help in making it better.

License
--------

This work is licensed under the [DSpace BSD 3-Clause License](http://www.dspace.org/license/), which is just a standard [BSD 3-Clause License](http://opensource.org/licenses/BSD-3-Clause).

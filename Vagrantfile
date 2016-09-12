# -*- mode: ruby -*-
# vi: set ft=ruby :

####################################
# Vagrantfile for DSpace Development
#
# WARNING: THIS IS A WORK IN PROGRESS.
#
# DO NOT USE IN PRODUCTION. THIS IS FOR DEVELOPMENT/TESTING PURPOSES ONLY.
#
# ONLY TESTED with VirtualBox provider. Your mileage may vary with other providers
####################################

#=====================================================================
# Load settings from our YAML configs (/config/*.yaml)
#
# This bit of "magic" is possible cause a Vagrantfile is just Ruby! :)
# It reads some basic configs from our 'default.yaml' and 'local.yaml'
# in order to decide how to start up the Vagrant VM.
#=====================================================================
require "yaml"

# Load up our config files
# First, load 'config/default.yaml'
CONF = YAML.load(File.open("config/default.yaml", File::RDONLY).read)

# Next, load local overrides from 'config/local.yaml'
# If it doesn't exist, no worries. We'll just use the defaults
if File.exists?("config/local.yaml")
  CONF.merge!(YAML.load(File.open("config/local.yaml", File::RDONLY).read))
end

# At this point, all our configs can be referenced as CONF['key'], e.g. CONF['vb_name']

####################################
# To be able to set hostname on Ubuntu 16.04. we need to have vagrant at least
# of version 1.8.3 See also: https://github.com/mitchellh/vagrant/issues/7288
Vagrant.require_version ">= 1.8.3"

# Actual Vagrant configs
Vagrant.configure("2") do |config|
    # All Vagrant configuration is done here. The most common configuration
    # options are documented and commented below. For a complete reference,
    # please see the online documentation at vagrantup.com.

    #-----------------------------
    # Basic Box Settings
    #-----------------------------
    # Every Vagrant virtual environment requires a box to build off of.
    config.vm.box = CONF['vagrant_box']

    # The url from where the 'config.vm.box' box will be fetched if it
    # doesn't already exist on the user's system.
    if CONF['vagrant_box_url']
        config.vm.box_url = CONF['vagrant_box_url']
    end

    # define this box so Vagrant doesn't call it "default"
    config.vm.define "vagrant-dspace"

    # Hostname for virtual machine
    config.vm.hostname = "dspace.vagrant.dev"

    #-----------------------------
    # Network Settings
    #-----------------------------
    # configure a private network and set this guest's IP to 192.168.50.2
    config.vm.network "private_network", ip: CONF['ip_address']

    # Create a forwarded port mapping which allows access to a specific port
    # within the machine from a port on the host machine. In the example below,
    # accessing "localhost:[port]" will access port 8080 on the VM.
    config.vm.network :forwarded_port, guest: 8080, host: CONF['port'],
      auto_correct: true

    # Forward PostgreSQL database port (5432) to local machine port (for DB & pgAdmin3 access)
    config.vm.network :forwarded_port, guest: 5432, host: CONF['db_port'],
      auto_correct: true

    # If a port collision occurs (e.g. port 8080 on local machine is in use),
    # then tell Vagrant to use the next available port between 8081 and 8100
    config.vm.usable_port_range = 8081..8100

    # BEGIN Landrush (https://github.com/phinze/landrush) configuration
    # This section will only be triggered if you have installed "landrush"
    #     vagrant plugin install landrush
    if Vagrant.has_plugin?('landrush')
        config.landrush.enable
        config.landrush.tld = 'vagrant.dev'

        # let's use the Google free DNS
        config.landrush.upstream '8.8.8.8'
        config.landrush.guest_redirect_dns = false
    end
    # END Landrush configuration

    #------------------------------
    # Caching Settings (if enabled)
    #------------------------------
    # BEGIN Vagrant-Cachier (https://github.com/fgrehm/vagrant-cachier) configuration
    # This section will only be triggered if you have installed "vagrant-cachier"
    #     vagrant plugin install vagrant-cachier
    if Vagrant.has_plugin?('vagrant-cachier')
       # Use a vagrant-cachier cache if one is detected
       config.cache.auto_detect = true

       # set vagrant-cachier scope to :box, so other projects that share the
       # vagrant box will be able to used the same cached files
       config.cache.scope = :box

       # and lets specifically use the apt cache (note, this is a Debian-ism)
       config.cache.enable :apt

       # use the generic cache bucket for Maven
       config.cache.enable :generic, {
             "maven" => { cache_dir: "/home/vagrant/.m2/repository" },
       }

       # set the permissions for .m2 so we can use Maven properly
       config.vm.provision :shell, :inline => "chown vagrant:vagrant /home/vagrant/.m2"
    end
    # END Vagrant-Cachier configuration

    #-----------------------------
    # Basic System Customizations
    #-----------------------------
    # Check our system locale -- make sure it is set to UTF-8
    # This also means we need to run 'dpkg-reconfigure' to avoid "unable to re-open stdin" errors (see http://serverfault.com/a/500778)
    # For now, we have a hardcoded locale of "en_US.UTF-8"
    locale = "en_US.UTF-8"
    config.vm.provision :shell, :inline => "echo 'Setting locale to UTF-8 (#{locale})...' && locale | grep 'LANG=#{locale}' > /dev/null || update-locale --reset LANG=#{locale} && dpkg-reconfigure -f noninteractive locales"

    # Turn off annoying console bells/beeps in Ubuntu (only if not already turned off in /etc/inputrc)
    config.vm.provision :shell, :inline => "echo 'Turning off console beeps...' && grep '^set bell-style none' /etc/inputrc || echo 'set bell-style none' >> /etc/inputrc"

    #------------------------
    # Enable SSH Forwarding
    #------------------------
    # Turn on SSH forwarding (so that 'vagrant ssh' has access to your local SSH keys, and you can use your local SSH keys to access GitHub, etc.)
    config.ssh.forward_agent = true

    # Prevent annoying "stdin: is not a tty" errors from displaying during 'vagrant up'
    # See also https://github.com/mitchellh/vagrant/issues/1673#issuecomment-28288042
    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

    # THIS NEXT PART IS TOTAL HACK (only necessary for running Vagrant on Windows)
    # Windows currently doesn't support SSH Forwarding when running Vagrant's "Provisioning scripts" 
    # (e.g. all the "config.vm.provision" commands below). Although running "vagrant ssh" (from Windows commandline) 
    # will work for SSH Forwarding once the VM has started up, "config.vm.provision" commands in this Vagrantfile DO NOT.
    # Supposedly there's a bug in 'net-ssh' gem (used by Vagrant) which causes SSH forwarding to fail on Windows only
    # See: https://github.com/mitchellh/vagrant/issues/1735
    #      https://github.com/mitchellh/vagrant/issues/1404
    # See also underlying 'net-ssh' bug: https://github.com/net-ssh/net-ssh/issues/55
    #
    # Therefore, we have to "hack it" and manually sync our SSH keys to the Vagrant VM & copy them over to the 'root' user account
    # (as 'root' is the account that runs all Vagrant "config.vm.provision" scripts below). This all means 'root' should be able 
    # to connect to GitHub as YOU! Once this Windows bug is fixed, we should be able to just remove these lines and everything 
    # should work via the "config.ssh.forward_agent=true" setting.
    # ONLY do this hack/workaround if the local OS is Windows.
    if Vagrant::Util::Platform.windows?
        # MORE SECURE HACK. You MUST have a ~/.ssh/github_rsa (GitHub specific) SSH key to copy to VM
        # (ensures we are not just copying all your local SSH keys to a VM)
        if File.exists?(File.join(Dir.home, ".ssh", "github_rsa"))
            # Read local machine's GitHub SSH Key (~/.ssh/github_rsa)
            github_ssh_key = File.read(File.join(Dir.home, ".ssh", "github_rsa"))
            # Copy it to VM as the /root/.ssh/id_rsa key
            config.vm.provision :shell, :inline => "echo 'Windows-specific: Copying local GitHub SSH Key to VM for provisioning...' && mkdir -p /root/.ssh && echo '#{github_ssh_key}' > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa", run: "always"
        else
            # Else, throw a Vagrant Error. Cannot successfully startup on Windows without a GitHub SSH Key!
            raise Vagrant::Errors::VagrantError, "\n\nERROR: GitHub SSH Key not found at ~/.ssh/github_rsa (required for 'vagrant-dspace' on Windows).\nYou can generate this key manually OR by installing GitHub for Windows (http://windows.github.com/)\n\n"
        end
    end

    # Create a '/etc/sudoers.d/root_ssh_agent' file which ensures sudo keeps any SSH_AUTH_SOCK settings
    # This allows sudo commands (like "sudo ssh git@github.com") to have access to local SSH keys (via SSH Forwarding)
    # See: https://github.com/mitchellh/vagrant/issues/1303
    config.vm.provision :shell do |shell|
        shell.inline = "touch $1 && chmod 0440 $1 && echo $2 > $1"
        shell.args = %q{/etc/sudoers.d/root_ssh_agent "Defaults    env_keep += \"SSH_AUTH_SOCK\""}
    end

    # Check if a test SSH connection to GitHub succeeds or fails (on every vagrant up)
    # This sets a Puppet Fact named "github_ssh_status" on the VM. 
    # That fact is then used by 'setup.pp' to determine whether to connect to a Git Repo via SSH or HTTPS (see setup.pp)
    config.vm.provision :shell, :inline => "echo 'Testing SSH connection to GitHub on VM...' && mkdir -p /etc/facter/facts.d/ && ssh -T -q -oStrictHostKeyChecking=no git@github.com; echo github_ssh_status=$? > /etc/facter/facts.d/github_ssh.txt", run: "always"

    #------------------------
    # Provisioning Scripts
    #    These scripts run in the order in which they appear, and setup the virtual machine (VM) for us.
    #------------------------

    # Shell script to set up swap space for this VM

    if File.exists?("config/increase-swap.sh")
        config.vm.provision :shell, :inline => "echo '   > > > running local increase-swap.sh to ensure enough memory is available, via a swap file.'"
        config.vm.provision :shell, :path => "config/increase-swap.sh"
    else
        config.vm.provision :shell, :inline => "echo '   > > > running default increase-swap.sh scripte to ensure enough memory is available, via a swap file.'"
        config.vm.provision :shell, :path => "increase-swap.sh"
    end




    # Shell script to set apt sources.list to something appropriate (close to you, and actually up)
    # via apt-spy2 (https://github.com/lagged/apt-spy2)

    # If a customized version of this script exists in the config folder, use that instead

    if File.exists?("config/apt-spy-2-bootstrap.sh")
        config.vm.provision :shell, :inline => "echo '   > > > running local apt-spy2 to locate a nearby mirror (for quicker installs). Do not worry if it shows an error, it will be OK, there is a fallback.'"
        config.vm.provision :shell, :path => "config/apt-spy-2-bootstrap.sh"
    else
        config.vm.provision :shell, :inline => "echo '   > > > running default apt-spy2 to locate a nearby mirror (for quicker installs). Do not worry if it shows an error, it will be OK, there is a fallback.'"
        config.vm.provision :shell, :path => "apt-spy-2-bootstrap.sh"
    end


    # Shell script to initialize latest Puppet on VM & also install librarian-puppet (which manages our third party puppet modules)
    # This has to be done before the puppet provisioning so that the modules are available when puppet tries to parse its manifests.
    config.vm.provision :shell, :path => "puppet-bootstrap-ubuntu.sh"

    # Copy our 'hiera.yaml' file over to the global Puppet directory (/etc/puppet) on VM
    # This lets us run 'puppet apply' manually on the VM for any minor updates or tests
    config.vm.provision :shell, :inline => "cp /vagrant/hiera.yaml /etc/puppet"

    # display the local.yaml file, if it exists, to give us a chance to back out
    # before waiting for this vagrant up to complete
    if File.exists?("config/local.yaml")
        config.vm.provision :shell, :inline => "echo '   > > > using the following local.yaml data, if this is not correct, control-c now...'"
        config.vm.provision :shell, :inline => "echo '---BEGIN local.yaml ---' && cat /vagrant/config/local.yaml && echo '--- END local.yaml -----'"
    end

    # Call our Puppet initialization script
    config.vm.provision :shell, :inline => "echo '   > > > Beginning Puppet provisioning, this may take a while (and will appear to hang during DSpace Install step)...'"
    config.vm.provision :shell, :inline => "echo '   > > > PATIENCE! Console output is only shown after each step completes...'"

    # Actually run Puppet to setup the server, install all prerequisites and install DSpace
    config.vm.provision :puppet do |puppet|
        puppet.manifests_path = "."
        puppet.manifest_file = "setup.pp"
        puppet.options = "--verbose --debug"
    end

    #-------------------------------------
    # Local customizations to VM
    #-------------------------------------
    # Check if ~/.gitconfig exists locally
    # If so, copy basic Git Config settings to Vagrant VM
    # This lets developers easily commit code to GitHub as themselves
    if File.exists?(File.join(Dir.home, ".gitconfig"))
        git_name = `git config user.name`   # find locally set git name
        git_email = `git config user.email` # find locally set git email
        # set git name for 'vagrant' user on VM
        config.vm.provision :shell, :inline => "echo 'Saving local git username to VM...' && sudo -i -u vagrant git config --global user.name '#{git_name.chomp}'"
        # set git email for 'vagrant' user on VM
        config.vm.provision :shell, :inline => "echo 'Saving local git email to VM...' && sudo -i -u vagrant git config --global user.email '#{git_email.chomp}'"
    end

    # Load any local customizations from the "local-bootstrap.sh" script (if it exists)
    # Check out the "config/local-bootstrap.sh.example" for examples
    if File.exists?("config/local-bootstrap.sh")
        config.vm.provision :shell, :inline => "echo '   > > > running config/local_bootstrap.sh (as vagrant)' && sudo -i -u vagrant /vagrant/config/local-bootstrap.sh"
    end

    # For IDE support + vagrant-dspace
    # Set up dspace-src subdirectory as a synced folder to support the use of an IDE on the host machine
    if CONF['sync_src_to_host'] == true
        config.vm.synced_folder "dspace-src", "/home/vagrant/dspace-src"
    end

    #############################################
    # Customized provider settings for VirtualBox
    # Many of these settings use VirtualBox's
    # 'VBoxManage' tool: http://www.virtualbox.org/manual/ch08.html
    #############################################
    config.vm.provider :virtualbox do |vb|
        # Boot into GUI mode (login: vagrant, pwd: vagrant). Useful for debugging boot issues, etc.
        vb.gui = CONF['vm_gui_mode']

        # Name of the VM created in VirtualBox (Also the name of the subfolder in ~/VirtualBox VMs/ where this VM is kept)
        vb.name = CONF['vm_name']

        # Let VirtualBox know this is Ubuntu
        vb.customize ["modifyvm", :id, "--ostype", 'Ubuntu']

        # Use VBoxManage to provide Virtual Machine with extra memory (default is only 300MB)
        vb.customize ["modifyvm", :id, "--memory", CONF['vm_memory']]

        # use the configured settings for memory and cpus (look in default.yaml or local.yaml to set these values)
        vb.memory = CONF['vm_memory']
        vb.cpus = CONF['vb_cpus']

        if CONF['vb_max_cpu']
          # Use VBoxManage to ensure Virtual Machine only has access to a percentage of host CPU
          vb.customize ["modifyvm", :id, "--cpuexecutioncap", CONF['vm_max_cpu']]
        end

        # Use VBoxManage to have the Virtual Machine use the Host's DNS resolver
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]

        # This allows symlinks to be created within the /vagrant root directory,
        # which is something librarian-puppet needs to be able to do. This might
        # be enabled by default depending on what version of VirtualBox is used.
        # Borrowed from https://github.com/purple52/librarian-puppet-vagrant/
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
    end

    # if we're running with vagrant-notify, send a notification that we're done, in case we've wandered off
    # https://github.com/fgrehm/vagrant-notify
    # NOTE: Currently this plugin only works on Linux or OSX hosts
    if Vagrant.has_plugin?('vagrant-notify')
        config.vm.provision :shell, :inline => "notify-send --urgency=critical 'Vagrant-DSpace is up! Get back to work! :-)'", run: "always"
    end

    # Message to display to user after 'vagrant up' completes
    config.vm.post_up_message = "Setup of 'vagrant-dspace' is now COMPLETE! DSpace should now be available at:\n\nhttp://localhost:#{CONF['port']}/xmlui/\nLOGIN: '#{CONF['dspace::admin_email']}', PASSWORD: '#{CONF['dspace::admin_passwd']}'\n\nThe DSpace database is accessible via local port #{CONF['db_port']}.\nYou can SSH into the new VM via 'vagrant ssh'"
end

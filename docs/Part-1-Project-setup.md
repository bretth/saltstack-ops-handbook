# Part 1 - Project setup

08/04/2016

SaltStack is a veritable spice rack of seasionings which can be confusing for the beginner, so we're going to start with agentless salt and use the _salt-ssh _ command _ _ as our beachhead into foreign territory. 

At it's simplest, the _salt-ssh _ command is used to run raw commands on hosts or execute salt execution module jobs on the target host through ssh (the transport). 

- [ ]  Initialise the project, install requirements, and set _env_ variables.

		export domain=example.com # your naked/apex domain
		pew mkproject salt.$domain # python 2.7 

	You should now be in the project directory so we can create the files we'll use to start and install salt.

		git init .
		echo 'salt==2016.3.1' >> requirements.txt
		brew install libgit2 # for pygit2
		echo 'pygit2==0.24.1' >> requirements.txt
		pip install -r requirements.txt

- [ ]   `touch .gitignore` 

		# .gitignore
		# cache and log files
		var/*
		# private keys
		*.rsa
		*.pem

- [ ]  Create the log folder.

	 _salt-ssh_ will create all folders with the exception of the log folder. We will keep everything contained in the project folder including salt logs and cache.

		mkdir -p var/log/salt 

- [ ]  Create project secrets that will not be shared or deployed.
	- [ ]  ssh keypair that _salt-ssh_ will use to access masters

			mkdir ssh
			# -N passphrase recommended -C comment -f output file
			ssh-keygen -N '' -C salt.$domain -f ssh/salt-ssh.rsa

	- [ ]  Create a project gpg2 key that will be used to encrypt secrets in the repository

			gpg2 —gen-key
			# Real Name: [salt.](http://salt.example.com) example.com
			# Passphrase recommended
			# Comment: Salt example.com project

	Needless to say you should back these up securely and provide an emergency access plan if you are the only one holding these keys.

## YAML files

The YAML format is used heavily in SaltStack (as with Ansible). YAML is an alternative to json for configuration designed for readability by humans.

Like python, space is significant in YAML to show hierarchy. You must configure your chosen editor to **always use spaces over tabs** (and 2 spaces per tab is the conventional style).

The critical things to know about YAML are `key: value` pairs translate to python dictionaries, a list item looks like `- list item` , and **beware** the dictionary nested in a list which needs a double indent.

[YAML Idiosyncrasies](https://docs.saltstack.com/en/latest/topics/troubleshooting/yaml_idiosyncrasies.html)

## Master Configuration

- [ ]   `touch master` file.

	The master is always the machine running the salt command regardless of whether it is an agentless _salt-ssh_ or _salt_ command run on a master with agent (daemon). _ _ The exception to this is the _salt-call _ which is run on the minion (target host). _ _ 

	[Configuring the Salt Master](https://docs.saltstack.com/en/latest/ref/configuration/master.html)

		# [https://docs.saltstack.com/en/develop/ref/configuration/master.html](https://docs.saltstack.com/en/develop/ref/configuration/master.html) 
		
		root_dir: . # store relative to the project folder
		user: [[user]] # your current env $USER username 
		pki_dir: .

- [ ]  Create the salt1 master virtual machine on the provider preferrably with salt1.[[domain]] hostname and configured with internal network interface which we can use communication between minion and master. 

	To simplify connecting attach your `ssh/salt-ssh.rsa.pub` identity file if the provider allows, and a bootstrap script that activates the firewall, updates the machine to the latest version, installs python, and reboots. The bootstrap script should do as little as possible. The rest will be done in salt. For example:

		#!/bin/sh
		# Use [http://ipinfo.io](http://ipinfo.io) to get your actual public ip address
		ufw allow proto tcp from [[your public ip address]] to any port 22
		ufw --force enable
		apt update —quiet -y
		apt upgrade -qy
		apt install -qy python
		shutdown -r now

	- [ ]  Edit `/etc/hosts` to add an entry for [salt1.example.com](http://salt1.example.com) 

			echo "[[vm ip address]] salt1.example.com" | sudo tee -a /etc/hosts

- [ ]  Deploy your project ssh public identity file (if you haven't already) and test that you can login.

		brew install ssh-copy-id # not installed by default on macOS
		ssh-copy-id -i ssh/salt-ssh.rsa.pub root@salt1.example.com
		ssh -i ssh/salt-ssh.rsa.pub root@salt1.example.com

	 _ssh-salt_ has an option for connecting with a password and deploying ssh keys but I found it not 100% reliable.

## Rosters

- [ ]   `touch roster` file.
The roster file defines your minions for _salt-ssh._ Like the master file in SaltStack it is in YAML format. The roster maps minion ids to host configurations. 

	[Salt Rosters](https://docs.saltstack.com/en/latest/topics/ssh/roster.html)

		# [https://docs.saltstack.com/en/latest/topics/ssh/roster.html](https://docs.saltstack.com/en/latest/topics/ssh/roster.html) 
		salt1.example.com: # the minion id 
			host: salt1.example.com # the simplest host config

## Saltfiles & salt-ssh

- [ ]   `touch saltfile` with config for salt-ssh.

	The saltfile is a shortcut way of providing commandline options to salt commands including salt-ssh that are used every time.

		# [https://docs.saltstack.com/en/latest/topics/ssh/index.html#define-cli-options-with-saltfile](https://docs.saltstack.com/en/latest/topics/ssh/index.html#define-cli-options-with-saltfile) 
		
		salt-ssh: 
		 config_dir: . 

- [ ]  Verify the _salt-ssh_ command can connect with a raw ssh command `—raw` `-r` targeting the all salt machines and just because we can, log _everything_ to console `—log-level={{all|debug ...}} -l` . We'll also use the `—ignore-host-keys -i` option on first run.

		# since salt-ssh still requires python to be installed on the target machine we'll install it if it isn't already
		salt-ssh 'salt*' -i -l all -r 'apt -qy install python' 

	The first time the _salt-ssh_ command is run it will create a local ssh keypair if required which it isn't because we've already done that. There are additional [debugging options](https://docs.saltstack.com/en/latest/topics/ssh/index.html#debugging-salt-ssh) if you need them.

	[Salt SSH](https://docs.saltstack.com/en/stage/topics/ssh/index.html)

- [ ]  With python installed, verify the _salt-ssh_ command can connect with the host and run a _salt_ _execution_ _module_ (a job) on the target vm. In this instance we will target _all_ (of one) machines in the roster using a glob. 

		salt-ssh '*' test.ping

	[execution modules](https://docs.saltstack.com/en/latest/ref/modules/all/index.html)

## Summary

The _salt-ssh_ command is the method for managing minions without master or minion daemons being installed on any machine but leveraging the same configuration, layout and files. At this point you should be able to: 

- Configure salt _master_ files
- Understand the basics of the YAML format
- Configure salt command _saltfiles_ 
- Configure a _roster_ file
- Execute raw commands with _salt-ssh _ on a rostered minion
- Execute salt module jobs with _salt-ssh _ on a rostered minion

You can do a lot with execution modules but really it's only one step more evolved than running shell commands directly. We can do better.
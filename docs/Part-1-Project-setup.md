# Part 1 - Project setup

08/04/2016

SaltStack is a veritable spice rack of seasionings which can be confusing for the beginner, so we're going to start with agentless salt and use the _salt-ssh _ command _ _ as our beachhead into foreign territory. 

At it's simplest, the _salt-ssh _ command is used to run raw commands on hosts or execute salt execution module jobs on the target host through ssh (the transport). 

- [ ]  Initialise the project, install requirements, and set _env_ variables.

		pew mkproject [salt.example.com](http://salt.example.com) # python 2.7 

	You should now be in the project directory so we can create the files we'll use to start and install salt.

		git init .
		echo 'salt==2016.3.2' >> requirements.txt
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

## Secrets

- [ ]  Create project secrets that will not be shared.
	- [ ]  ssh keypair that _salt-ssh_ will use to access masters

			mkdir ssh
			# -N passphrase recommended -C comment -f output file
			ssh-keygen -N '' -C [salt.example.com](http://salt.example.com) -f ssh/salt-ssh.rsa

	- [ ]  Create a project gpg2 key (with a passphrase) that will be used to sign a passwordless gpg key to encrypt secrets in the repository.

			$ gpg2 --gen-key
			# Real Name: [salt.](http://salt.example.com) [example.com](http://example.com) 
			# Passphrase
			# Comment: Salt example.com project

	- [ ]  Create a subkey for encryption only

		A subkey is what will be distributed to machines and can be revoked if necessary.

			$ gpg2 --list-keys
			pub 4096R/E3FFE777 2016-08-25
			uid [ultimate] [salt.example.com](http://salt.example.com) (Salt project key) <admin+salt@example.com>
			sub 4096R/2F0200A5 2016-08-25
			
			$ gpg2 --edit-key salt.example.com
			gpg> addkey # (6) RSA (encrypt only)
			# enter your pass phrase
			gpg> save
			
			# 
			# use -a --armor to make a non-binary file
			$ gpg2 --export-secret-keys -a salt.example.com > salt.example.com.key
			$ gpg2 --export -a salt.example.com > [salt.example.com.pub](http://salt.example.com.pub) 
			
			$ gpg2 --export-secret-subkeys --armor 97E1D516 > srv/pillar/files/hosts/test-salt1.example.com/files/gnupg/private_project_key.asc

	- [ ]  Export the secret & public keys

			# use -a --armor to make a non-binary file
			$ gpg2 --export-secret-keys -a [salt.example.com](http://salt.example.com) > salt.example.com.key
			$ gpg2 --export -a salt.example.com > [salt.example.com.pub](http://salt.example.com.pub) 

	- [ ]  Export the subkey

			$ gpg2 --export-secret-subkeys -a [salt.example.com](http://salt.example.com) > salt.example.com1.key

	- [ ]  Delete the key and subkeys from the keyring

			$ gpg2 --delete-secret-and-public-key [salt.example.com](http://salt.example.com) 

	- [ ]  Re-import the subkey

			$ gpg2 --import salt.example.com1.key

	- [ ]  Change the password to an empty one

			$ gpg2 --edit-key
			gpg> passwd
			# use empty pass phrase
			gpg> save

	- [ ]  Re-export the subkey that will be distributed to masters

			gpg2 --export-secret-subkeys -a [salt.example.com](http://salt.example.com) > salt.example.com1.key

	- [ ]  Save the original _salt.example.com.key _ somewhere safe.

	Needless to say you should back these up securely and provide an emergency access plan if you are the only one holding these keys.

## YAML files

The YAML format is used heavily in SaltStack (as with Ansible). YAML is an alternative to json for configuration designed for readability by humans.

YAML files as used by Salt are essentially just composed of dictionaries, lists, numbers and strings.

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

- [ ]  Create the salt1 master virtual machine on the provider preferrably with [test-salt1.example.com](http://test-salt1.example.com) hostname and configured with internal network interface which we can use for communication later between minions and master. 

	To simplify connecting attach your project `ssh/salt-ssh.rsa.pub` identity file if the provider allows, and a bootstrap script that activates the firewall, updates the machine to the latest version, installs python, and reboots. The bootstrap script should do as little as possible. The rest will be done in salt. For example:

		#!/bin/sh
		# Use [http://ipinfo.io](http://ipinfo.io) to get your actual public ip address
		ufw allow proto tcp from [[your public ip address]] to any port 22
		ufw —force enable
		apt update —quiet -y
		apt upgrade -qy
		apt install -qy python
		shutdown -r now

	- [ ]  Edit `/etc/hosts` to add an entry for [dev-salt1.example.com](http://dev-salt1.example.com) 

			echo "[[vm ip address]] test-salt1.example.com" | sudo tee -a /etc/hosts

	- [ ]  Append to `~/.ssh/config` a config for your new key

			host dev.s1.ex
			hostname [dev-salt1.example.com](http://dev-salt1.example.com) 
			user root
			identityfile ~/[[path]]/salt.example.com/ssh/salt-ssh.rsa

		We'll now use _ssh test.s1.ex_ instead of _ssh -i ssh/salt-ssh.rsa root@salt1.example.com_ 

- [ ]  Deploy your project ssh public identity file (if you haven't already) and test that you can login.

		brew install ssh-copy-id # not installed by default on macOS
		ssh-copy-id test.s1.ex
		ssh test.s1.ex

	 _ssh-salt_ has an option for connecting with a password and deploying ssh keys but I found it not 100% reliable.

## Rosters

- [ ]   `touch roster` file.
The roster file defines your minions for _salt-ssh._ Like the master file in SaltStack it is in YAML format. The roster maps minion ids to host configurations. 

	[Salt Rosters](https://docs.saltstack.com/en/latest/topics/ssh/roster.html)

		# [https://docs.saltstack.com/en/latest/topics/ssh/roster.html](https://docs.saltstack.com/en/latest/topics/ssh/roster.html) 
		test-salt1.example.com: # the minion id 
			host: test-salt1.example.com # the simplest host config

	We could just us a short minion id, but a fqdn makes sense when we want to refer to that minion definitively. With salt-ssh we can target hosts using globs such as '*' for all or 'dev*' for minions starting with dev. We can also group them together with nodegroups so that minions can do more than one role which we will later on.

## Saltfiles & salt-ssh

- [ ]   `touch saltfile` with config for salt-ssh.

	The saltfile is a shortcut way of providing commandline options to salt commands including salt-ssh that are used every time.

		# [https://docs.saltstack.com/en/latest/topics/ssh/index.html#define-cli-options-with-saltfile](https://docs.saltstack.com/en/latest/topics/ssh/index.html#define-cli-options-with-saltfile) 
		
		salt-ssh: 
		 config_dir: . 

- [ ]  Verify the _salt-ssh_ command can connect with a raw ssh command `—raw` `-r` targeting the all salt machines and just because we can, log _everything_ to console `—log-level={{all|debug ...}} -l` . We'll also use the `—ignore-host-keys -i` option on first run.

		# since salt-ssh still requires python to be installed on the target machine we'll install it if it isn't already
		salt-ssh '*' -i -l all -r 'apt -qy install python' 

	The first time the _salt-ssh_ command is run it will create a local ssh keypair if required which it isn't because we've already done that. There are additional [debugging options](https://docs.saltstack.com/en/latest/topics/ssh/index.html#debugging-salt-ssh) if you need them.

	[Salt SSH](https://docs.saltstack.com/en/stage/topics/ssh/index.html)

- [ ]  With python installed, verify the _salt-ssh_ command can connect with the minion and run a _salt_ _module (_ salt.modules) _._ In this instance we will target _all_ (of one) machines in the roster using a glob. 

	We'll call it a minion because even though it doesn't have the minion agent installed, _salt-ssh, _ installs a standalone thin environment it can execute commands through.

	Modules are the backbone of salt.

		salt-ssh '*' test.ping

	Familiarize yourself with the other modules you can control your minion with and read the source code.

	[execution modules](https://docs.saltstack.com/en/latest/ref/modules/all/index.html)

## Nodegroups (aka roles)

[Node groups](https://docs.saltstack.com/en/latest/topics/targeting/nodegroups.html)

- [ ]   ~~Update ~~ `~~master~~` ~~ to configure nodegroups~~ 

	Nodegroups [don't work](https://github.com/saltstack/salt/issues/16068) ~~correctly~~ [much](https://github.com/saltstack/salt/issues/27842) at all in salt-ssh at the moment, so stick with glob targetting in salt-ssh, and encode the group name(s) in the minion id. To get around having to remember glob patterns export them as environment variables using something like [this](http://stackoverflow.com/a/34093548) . 

	- [ ]  Target all test minions.

		salt-ssh 'test*' test.versions

## Summary

The _salt-ssh_ command is the method for managing minions without master or minion daemons being installed on any machine but leveraging the same configuration, layout and files. At this point you should be able to: 

- Configure salt _master_ files
- Understand the basics of the YAML format
- Configure salt command _saltfiles_ 
- Configure a _roster_ file
- Execute raw commands with _salt-ssh _ on a rostered minion
- Execute salt module jobs with _salt-ssh _ on a rostered minion
- Use glob patterns to target minions

You can do a lot with execution modules but really it's only one step more evolved than running shell commands directly. We can do better.
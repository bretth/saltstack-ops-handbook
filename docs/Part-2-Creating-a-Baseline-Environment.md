# Part 2 - Creating a Baseline Environment

08/04/2016

## State Files

A state (.sls) file executes functions from state modules (salt.states). State modules would usually call salt.modules to do the actual work. 

[How Do I Use Salt States?](https://docs.saltstack.com/en/latest/topics/tutorials/starting_states.html)

- [ ]  Optionally create a state file to install etckeeper in our test environment

	We're going to use etckeeper to track changes to configuration files on the host in development which is a good excuse to demonstrate the most simple of state files.

	- [ ]   `mkdir -p srv/salt/utils` 

		Salt uses _/srv/salt_ as the default location for state files. 

	- [ ]   `touch srv/salt/utils/init.sls` 

		Just like python's __init__.py files the init.sls takes the namespace of it's parent directory, 'utils'. Namespaces in salt are pretty similar to python.

	- [ ]   `touch srv/salt/utils/etckeeper.sls` 

			# salt utils.etckeeper
			
			# track changes in /etc
			# salt.states.pkg.installed(name='etckeeper')
			etckeeper: # global id and name arg
				pkg.installed # module.function

		A move verbose way of defining this without comments to describe why we're installing it would be:

			install etckeeper to track etc changes: # global id
				pkg.installed: # module.function
			 	- name: etckeeper # name argument in a list of keyword args

## File Serving

- [ ]  Append to `./master` the config for the Salt File Server _file_roots_ . 

	Salt can find state files in one or more _file_roots _ and _ _ serve them to minions for execution. 

		file_roots:
			base: # Environment. base is the default. 
		 	- srv/salt # path to a package

	You can have multiple _file_roots_ environments and paths aside from the default _base_ environment _ _ (dev, staging etc).

	Salt will search in order of configuration, so it gives flexibility to override behaviour of existing installed packages or alter the namespace to avoid conflicts.

- [ ]   _Validate_ the etckeeper state file against the target hosts.

		$ salt-ssh 'test*' state.show_sls utils.etckeeper
		test-salt1.example.com:
		 ----------
		 install etckeeper to track etc changes:
		 ----------
		 __env__:
		 base
		 __sls__:
		 utils.etckeeper
		 pkg:
		 |_
		 ----------
		 name:
		 etckeeper
		 - installed
		 |_
		 ----------
		 order:
		 10000 # the order of execution

- [ ]   _Test_ the etckeeper state file against a target.

		$ salt-ssh 'test*' state.apply utils.etckeeper test=true
		test-salt1.example.com:
		----------
		 ID: install etckeeper to track etc changes
		 Function: pkg.installed
		 Name: etckeeper
		 Result: None
		 Comment: The following packages would be installed/updated: etckeeper
		 Started: 13:39:39.435264
		 Duration: 27.425 ms
		 Changes: 
		
		Summary for test-salt1.example.com
		------------
		Succeeded: 1 (unchanged=1)
		Failed: 0
		------------
		Total states run: 1

		# show the or

	The verbosity of the output can be adjusted with the master settings _state_output (e.g. state_output: changes) _ and _state_verbose: false _ (to remove unchanged states from output). 

## The Low State

The low state is the state files compiled down to an order of execution. Not very interesting for one function, but when we get to out-of-declaration-order execution this is an extremely handy command.

- [ ]  Display the low state for an individual state file with _show_low_sls_ 

		salt-ssh 'test*' state.show_low_sls utils.etckeeper
		test-salt1.example.com:
		 |_
		 ----------
		 __env__:
		 base
		 __id__:
		 install etckeeper to track /etc changes
		 __sls__:
		 utils.etckeeper
		 fun:
		 installed
		 name:
		 etckeeper
		 order:
		 10000
		 state:
		 pkg

## Salt Top File

- [ ]   `touch srv/salt/top.sls` file.

	We are able to apply state files to minions manually because _all state files are available to all minions_ , but the top file is a special state file that maps states to minions so we don't need to apply everything manually.

		# salt/top
		# [https://docs.saltstack.com/en/latest/ref/states/top.html](https://docs.saltstack.com/en/latest/ref/states/top.html) 
		
		base: # environment
			'*': # match all minions
		 'test*': # group to match
		 - utils.etckeeper
		 

	By using groups we can eaily add extra states that wouldn't be used in production or allow a host to have multiple roles.

	[The Top File](https://docs.saltstack.com/en/latest/ref/states/top.html)

	- [ ]  Apply the top file state to any minion

			salt-ssh '*' state.apply
			
			# other useful commands
			salt-ssh '*' state.show_highstate # high level alphabetical overview of what will be executed
			salt-ssh '*' state.apply packaging # execute one or more comma separated state files

- [ ]  Create network state files to set a private network interface

	Most providers have a private interface which will be useful for minions to communicate with each other securely within a location.

	- [ ]  Determine which interface we can use

			# run a raw call
			salt-ssh '*' -r 'ifconfig -a'

		In my case _ens7 _ is available but not configured, and the provider pre-assigns an ip address to use.

	- [ ]   `mkdir srv/salt/network` 
	- [ ]   `touch srv/salt/network/init.sls` 

			# salt network
			
			ens7:
			 network.managed:
			 - enabled: true
			 - type: eth
			 - proto: static
			 - ipaddr: 10.99.0.11 # your private ip
			 - netmask: 255.255.0.0 # your netmask
			 - mtu: 1450 # provider recommended mtu
			

	- [ ]  Update `srv/salt/top.sls` to append `- network` to `base: '*'` 

			# salt top
			# [https://docs.saltstack.com/en/latest/ref/states/top.html](https://docs.saltstack.com/en/latest/ref/states/top.html) 
			
			base: # environment
			 '*': # match all minions
			 - network
			 'test*': # group to match
			 - utils.etckeeper

	- [ ]  Apply the network changes

		We could dig around the 'network' module to see what network.managed does or we can just let etckeeper do the work.

			salt-ssh 'test*' state.apply network

		In this case it changes the /etc/network/interfaces file.

		- [ ]  Revert the changes to /etc/network/interfaces in etckeeper 
	- [ ]  Prepend _file.copy_ to `srv/salt/network/init.sls` to backup /etc/network/interfaces

		Having a backup of the starting state is useful when we make multiple state changes over time without having an adequate migration strategy in place. 

			# salt network
			
			# this will only copy the first time
			/etc/network/interfaces.orig: # target
			 file.copy:
			 - source: /etc/network/interfaces
			 - preserve: true # keep permissions
			
			ens7:
			 network.managed:
			 - enabled: true
			 - type: eth
			 - proto: static
			 - ipaddr: 10.99.0.11 # your private ip
			 - netmask: 255.255.0.0 # your netmask
			 - mtu: 1450 # provider recommended mtu

	- [ ]  Add a check command to ens7.

		It's easy to make state functions succeed, but sometimes it doesn't mean it actually worked as intended. A _check_cmd _ asserts the output of the command to be true or false to determine whether the function was actually successful.

			ens7:
			 network.managed:
			 - enabled: true
			 - type: eth
			 - proto: static
			 - ipaddr: 10.99.0.11 # your private ip
			 - netmask: 255.255.0.0 # your netmask
			 - mtu: 1450 # provider recommended mtu
			 - check_cmd:
			 - "ifconfig ens7 | grep 'inet addr:10.99.0.11'"

	- [ ]   `touch srv/salt/network/test.sls` 

		We're now going to apply some basic test driven development to saltstack _. _ 

		-  _Why test salt state files?_ 

			Well actually, salt state files are the tests. Salt state functions either succeed or fail when run which gives them the essential characteristics of a test. The check_cmd even allows us to do an additional assert. 

			Applying a salt file or applying 'top.sls' also produces a summary of successes and failures which makes salt a test runner What is missing to complete the picture are setup and teardown. 

			Setup will help identify dependencies that either need to be documented as requirements, or dealt with as part of the state file or package. Teardown will ensure that there is clean separation between this package and the setup of the next, and may also be useful aid when writing state migrations (transition to new state and reverse previous state).

			Since salt provides most of the tools we need to do all these things in the state files themselves there seems no reason not to even given some limitations.

			# salt/network/test
			
			include: # import and execute the following state files 
				- local.network
			 - local.network.teardown

		The 'include' function imports and runs state files recursively in the order they are imported. Unlike python you can't do a relative include in a salt state file.

		As discussed the state file under test really _is_ the test and even includes a setup to backup the main config file, so we really don't need to much other than add a teardown file.

		[Include and Exclude](https://docs.saltstack.com/en/latest/ref/states/include.html)

	- [ ]   `touch srv/salt/network/teardown.sls` 

			# salt network.teardown
			
			# teardown
			/etc/network/interfaces:
			 file.copy:
			 - source: /etc/network/interfaces.orig
			 - preserve: true
			 - force: true
			 
			ip addr flush ens7:
			 cmd.run

	- [ ]   `salt-ssh 'test*' state.apply network.test` 

		Run the test!

	We have a problem with our state files though. The runtime configuration is wired into the state files which doesn't make it very portable and breaks our 12factor contract. The answer to this are pillars.

## Pillars

- [ ]  Append `master` to configure a flat file based pillar.

	Here we introduce another key concept, _pillars_ . Pillars are key value stores to any depth that hold secrets and other data which may be intended only for specific minions. 

		# Configuration of a file pillar, pillar_roots is the same as state file_roots.
		pillar_roots:
			base:
		 	- srv/pillar/default

	[Pillar Walkthrough](https://docs.saltstack.com/en/latest/topics/tutorials/pillar.html)

	Pillars are pluggable so other services could also provide the key, value pairs, such as [vault](https://www.vaultproject.io) .

- [ ]   `touch srv/pillar/default/network.sls` to add some configuration settings for network.

		# pillar network
		
		network:
		 private_network_interface: ens7
		 type: eth
		 proto: static
		 netmask: 255.255.0.0

- [ ]   `touch srv/pillar/default/top.sls` 

	Just like salt tops, pillar has a top as well that determines what pillar files are merged to a single key value store. Unlike the salt top we need to actually map the pillar state file to a target to use it since _pillars are only sent to their targets._ 

		# pillar top
		
		base:
		 '*': # available to all minions
		 - network

- [ ]  View the key value items to ensure you they are configured as expected

		salt-ssh 'test*' pillar.items
		# ensure a specific value exists for the target
		salt-ssh 'test*' pillar.get network:private_network_interface

	Now we need to use those pillar items in our state file.

## Jinja Templates

- [ ]  Update `srv/network/init.sls` 

	By default state files are compiled [jinja](http://jinja.pocoo.org/docs/dev/templates/) templates with some context variables thrown in. The first context variable we'll use is the _pillar_ context variable.

	[Understanding Jinja](https://docs.saltstack.com/en/latest/topics/jinja/index.html)

		# salt network
		
		# setup
		/etc/network/interfaces.orig:
		 file.copy:
		 - source: /etc/network/interfaces
		 - preserve: true
		
		{% set network=pillar['network'] %}
		
		{{ network.private_network_interface }}:
		 network.managed:
		 - enabled: true
		 - type: {{ network.type }}
		 - proto: {{ network.proto }}
		 - ipaddr: {{ network.internal_ipaddr }}
		 - netmask: {{ network.netmask }}

	Using _pillar['network'] _ has a weakness; if the key doesn't exist the state file fails when we apply it.

	There's also another issue; we haven't set a network:internal_ipaddr. That's because we don't want the same ip address for every minion.

## External Pillars (file_tree)

A file_tree pillar is a pattern for applying a per-minion or per-group pillar from a file. Sadly file_tree nodegroups don't work with salt-ssh yet so you'll need to workaround that by embedding files in a standard pillar targetted at a group if you need it.

- [ ]   `mkdir srv/pillar/minion` 
- [ ]  Append to `master` the _ext_pillar_ config for _file_tree._ 

		ext_pillar:
		 - file_tree:
		 		# remember the YAML double indent rule of dicts under lists!
		 	root_dir: srv/pillar/files

	The file_tree pillar module serves directories and their children as key values pairs terminating in a file key with file contents as it's value. It can target hosts or nodegroups and gets merged with other pillars. We could use this pattern to store secrets for individual or groups of hosts, but in this case we'll use it as an overkill method for storing the private ipaddr of the host.

	Note **there is a ** **[bug](https://github.com/saltstack/salt/issues/33069)** with hidden binary files like *.DS_Store breaking the file_tree pillar. Purge them ( `find . -name '*.DS_Store' -type f -delete` ).

- [ ]   `mkdir -p srv/pillar/minion/hosts/test-salt1.example.com/network` 
- [ ]   `touch srv/pillar/minion/hosts/test-salt1.example.com/network/internal_ipaddr` 

	Put your internal ip address in the file

	- [ ]  Test the address is available `salt-ssh 'test*' pillar.get network:internal_ipaddr` 

[pillar modules](https://docs.saltstack.com/en/latest/ref/pillar/all/index.html)

## Formulae

- [ ]   `mkdir srv/formulas` 
- [ ]  Add external formula for locale, timezone, hostname, openssh, and apt.

	Salt _formula_ are simply pre-written salt states for re-use. In essense we should treat them as we would external python _distribution packages_ .

	[Salt Formulas](https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html)

		git submodule add [https://github.com/saltstack-formulas/locale-formula](https://github.com/saltstack-formulas/locale-formula) srv/formulas/locale
		git submodule add [https://github.com/saltstack-formulas/timezone-formula](https://github.com/saltstack-formulas/timezone-formula) srv/formulas/timezone
		git submodule add [https://github.com/saltstack-formulas/hostsfile-formula](https://github.com/saltstack-formulas/hostsfile-formula) srv/formulas/hostsfile
		git submodule add [https://github.com/saltstack-formulas/openssh-formula](https://github.com/saltstack-formulas/openssh-formula) srv/formulas/openssh
		git submodule add [https://github.com/saltstack-formulas/apt-formula](https://github.com/saltstack-formulas/apt-formula) srv/formulas/apt

	When writing your own formula add a FORMULA file which the Salt Package Manager ( [SPM](https://docs.saltstack.com/en/latest/topics/spm/index.html) ) can leverage.

	[FORMULA File](https://docs.saltstack.com/en/latest/topics/spm/spm_formula.html#spm-formula)

	-  _Useful starter commands for working with submodules._ 

			git submodule status
			git fetch --recurse-submodules
			git pull --recurse-submodules 
			git submodule update --recursive

- [ ]  Update `master` to append the formulas to _file_roots_ 

		file_roots:
			base: # Environment. base is the default. 
		 	- srv/salt # path to salt state files
		 - srv/formulas/locale
		 - srv/formulas/timezone
		 - srv/formulas/hostsfile
		 - srv/formulas/openssh
		 - srv/formulas/apt

- [ ]  Configure locale formula
	- [ ]  Append `- locale` to `base:'*'` in `srv/pillar/default/top.sls` 

			# pillar top
			
			base:
			 '*': # available to all minions
			 - network
			 - locale

	- [ ]   `touch srv/pillar/default/locale.sls` to configure the locale formula state.

		By convention the formula's 'pillar.example' file documents a full example configuration. The locale.sls file will be merged with all the other pillar files so the name of the file doesn't really matter expect for consistency and clarity. 

			# pillar locale
			
			locale: 
			 present:
			 - "en_US.UTF-8 UTF-8"
			 - "en_AU.UTF-8 UTF-8" # replace with your own
			 default: 
			 name: 'en_AU.UTF-8' # Note: On debian systems don't write the 
			 # second 'UTF-8' here or you will experience 
			 # salt problems like:
			 # LookupError: unknown encoding: utf_8_utf_8
			 # Restart the minion after you corrected this!
			 requires: 'en_AU.UTF-8 UTF-8' # replace with your own

	- [ ]  Append `- locale` to `base:'*'` in `srv/salt/top.sls` 

			# salt top
			# [https://docs.saltstack.com/en/latest/ref/states/top.html](https://docs.saltstack.com/en/latest/ref/states/top.html) 
			
			base: # environment
			 '*': # match all minions
			 - network
			 - locale
			 'test*': # group to match
			 - utils.etckeeper

- [ ]  Configure timezone state
	- [ ]  Append `- timezone` to `base:'*'` in `srv/pillar/default/top.sls` 
	- [ ]   `touch srv/pillar/default/timezone.sls` 

			timezone:
			 name: 'Australia/Sydney'
			 utc: True

	- [ ]  Append `- timezone` to `base:'*'` in `srv/salt/top.sls` . 
- [ ]  Configure apt.unattended updates
	- [ ]  Append `- apt.unattended` to `base:'*'` in `srv/salt/top.sls` 
	- [ ]  Append `- apt` to `base:'*'` in `srv/pillar/default/top.sls` 
	- [ ]   `touch srv/pillar/default/apt.sls` 

		Previously we've used the _pillar _ context variable now we'll use the _salt _ context to execute a module function from _salt.modules.mod_random._ 

			# pillar apt
			
			{% set random_time_per_minion=salt['random.seed'](59) %}
			apt:
			 unattended:
			 automatic_reboot: true
			 automatic_reboot_time: '02:{{ '%02d'| format(random_time_per_minion) }}'

		The default for Ubuntu unattended updates runs only security updates daily. Mostly Ubuntu can apply updates without rebooting but in the event of a kernel patch that needs a reboot we're erring on the side of security by letting it reboot unattended, but putting in a semi-random time so that if there are multiple hosts they don't all reboot at once.

		We might revisit this later for a more pro-active approach that allows us to intervene.

- [ ]  Configure openssh.config formula state 
	- [ ]  Append `- openssh` to `base:'*'` in `srv/pillar/default/top.sls` 
	- [ ]  Append `- openssh.config` to `base:'*'` in `srv/salt/top.sls` .
	- [ ]   `touch srv/pillar/default/openssh.sls` 

			# pillar openssh
			
			sshd_config:
				PermitRootLogin: 'yes'
			 PasswordAuthentication: 'no'
			 X11Forwarding: 'no'

	- [ ]  Workaround a salt-ssh [issue](https://github.com/saltstack/salt/issues/26585) finding formula jinja templates

		This fixes TemplateNotFound errors when applying any state.

			salt-ssh: 
				config_dir: . 
			 extra_filerefs:
			 	- salt://openssh/map.jinja
			 - salt://openssh/defaults.yaml

## Jinja template logic

There is a firewall module in salt which wraps firewalld. Although firewalld is available for Ubuntu, we're going to configure a simple ufw firewall using some simple jinja template logic because it's simpler to reason about and ufw is already installed by default on Ubuntu.

- [ ]  Configure a firewall
	- [ ]  Append `- firewall` to `base:'*'` in `srv/pillar/default/top.sls` 
	- [ ]   `mkdir srv/salt/firewall` 
	- [ ]   `touch srv/salt/firewall/test.sls srv/salt/firewall/teardown.sls srv/salt/firewall/init.sls` 
	- [ ]  Update `srv/salt/firewall/init.sls` to configure a base unconfigured firewall

			# salt firewall
			
			# pillar.get('network:private_network_interface', None)
			{% set internal_interface = salt['pillar.get'] ('network:private_network_interface') %} # default to None
			{% set internal_network = salt['pillar.get']('network:private_network', 'any') %} # default to 'any'
			{% set public_interface = salt['pillar.get']('network:public_network_interface', 'any') %} # default to 'any'
			
			{% set ssh_sources = salt['pillar.get']('firewall:ssh_sources', []) %}
			
			{% if internal_interface %}
			ufw allow in on ens7 from {{ internal_network }} to any app openssh:
			 cmd.run
			{% endif %}
			
			{% if ssh_sources %}
			{% for source in ssh_sources %}
			ufw allow in on {{ public_interface }} from {{ source }} to any app openssh:
			 cmd.run
			{% endfor %}
			{% else %}
			ufw allow openssh:
			 cmd.run
			{% endif %}
			
			ufw --force enable:
			 cmd.run
			

		The _salt['pillar.get'] _ is basically a chained python _{}.get()_ . For example _pillar.get('network:private_network_interface') _ would be _pillar.get('network', {}).get('private_network_interface')._ 

		The rest of the jinja template should be fairly straightforward.

	- [ ]   `touch srv/pillar/default/firewall.sls` 

		We're configuring a near empty pillar just as a placeholder and to avoid warning messages when there's an actual missing pillar state file. 

		To tighten your security which you should do given that we're logging in as root you would want to add a list of _ssh_sources _ to the firewall pillar.

			# pillar firewall
			
			firewall:
				#- ssh_sources:
			 	#	- 0.0.0.0/24

	- [ ]  Append `- firewall` to `base:'*'` in `srv/salt/top.sls` .

## Minion ids

- [ ]  Optionally add _hostsfile.hostname_ state to `srv/salt/top.sls` 

	By default the minion id is derived from the fully qualified domain name (fqdn) of the host. It's better practice however to set the minion id manually. In _salt-ssh_ the roster file determines the minion id and this state just sets the hostname to match it.

		# salt top
		# [https://docs.saltstack.com/en/latest/ref/states/top.html](https://docs.saltstack.com/en/latest/ref/states/top.html) 
		
		base: # environment
		 '*': # match all minions
		 - network
		 - locale
		 - timezone
		 - apt.unattended
		 - openssh.config
		 - firewall
		 - hostsfile.hostname
		 
		 'test*': # group to match
		 - utils.etckeeper

- [ ]  Test the combined state.

		salt-ssh '*' state.apply test=true

- [ ]  Apply the new high state.

		salt-ssh '*' state.apply

## Summary

At this point we have created a project that can bootstrap a baseline host that could be applied to any project with everything under version control. The salt concepts you should now have a basic understanding of are:

- writing and testing salt _ state files_ 
- serving state files to minions
- using _salt state modules _ in state files
- salt _top_ files
- formulas
- using and testing _pillars_ 
- pillar _top_ files
- external pillars 
- using basic Jinja templating in state files
- how minion ids are set

At this point you should be able to use your repository as the basis for your own _ salt-ssh_ project.
# Part 2 - Creating a Baseline Environment

08/04/2016

- [ ]  Create the directories we will require.

		mkdir -p srv/salt srv/formulas srv/pillar srv/pillar-minion/hosts/salt1.example.com

## State Files

- [ ]   `touch srv/salt/packaging.sls` state file to install all the package management packages we might need in the order we want.

	Salt state (.sls) files allow you to execute a series of python module functions from _salt.states_ and provide arguments to those functions but in YAML instead of python. In this simple example they will be executed in the order they are declared.

		# [https://docs.saltstack.com/en/latest/ref/states/writing.html](https://docs.saltstack.com/en/latest/ref/states/writing.html) 
		
		# the short form for calling a python module function
		# Ubuntu 16.04 pip needs python-setuptools for some packages
		python-setuptools: # globally unique id and name argument
			pkg.installed # salt module.function
		# equivalent of salt.states.pkg.installed('python-setuptools')
		
		# the preferred longer form 
		enable_saltstack_to_install_python-pip_packages: # globally unique id
			pkg.installed: # salt module.function
		 	- name: python-pip # name argument
		 
		enable_saltstack_to_add_external_apt_packages: 
			pkg.installed:
		 	- name: python-apt

	The longer form is usually preferred because you can describe _why _ you are doing something without needing to comment.

	Just like a public api, ids should not change unless they absolutely have to. 

	[How Do I Use Salt States?](https://docs.saltstack.com/en/latest/topics/tutorials/starting_states.html)

	The biggest issues with this state file is that it is Ubuntu specific and has a workaround for a specific version of Ubuntu. Later on we'll look at how you might improve that. 

## File Serving

- [ ]  Append to `./master` the config for the Salt File Server _file_roots_ . 

	Salt can find state files in one or more _file_roots _ and _ _ serve them to minions for execution. 

		file_roots:
			base: # Environment. base is the default. 
		 	- srv/salt # path to salt state files

	You can have multiple environments (dev, staging etc) but git branches may be better for this?

## Testing State Files

- [ ]  Test the packaging state file.

	Some essential test commands from the _salt.modules.state_ module _ _ that test the states on the targeted hosts.

		salt-ssh '*' state.show_sls packaging # validate the sls
		
		salt-ssh '*' state.apply test=True packaging # test apply packaging. 
		# Can also add comma separated additional state files to apply

	Update master to set _failhard: True _ to stop execution at the first failed state, and _state_verbose: False _ to show only changed or failed states.

	But what about actual unit and integration tests?

	Running a state file bears surface similarity with an integration test. Each function passes or fails and is summarised at the end of the run. What's missing is setup, teardown, and a full test runner. We'll come back to those later.

## Salt Top File

- [ ]   `touch srv/salt/top.sls` file.

	The top file is a special state file that maps states to minions so we don't need to apply everything manually.

		# salt/top
		# [https://docs.saltstack.com/en/latest/ref/states/top.html](https://docs.saltstack.com/en/latest/ref/states/top.html) 
		
		base: # environment
			'*': # target all
		 	- packaging # single sls state file 

	[The Top File](https://docs.saltstack.com/en/latest/ref/states/top.html)

	- [ ]  Apply the top file state to the host

			salt-ssh '*' state.apply
			
			# other useful commands
			salt-ssh '*' state.show_highstate # high level alphabetical overview of what will be executed
			salt-ssh '*' state.show_lowstate # low level execution order view
			salt-ssh '*' state.apply packaging # execute one or more comma separated state files

## Formulae

- [ ]  Add external formula for locale, timezone, hostname, and openssh.

	Salt _formula_ are simply pre-written salt states for re-use. In essense we should treat them as we would external python packages. 

	[Salt Formulas](https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html)

		git submodule add [https://github.com/saltstack-formulas/locale-formula](https://github.com/saltstack-formulas/locale-formula) srv/formulas/locale
		git submodule add [https://github.com/saltstack-formulas/timezone-formula](https://github.com/saltstack-formulas/timezone-formula) srv/formulas/timezone
		git submodule add [https://github.com/saltstack-formulas/hostsfile-formula](https://github.com/saltstack-formulas/hostsfile-formula) srv/formulas/hostsfile
		git submodule add [https://github.com/saltstack-formulas/openssh-formula](https://github.com/saltstack-formulas/openssh-formula) srv/formulas/openssh
		git submodule add [https://github.com/saltstack-formulas/apt-formula](https://github.com/saltstack-formulas/apt-formula) srv/formulas/apt

	When writing your own formula add a FORMULA file which the Salt Package Manager ( [SPM](https://docs.saltstack.com/en/latest/topics/spm/index.html) ) can leverage.

	-  _So why not just use SPM or _ _[gitfs](https://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html)_ _? Why submodules? _ 

		Repositories get deleted, package providers go down, and ideally you want to pin to a tagged release or revision in your requirements. 

		We _could_ use gitfs but at the very least we'd want to fork the repository, and not worry about availability if there is no enterprise agreement; gitfs also has issues to workaround when used with salt-ssh.

		SPM is new so most formula isn't packaged for it and it needs lots of configuration settings when the salt configuraton is not in the default location. Unfortunately I couldn't get it to work at all for the timezone-formula so it was a non-starter.

		Submodules on the other hand are mature, can be pinned to a revision easily and we can store locally (and remotely) and deploy them whole, filtering out the actual .git repository. 

		The pragmatic approach then is to use submodules; create a FORMULA file to leverage spm when it matures, and skip gitfs altogether.

	[FORMULA File](https://docs.saltstack.com/en/latest/topics/spm/spm_formula.html#spm-formula)

	-  _Useful starter commands for working with submodules._ 

			git submodule status
			git fetch --recurse-submodules
			git pull --recurse-submodules 
			git submodule update --recursive

- [ ]  Update `master` to add the formulas to _file_roots_ 

		file_roots:
			base: # Environment. base is the default. 
		 	- srv/salt # path to salt state files
		 - srv/formulas/locale
		 - srv/formulas/timezone
		 - srv/formulas/hostsfile
		 - srv/formulas/openssh
		 - srv/formulas/apt

## Pillars

- [ ]  Append `master` to configure a flat file based pillar.

	Here we introduce another key concept, _pillars_ . Unlike state files which may be blasted out to all minions, pillars are key value stores that hold secrets and other data which may be intended only for specific minion. Where state files are programs, pillars are the settings we want to use to configure those programs.

		# Configuration of a file pillar, pillar_roots is the same as state file_roots.
		pillar_roots:
			base:
		 	- srv/pillar

	[Pillar Walkthrough](https://docs.saltstack.com/en/latest/topics/tutorials/pillar.html)

	Pillars are pluggable so other services could also provide the key, value pairs, such as [vault](https://www.vaultproject.io) .

- [ ]   `touch srv/pillar/top.sls` 

	Just like salt tops, pillar has a top as well that determines what pillar files are merged to a single key value store.

		# pillar/top
		
		base:
		 '*':
		 - locale

- [ ]   `touch srv/pillar/locale.sls` to configure the locale formula state.

	By convention the formula's pillar.example file should give a full example configuration. The locale.sls file will be merged with all the other pillar files so the name of the file doesn't really matter expect for consistency and clarity. 

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

	- [ ]  View the key value items to ensure you they are configured as expected

			salt-ssh '*' pillar.items
			# get a specific value
			salt-ssh '*' pillar.get locale:default:name

- [ ]  Append `- locale` to '*' in `srv/salt/top.sls` to use the locale state.

		# salt/top
		# [https://docs.saltstack.com/en/latest/ref/states/top.html](https://docs.saltstack.com/en/latest/ref/states/top.html) 
		
		base: # environment
		 '*': # target all
		 - packaging # single sls state file
		 - locale

- [ ]  Configure timezone state
	- [ ]   `touch srv/pillar/timezone.sls` 

			timezone:
			 name: 'Australia/Sydney'
			 utc: True

	- [ ]  Append `- timezone` to '*' in `srv/salt/top.sls` . 

			base: # environment
				'*': # target all
			 	- packaging # single sls state file
			 - locale
			 - timezone

- [ ]  Configure openssh.config formula state 
	- [ ]   `touch srv/pillar/openssh.sls` 

			# View the formula pillar.example for more examples
			sshd_config:
				PermitRootLogin: 'yes'
			 PasswordAuthentication: 'no'
			 X11Forwarding: 'no'

	- [ ]  Append `- openssh.config` to '*' in `srv/salt/top.sls` .
- [ ]  Workaround a salt-ssh [issue](https://github.com/saltstack/salt/issues/26585) finding formula jinja templates

	This fixes TemplateNotFound errors when applying any state.

		salt-ssh: 
			config_dir: . 
		 extra_filerefs:
		 	- salt://openssh/map.jinja
		 - salt://openssh/defaults.yaml

## Jinja Templates

- [ ]   `touch srv/salt/network.sls` 

	By default state files are compiled [jinja](http://jinja.pocoo.org/docs/dev/templates/) templates with some jinja context variables thrown in, the first of which we'll use is the _pillar_ context variable.

	We're going to configure the internal private network interface that the provider offers.

	[Understanding Jinja](https://docs.saltstack.com/en/latest/topics/jinja/index.html)

		# salt/network
		
		{% set network=pillar['network'] %}
		
		{{ network.private_network_interface }}:
		 network.managed:
		 - enabled: true
		 - type: {{ network.type }}
		 - proto: {{ network.proto }}
		 - ipaddr: {{ network.internal_ipaddr }}
		 - netmask: {{ network.netmask }}

	Using _pillar['network'] _ has a weakness; if the key doesn't exist the state file fails when we apply it. There's a way around that we'll use soon, but it's fine for this mandatory setting.

- [ ]  Append `- network` to '*' in `srv/salt/top.sls` .
- [ ]  Append `- network` to '*' in `srv/pillar/top.sls` 
- [ ]   `touch srv/pillar/network.sls` to add the configuration settings

		# pillar/network
		
		network:
		 private_network_interface: ens7
		 type: eth
		 proto: static
		 netmask: 255.255.0.0

	You'll notice I'm missing one; internal_ipaddr. That's because it's a per minion setting. Since pillars get served to all minions, but applied only to the target ones, in some cases - particularly with sensitive data - it's better to serve data only to the targetted minion. 

- [ ]  Append `- apt.unattended` to '*' in `srv/salt/top.sls` 
- [ ]  Append `- apt` to '*' in `srv/pillar/top.sls` 
- [ ]   `touch srv/pillar/apt.sls` 

	Previously we've used the _pillar _ context variable now we'll use the _salt _ context to execute a module function from _salt.modules.mod_random._ 

		# pillar/apt
		
		{% set random_time_per_minion=salt['random.seed'](59) %}
		apt:
		 unattended:
		 automatic_reboot: true
		 automatic_reboot_time: '02:{{ '%02d'| format(random_time_per_minion) }}'

	The default for Ubuntu unattended updates runs only security updates daily. Mostly Ubuntu can apply updates without rebooting but in the event of a kernel patch that needs a reboot we're erring on the side of security by letting it reboot unattended, but putting in a semi-random time so that if there are multiple hosts they don't all reboot at once.

	We might revisit this later for a more pro-active approach.

## External Pillars (file_tree)

- [ ]  Append to `master` the _ext_pillar_ config for _file_tree._ 

		ext_pillar:
		 - file_tree:
		 		# remember the YAML double indent rule of dicts under lists!
		 	root_dir: srv/pillar-minion

	The file_tree pillar module serves directories and their children as key values pairs terminating in a file key with file contents as it's value. It can target hosts or nodegroups and gets merged with other pillars. We could use this pattern to store secrets for individual or groups of hosts, but in this case we'll use it as an overkill method for storing the private ipaddr of the host.

	Note **there is a bug** with hidden binary files like *.DS_store breaking the pillar. Purge them.

- [ ]  Save the internal vm network address from the hosting provider to a file

		echo '[[vm_internal_ip_address]]' > srv/pillar-minion/hosts/salt1.example.com/network/internal_ipaddr
		# pillar['network']['internal_ipaddr'] = 'file content' 

	We can now _state.apply_ if you like.

[pillar modules](https://docs.saltstack.com/en/latest/ref/pillar/all/index.html)

## Requisites

Up to now state files have just been written in the order they execute. Very simple, but salt also has a method to create dependencies between states called requisites. In the simple case we will use here, the _onlyif _ requisite will execute another command first to determine whether the it should execute the state function.

- [ ]   `touch srv/salt/firewall.sls` 

	If you'd looked at some of the formula we've used, state files and other configuration files can be templates that are compiled before evaluation. Here we will use a template to configure a simple firewall. 

		# salt/firewall.sls
		
		# Firewalld rules are applied in the following layered order:
		
		# 1. Direct rules (Not implemented)
		# 2. Source address based zone
		# 3. Interface based zone
		# 4. Default zone
		
		# For each of the iptables chains allow/deny/log the priority is:
		# - Rich rule (Not implemented)
		# - Port definition
		# - Service definition
		
		remove_all_ufw_iptable_rules_and_disable: 
		 cmd.run: 
		 - name: 'ufw --force reset'
		 - onlyif: # dynamically altering state with requisite functions
		 - ufw status # Error or false means ufw —force reset doesn't run 
		
		remove_ufw:
		 pkg.removed:
		 - name: ufw
		
		install_firewalld:
		 pkg.installed:
		 - name: firewalld
		
		start_firewalld:
		 service.running:
		 - name: firewalld
		 - enable: true
		
		# an interface can be bound to a single zone
		trust_loopback_interface:
		 firewalld.bind:
		 - name: trusted
		 - interfaces:
		 - lo
		# Jinja set variable using salt context and default [] if the pillar keys don't exist. 
		{% set ssh_sources = salt['pillar.get']('firewall:ssh', []) %}
		# Note the Jinja comment syntax. This code would produce an error with missing pillar keys.
		{# {% set ssh_sources = pillar['firewall']['ssh'] %} #}
		
		# one or more sources can be bound to a single firewalld zone 
		{% if ssh_sources %}
		bind_sources_to_ssh_zone:
		 firewalld.bind:
		 - name: ssh
		 - sources:
		 {% for source in ssh_sources %}
		 - {{ source }}
		 {% endfor %}
		allow_ssh_in_ssh_zone:
		 firewalld.present:
		 - name: ssh
		 - services: 
		 - ssh
		{% endif %}
		
		set_default_zone:
		 firewalld.present:
		 - name: public # zone
		 - block_icmp:
		 - echo-reply
		 - echo-request
		 - default: true # —set-default-zone
		{% if not ssh_sources %}
		 - services:
		 - ssh
		{% endif %}

	Note the _pillar.get _ which operates as you'd expect from python and allows us to set a default if we prefer.

	[Requisites and Other Global State Arguments](https://docs.saltstack.com/en/latest/ref/states/requisites.html)

- [ ]  Append `- firewall` to '*' in `srv/salt/top.sls` .

## Minion ids

- [ ]  Optionally add _hostsfile.hostname_ state to `srv/salt/top.sls` 
	-  _Setting a hostname isn't strictly necessary._ 

			base: # environment
			 '*': # target all
			 - packaging # single sls state file
			 - locale
			 - timezone
			 - hostsfile.hostname

	By default the minion id is derived from the fully qualified domain name (fqdn) of the host. It's better practice however to set the minion id manually. In _salt-ssh_ the roster file determines the minion id and this state just sets the hostname to match it.

- [ ]  Test the combined state.

		salt-ssh '*' state.apply test=true

- [ ]  Apply the new state.

		salt-ssh '*' state.apply

## Summary

At this point we have created a project that can bootstrap a baseline host that could be applied to any project with everything under version control. The salt concepts you should now have a basic understanding of are:

- writing and testing salt _ state files_ 
- serving state files to hosts
- using _salt states modules _ in state files
- salt _top_ files
- formula state files
- using and testing _pillars_ 
- external pillars 
- using basic Jinja templating in state files
- the salt _ requisite _ system
- how minion ids are set

At this point you should be able to use your repository as the basis for your own _ salt-ssh_ project.
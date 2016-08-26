# Part 3 - Installing a masterless minion

08/04/2016

The salt docs say that "running a masterless salt-minion lets you use Salt's configuration management for a single machine without calling out to a Salt master on another machine".

A masterless minion can be used as the basis for a scaled out architecture.

## Grains

- [ ]   `mkdir -p srv/salt/pre_seed_minion/templates` 
- [ ]   `touch srv/salt/pre_seed_minion/templates/minion.yml` config file

		# minion configuration
		
		{% if salt['pillar.get']('masterless', True) %}
		file_client: local # default 'remote'
		{% endif %}
		
		id: {{ grains['id'] }} # defining it in config is more reliable than relying on the default fqdn which 'could' change.

	Grains are facts about the target system from multiple sources. We want the minion id. The id would normally be the minion id collected on the target from the minion configuration file but in this case the the roster is merged with the target to create the grains. With this approach we can avoid the chicken & egg problem of setting the minon id and demonstrate that grains can be set by sources other than the target.

	[Grains](https://docs.saltstack.com/en/latest/topics/grains/index.html)

	- [ ]  Use salt.modules.grains commands to view system grains

			salt-ssh '*' grains.items
			salt-ssh '*' [grains.ls](http://grains.ls) 
			salt-ssh '*' grains.item os_family osfullname

## Pre-seeding minions

When a minion starts up the first time it will autocreate a keypair to use for encryption and security. If we were using a master this key would need to be accepted by the master with salt-key before jobs could be issued to the minion. Pre-seeding will allow us to skip the acceptance step.

- [ ]  Append `saltfile` to set commandline options for `salt-key` 

	We are going to u _se salt-key _ to create keypair _s to _ pre-seed the minion key _. _ s _alt-key _ run by itself on a daemon master principally allows the master to accept keys from minions asking to connect to it. Pre-seeding will ensure our minion does not create it's own keys that we don't have control over. 

	The saltfile can be configured for salt commands other than salt-ssh.

		salt-key:
		 config_dir: .
		 gen_keys_dir: srv/pillar/files/hosts/salt1.example.com/files/ssh

	We use this specific _gen_keys_dir_ because we want to make them available as variables later.

	[Preseed Minion with Accepted Key](https://docs.saltstack.com/en/latest/topics/tutorials/preseed_key.html)

- [ ]  Create a minion keypair to pre-seed the master

		salt-key --gen-keys=test-salt1.example.com

- [ ]  Append to the `master` conf file a keep_newline option.

	The other file_tree pillar we used as a simple source of secrets, this one we want to use to deploy whole files so we add the _keep_newline_ option.

		# [https://docs.saltstack.com/en/latest/ref/configuration/master.html#ext-pillar](https://docs.saltstack.com/en/latest/ref/configuration/master.html#ext-pillar) 
		ext_pillar:
		 - file_tree:
		 # remember the YAML double indent rule of dicts under lists!
		 root_dir: srv/pillar/minion
		 keep_newline: 
		 	- files/*
		 

	- [ ]  View the pillar items for salt1 which should contain the minion key.

			salt-ssh '*' pillar.items
			salt-ssh '*' pillar.get files:ssh

- [ ]   `touch srv/salt/pre_seed_minion/init.sls` to pre-seed the keys and deploy the minion config.

		# salt minion
		
		/etc/salt/pki/minion:
		 file.directory:
		 - mode: '0700'
		 - makedirs: True
		
		pre-seed minion public key once only:
		 file.managed:
		 - name: /etc/salt/pki/minion/minion.pub
		 - contents_pillar: files:ssh:{{ grains['id'] }}.pub
		 - replace: false
		 - unless:
		 - ls /etc/salt/pki/minion/minion.pub
		
		pre-seed minion private key once only:
		 file.managed:
		 - name: /etc/salt/pki/minion/minion.pem
		 - mode: '0600'
		 - contents_pillar: files:ssh:{{ grains['id'] }}.pem
		 - replace: false
		 - unless:
		 - ls /etc/salt/pki/minion/minion.pem
		
		deploy the minion configuration: 
		 file.managed:
		 - name: /etc/salt/minion
		 - source: salt://pre_seed_minion/templates/minion.yml
		 - template: jinja
		 

- [ ]   `touch srv/salt/pre_seed_minion/teardown.sls` 

		# salt minion.teardown
		
		teardown /etc/salt/pki/minion:
		 file.absent:
		 - name: /etc/salt/pki/minion
		
		teardown /etc/salt/minion:
		 file.absent:
		 - name: /etc/salt/minion

- [ ]  Append `pre_seed_minion` to `base:'*-salt*'` in `srv/salt/top.sls` .

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
		 
		 '*-salt*': # $masterless
		 - pre_seed_minion
		 
		 'test*': # group to match
		 - utils.etckeeper

- [ ]   `export masterless='*-salt*'` 

	I am using the method described [here](http://stackoverflow.com/questions/19331497/set-environment-variables-from-file/34093548#34093548) to hold environment variables to simplify targeting groups.

- [ ]  Clone the official salt-formula [https://github.com/saltstack-formulas/salt-formula](https://github.com/saltstack-formulas/salt-formula) as a submodule

		git submodule add [https://github.com/saltstack-formulas/salt-formula](https://github.com/saltstack-formulas/salt-formula) srv/formulas/salt

	- [ ]  Edit the `saltfile` and add _extra_filerefs _ for _ _ the _ _ salt formula _ _ (a workaround for [this bug](https://github.com/saltstack/salt/issues/19564) ) _._ 

			# [https://docs.saltstack.com/en/latest/topics/ssh/#define-cli-options-with-saltfile](https://docs.saltstack.com/en/latest/topics/ssh/#define-cli-options-with-saltfile) 
			
			salt-ssh:
			 config_dir: .
			 extra_filerefs:
			 - salt://openssh/map.jinja
			 - salt://openssh/defaults.yaml
			 - salt://salt/formulas.jinja
			
			salt-key:
			 config_dir: .
			 gen_keys_dir: srv/pillar/files/hosts/test-salt1.example.com/files/ssh

- [ ]  Update the `master` _ file_roots: base _ config to add the salt-formula.

		file_roots:
		 base: # Environment. base is the default. 
		 - srv/salt # path to a package distribution
		 - srv/formulas/locale
		 - srv/formulas/timezone
		 - srv/formulas/hostsfile
		 - srv/formulas/openssh
		 - srv/formulas/apt
		 - srv/formulas/salt

## Requsites, State Order & Include

- [ ]  Create a package to wrap salt.minion and salt.pkgrepo

	To get the current salt.minion we need salt.pkgrepo, and to install pkgrepo we need to install a dependency, python-apt. The cleanest way to manage the dependency is to use the _require_in_ requisite.

	Requisites are the prime method for executing state functions out of declaration order. 

	[Requisites and Other Global State Arguments](https://docs.saltstack.com/en/latest/ref/states/requisites.html)

	- [ ]   `mkdir srv/salt/local_salt_minion` 
	- [ ]   `touch srv/salt/local_salt_minion/init.sls` 

			# salt local_salt_minion
			
			include: # execute recursively
			 - salt.pkgrepo # execute first 
			# 'salt.pkgrepo.ubuntu' included by salt.pkgrepo is executed second
			 - salt.minion # execute third
			
			python-apt: # execute fourth
			 pkg.installed:
			 - require_in:
			 - pkgrepo: saltstack-pkgrepo

		 _Include_ is the state file equivalent of a python import. The key difference to python import is that because state files are ordered for execution, the include always comes first, with the exception o requisite functions.

	- [ ]   `touch srv/salt/local_salt_minion/test.sls` 

			# salt local_salt_minion.test
			
			include:
			 - local_salt_minion
			 - local_salt_minion.teardown

		One thing to note with this test is that the minion service fails when you run the test but not if you run the state files separately.

	- [ ]   `touch srv/salt/local_salt_minion/teardown.sls` 

			# salt local_salt_minion.teardown
			{% from "salt/map.jinja" import salt_settings with context %}
			
			include:
			 - salt.pkgrepo.absent
			
			local_purge_python-apt:
			 pkg.purged:
			 - name: python-apt
			
			purge_salt-minion:
			 pkg.purged:
			 - name: {{ salt_settings.salt_minion }}
			 file.absent:
			 - name: {{ salt_settings.config_path }}/minion.d

	- [ ]   _View _ the order of execution with `salt-ssh $masterless` `state.show_low_sls local_salt_minion` . 
- [ ]  Update `base:'*-salt*` in `srv/salt/top.sls` to append `local_salt_minion` .

		 '*-salt*': # $masterless
		 - pre_seed_minion
		 - local_salt_minion

- [ ]  Test the combined state.

		salt-ssh $masterless state.apply test=true

	You might have a few red errors when testing because pre-requisites to be applied are further up the list. As long as those pre-requisites test ok then you should be all good. 

- [ ]  Apply the new state.

		salt-ssh $masterless state.apply

- [ ]  Login to your new masterless minion and test it.

		ssh test.s1.ex
		salt-call test.ping

	The _salt-call _ command is the command run on the minion regardless of whether it's a standalone minion, recipient of a salt-ssh command or taking jobs from a master. 

- [ ]   `touch srv/salt/project/init.sls` 

		# salt selfservice
		
		{% set projectname = pillar['project']['name'] %}
		{% set branch = salt['pillar.get']('project:branch', 'master') %}
		
		install pygit2 and dependencies:
		 pkg.installed:
		 - name: libgit2-24
		 - name: pygit2
		
		/srv/git:
		 file.directory:
		 - makedirs: true 
		
		/srv/releases:
		 file.directory:
		 - makedirs: true
		
		create the bare repo to push to:
		 git.present:
		 - name: /srv/git/{{ projectname }}
		 - bare: true

- [ ]   `touch /srv/pillar/project.sls` 

		# pillar project
		
		project: 
		 name: [salt.example.com](http://salt.example.com) 

- [ ]   `touch srv/salt/project/deploy.sls` 

		# salt project.deploy
		
		{% set projectname = pillar['project']['name'] %}
		
		{% if salt['pillar.get']('masterless', True) %}
		create the clone that pulls from the bare repo:
		 git.latest:
		 - name: /srv/git/{{ projectname }}
		 - target: /srv/releases/{{ projectname }}
		 - submodules: true
		 - force_reset: true
		 - depth: 1
		{% endif %}

- [ ]  Update `srv/salt/pre_seed_minion/templates/minion` 

		# minion configuration
		
		id: {{ grains['id'] }} # defining it in config is more reliable than relying on the default fqdn which 'could' change.
		
		{% set srv = ['/srv/releases/', pillar['project']['name'], '/srv']|join %} 
		
		{% if salt['pillar.get']('masterless', True) %}
		file_client: local # default 'remote'
		
		file_roots:
		 base: # Environment. base is the default. 
		 - {{srv}}/salt # path to a package distribution
		 - {{srv}}/formulas/locale
		 - {{srv}}/formulas/timezone
		 - {{srv}}/formulas/hostsfile
		 - {{srv}}/formulas/openssh
		 - {{srv}}/formulas/apt
		 - {{srv}}/formulas/salt
		
		pillar_roots:
		 base:
		 - {{srv}}/pillar/default
		
		ext_pillar:
		 - file_tree:
		 # remember the YAML double indent rule of dicts under lists!
		 root_dir: {{srv}}/pillar/files
		 keep_newline:
		 - files/*
		
		{% endif %}

- [ ]   `$ salt-ssh $masterless state.apply` 
- [ ]  Add a remote to your project and for simplicity we will make it only track the master branch.

		$ git remote add -t master -m master test-s1-ex ssh://test.s1.ex/srv/git/salt.example.com

- [ ]  Push your current branch to init the remote repository

		$ git push test-s1-ex HEAD:master

- [ ]  Deploy (clone) the remote to the desired dir.

		$ salt-ssh $masterless state.apply project.deploy 

## Salt-call

Regardless of whether we're using a master or salt-ssh, _salt-call _ is what will execute the state functions on the minion. The primary difference is that salt-ssh uses a thin agentless installation whereas a minion has a daemon agent.

- [ ]  Login to the minion and test apply with _salt-call_ 

		$ ssh test.s1.ex
		$ salt-call state.apply test=true

## Summary

Although we could survive just with _salt-ssh_ , creating a minion daemon could be the basis for a scaled out masterless architecture. We used a local git repository to push to but with a little modification we could auto-deploy from a remote with cron.

At this point we have created a project that can bootstrap a standalone masterless minion with salt-ssh and have everything under version control. 

The additional salt concepts you should now have a basic understanding of are:

- using system facts ( _grains)_ 
-  _pre-seeding _ minions
-  _requisites_ 
- the _salt-call_ command

It's time to convert our masterless minion into a full master.
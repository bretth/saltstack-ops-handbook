# salt top
# https://docs.saltstack.com/en/latest/ref/states/top.html

base:  # environment
  '*': # match all minions
    - network
    - locale
    - timezone
    - apt.unattended
    - openssh.config
    - firewall
  
  '*-salt*':  # $masterless
     - pre_seed_minion
     - project
     - local_salt_minion
     
  'test*':  # group to match
    - utils.etckeeper



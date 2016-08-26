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

  'test*':
    - utils.etckeeper
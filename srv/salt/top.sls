# salt/top
# https://docs.saltstack.com/en/latest/ref/states/top.html

base:  # environment
  '*': # match all minions
    - network
  test:  # group to match
    - match: nodegroup  # required for nodegroups
    - local.utils.etckeeper
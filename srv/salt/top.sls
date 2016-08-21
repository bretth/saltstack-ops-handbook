# salt/top
# https://docs.saltstack.com/en/latest/ref/states/top.html

base:  # environment
  test:  # group
    - match: nodegroup  # this means we match a group
    - local.utils.etckeeper
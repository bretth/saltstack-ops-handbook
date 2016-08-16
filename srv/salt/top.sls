# salt/top
# https://docs.saltstack.com/en/latest/ref/states/top.html

base:  # environment
  '*':  # target all
    - packaging # single sls state file

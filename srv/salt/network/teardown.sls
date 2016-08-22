# salt/example-com/network

# teardown
/etc/network/interfaces:
  file.copy:
    - source: /etc/network/interfaces.orig
    - preserve: true
    - force: true

ip addr flush ens7:
  cmd.run



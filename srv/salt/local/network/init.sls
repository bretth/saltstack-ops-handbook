# salt/example-com/network

# setup
/etc/network/interfaces.orig:
  file.copy:
    - source: /etc/network/interfaces
    - preserve: true

ens7:
  network.managed:
    - enabled: true
    - type: eth
    - proto: static
    - ipaddr: 10.99.0.11  # your private ip
    - netmask: 255.255.0.0  # your netmask
    - mtu: 1450  # provider recommended mtu
    - check_cmd:
        - "ifconfig ens7 | grep 'inet addr:10.99.0.11'"
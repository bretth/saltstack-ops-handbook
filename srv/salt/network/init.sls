# salt local.network

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
# salt/network

# network = pillar.get('network')
{% set network=pillar['network'] %}

{{ network.private_network_interface }}:
  network.managed:
    - enabled: true
    - type: {{ network.type }}
    - proto: {{ network.proto }}
    - ipaddr: {{ network.internal_ipaddr }}
    - netmask: {{ network.netmask }}
# salt firewall.teardown

{% set internal_interface = salt['pillar.get']('network:private_network_interface') %}
{% set internal_network = salt ['pillar.get']('network:private_network', 'any') %}
{% set public_interface = salt['pillar.get']('network:public_network_interface', 'any') %}

{% set ssh_sources = salt['pillar.get']('firewall:ssh_sources', []) %}


# default to allow openssh
teardown ufw allow openssh:
  cmd.run:
    - name: ufw allow openssh

{% if internal_interface %}
ufw delete allow in on ens7 from {{ internal_network }} to any app openssh:
  cmd.run
{% endif %}

{% if ssh_sources %}
{% for source in ssh_sources %}
ufw delete allow in on {{ public_interface }} from {{ source }} to any app openssh:
  cmd.run
{% endfor %}
{% endif %}


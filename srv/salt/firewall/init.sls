# salt firewall

{% set internal_interface = salt['pillar.get'] ('network:private_network_interface') %}  # default to None
{% set internal_network = salt ['pillar.get']('network:private_network', 'any') %}  # default to 'any'
{% set public_interface = salt['pillar.get']('network:public_network_interface', 'any') %} # default to 'any'

{% set ssh_sources = salt['pillar.get']('firewall:ssh_sources', []) %}

{% if internal_interface %}
ufw allow in on ens7 from {{ internal_network }} to any app openssh:
  cmd.run
{% endif %}

{% if ssh_sources %}
{% for source in ssh_sources %}
ufw allow in on {{ public_interface }} from {{ source }} to any app openssh:
  cmd.run
{% endfor %}
{% else %}
# default to limit openssh
ufw allow openssh:
  cmd.run
{% endif %}

ufw --force enable:
  cmd.run



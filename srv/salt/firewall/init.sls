# salt firewall


# Jinja set variable using salt context and default similar to python dict get but for key trees
{% set internal_interface = salt['pillar.get']('network:private_network_interface') %}
{% set internal_network = salt ['pillar.get']('network:private_network', 'any') %}
{% set public_interface = salt['pillar.get']('network:public_network_interface', 'any') %}

{% set ssh_sources = salt['pillar.get']('firewall:ssh_sources', []) %}

{% if internal_interface %}
ufw allow in on ens7 from {{ internal_network }} to any app openssh:
  cmd.run
{% endif %}

# ufw  [--dry-run]  [rule]  [delete]  [insert NUM] allow|deny|reject|limit [in|out [on INTERFACE]] [log|log-all] [proto PROTOCOL] [from ADDRESS [port PORT | app APPNAME ]] [to ADDRESS
#       [port PORT | app APPNAME ]] [comment COMMENT]
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



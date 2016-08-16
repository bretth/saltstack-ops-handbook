# salt/firewall.sls

# Firewalld rules are applied in the following layered order:

# 1. Direct rules (Not implemented)
# 2. Source address based zone
# 3. Interface based zone
# 4. Default zone

# For each of the iptables chains allow/deny/log the priority is:
#   - Rich rule (Not implemented)
#   - Port definition
#   - Service definition

remove_all_ufw_iptable_rules_and_disable: 
  cmd.run: 
    - name: 'ufw --force reset'
    - onlyif:  # dynamically altering state with requisite functions
      - ufw status  # Error or false means ufw —force reset doesn't run 

remove_ufw:
  pkg.removed:
    - name: ufw

install_firewalld:
  pkg.installed:
    - name: firewalld

start_firewalld:
  service.running:
    - name: firewalld
    - enable: true

# an interface can be bound to a single zone
trust_loopback_interface:
  firewalld.bind:
    - name: trusted
    - interfaces:
      - lo
# Jinja set variable using salt context and default [] if the pillar keys don't exist. 
{% set ssh_sources = salt['pillar.get']('firewall:ssh', []) %}
# Note the Jinja comment syntax. This code would produce an error with missing pillar keys.
{# {% set ssh_sources = pillar['firewall']['ssh'] %} #}

# one or more sources can be bound to a single firewalld zone 
{% if ssh_sources %}
bind_sources_to_ssh_zone:
   firewalld.bind:
     - name: ssh
     - sources:
  {% for source in ssh_sources %}
       - {{ source }}
  {% endfor %}
allow_ssh_in_ssh_zone:
  firewalld.present:
    - name: ssh
    - services: 
      - ssh
{% endif %}

set_default_zone:
 firewalld.present:
    - name: public # zone
    - block_icmp:
      - echo-reply
      - echo-request
    - default: true  # —set-default-zone
{% if not ssh_sources %}
    - services:
        - ssh
{% endif %}
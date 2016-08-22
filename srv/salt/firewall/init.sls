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



# salt local_salt_minion.teardown
{% from "salt/map.jinja" import salt_settings with context %}

include:
  - salt.pkgrepo.absent

local_purge_python-apt:
  pkg.purged:
    - name: python-apt

purge_salt-minion:
  pkg.purged:
    - name: {{ salt_settings.salt_minion }}
  file.absent:
    - name: {{ salt_settings.config_path }}/minion.d
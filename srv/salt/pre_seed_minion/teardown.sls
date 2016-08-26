# salt minion.teardown

teardown /etc/salt/pki/minion:
  file.absent:
    - name: /etc/salt/pki/minion

teardown /etc/salt/minion:
  file.absent:
    - name: /etc/salt/minion
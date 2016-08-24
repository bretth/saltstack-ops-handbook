# salt local_salt_minion

include:
  - salt.pkgrepo
  - salt.minion

python-apt:
  pkg.installed:
    - require_in:
      - pkgrepo: saltstack-pkgrepo
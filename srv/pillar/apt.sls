# pillar/apt

{% set random_time_per_minion=salt['random.seed'](59) %}
apt:
  unattended:
    automatic_reboot: true
    automatic_reboot_time: '02:{{ '%02d'| format(random_time_per_minion) }}'

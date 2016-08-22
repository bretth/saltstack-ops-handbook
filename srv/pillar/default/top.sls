# pillar top

base:
  '*':  # available to all minions
    - network
    - locale
    - timezone
    - apt
    - openssh

# salt project.deploy

{% set projectname = pillar['project']['name'] %}
{% set branch = salt['pillar.get']('project:branch', 'master') %}

{% if salt['pillar.get']('masterless', True) %}
create the clone that pulls from the bare repo:
  git.latest:
    - name: /srv/git/{{ projectname }}
    - target: /srv/releases/{{ projectname }}
    - submodules: true
    - force_reset: true
    - depth: 1
{% endif %}
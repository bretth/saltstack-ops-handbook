# salt selfservice

{% set projectname = pillar['project']['name'] %}

/srv/git:
  file.directory:
    - makedirs: true 

/srv/releases:
  file.directory:
    - makedirs: true

create the bare repo to push to:
  git.present:
    - name: /srv/git/{{ projectname }}
    - bare: true


# salt selfservice

{% set projectname = pillar['project']['name'] %}

install pygit2 and dependencies:
  pkg.installed:
    - name: libgit2-24
    - name: python-pygit2

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


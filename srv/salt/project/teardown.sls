# salt selfservice.teardown

teardown pygit2:
  pkg.purged:
    - name: libgit2-24
    - name: python-pygit2

teardown /srv/git:
  file.absent:
    - name: /srv/git

teardown /srv/releases:
  file.absent:
    - name: /srv/releases

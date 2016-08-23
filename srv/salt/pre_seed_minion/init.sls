# salt minion

/etc/salt/pki:
  file.directory:
    - makedirs: True

/etc/salt/pki/minion:
  file.directory:
    - mode: '0700'

pre-seed minion public key:
  file.managed:
    - name: /etc/salt/pki/minion/minion.pub
    - contents_pillar: files:ssh:{{ grains['id'] }}.pub
    - makedirs: True

pre-seed minion key:
  file.managed:
    - name: /etc/salt/pki/minion/minion.pem
    - contents_pillar: files:ssh:{{ grains['id'] }}.pem
    - makedirs: True

/etc/salt/minion: 
  file.managed:
    - source: salt://pre_seed_minion/templates/minion
    - template: jinja
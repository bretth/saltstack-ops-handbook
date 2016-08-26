# salt minion

/etc/salt/pki/minion:
  file.directory:
    - mode: '0700'
    - makedirs: True

pre-seed minion public key once only:
  file.managed:
    - name: /etc/salt/pki/minion/minion.pub
    - contents_pillar: files:ssh:{{ grains['id'] }}.pub
    - replace: false
    - unless:
      - ls /etc/salt/pki/minion/minion.pub

pre-seed minion private key once only:
  file.managed:
    - name: /etc/salt/pki/minion/minion.pem
    - mode: '0600'
    - contents_pillar: files:ssh:{{ grains['id'] }}.pem
    - replace: false
    - unless:
      - ls /etc/salt/pki/minion/minion.pem

deploy the minion configuration: 
  file.managed:
    - name: /etc/salt/minion
    - source: salt://pre_seed_minion/templates/minion.yml
    - template: jinja

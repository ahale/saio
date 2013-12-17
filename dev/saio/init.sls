corepkgs:
  pkg.installed:
    - skip_verify: True
    - pkgs:
      - curl
      - gcc
      - memcached
      - rsync
      - sqlite3
      - xfsprogs
      - git-core
      - libffi-dev
      - python-setuptools
      - python-coverage
      - python-dev
      - python-nose
      - python-simplejson
      - python-xattr
      - python-eventlet
      - python-greenlet
      - python-pastedeploy
      - python-netifaces
      - python-pip
      - python-dnspython
      - python-mock

{{ pillar['swift_user'] }}:
  group.present:
    - system: False
  user.present:
    - groups:
      - {{ pillar['swift_user'] }}
    - remove_groups: False
    {% if pillar['swift_user'] == "swift" %}
    - home: /srv/swift
    {% endif %}

/etc/sudoers:
  file.sed:
    - before: '^.*%sudo.*'
    - after: '%sudo ALL=NOPASSWD: ALL'

{% for n in range(1, (pillar['storage_zones'] + 1)) %}
/srv/{{ n }}/node/sda:
  loopbackdisk.xfs:
    - mount: /srv/{{ n }}/node/sda
    - path: /mnt/z{{ n }}.disk

  mount.mounted:
    - device: /mnt/z{{ n }}.disk
    - fstype: xfs
    - opts: loop,noatime,nodiratime,nobarrier,logbufs=8
    - persist: True
    - mkmnt: True

  file.directory:
    - user: {{ pillar['swift_user'] }}
    - group: {{ pillar['swift_user'] }}
    - watch:
      - mount: /srv/{{ n }}/node/sda

{% endfor %}

/srv/swift:
  file.directory:
    - user: {{ pillar['swift_user'] }}
    - group: {{ pillar['swift_user'] }}
    - mode: 755

/var/run/swift:
  file.directory:
    - user: {{ pillar['swift_user'] }}
    - group: {{ pillar['swift_user'] }}
    - mode: 755

{% for n in range(1, (pillar['storage_zones'] + 1)) %}
/var/cache/swift{{ n }}:
  file.directory:
    - user: {{ pillar['swift_user'] }}
    - group: {{ pillar['swift_user'] }}
    - mode: 755
    - mkdirs: True
{% endfor %}

/etc/cron.d/swift-recon-cron:
  file.managed:
    - source: salt://etc/cron.d/swift-recon-cron
    - template: jinja

/etc/default/rsync:
  file.managed:
    - source: salt://etc/default/rsync

/etc/rsyncd.conf:
  file.managed:
    - source: salt://etc/rsyncd.conf
    - template: jinja

rsync:
  service:
    - running
    - enable: True
    - watch:
      - file: /etc/rsyncd.conf

/etc/memcached.conf:
  file.managed:
    - source: salt://etc/memcached.conf
    - template: jinja

memcached:
  service:
    - running
    - enable: True
    - watch:
      - file: /etc/memcached.conf

{% if pillar['rsyslog_setup'] %}
/etc/rsyslog.conf:
  file.managed:
    - source: salt://etc/rsyslog.conf
    - template: jinja

/etc/rsyslog.d/10-swift.conf:
  file.managed:
    - source: salt://etc/rsyslog.d/10-swift.conf
    - template: jinja

rsyslog:
  service:
    - running
    - enable: True
    - watch:
      - file: /etc/rsyslog.conf
      - file: /etc/rsyslog.d/10-swift.conf

/var/log/swift:
  file.directory:
    - user: syslog
    - group: adm
    - mode: 775

  {% if pillar['rsyslog_setup_hourly'] %}
/var/log/swift/hourly:
  file.directory:
    - user: syslog
    - group: adm
    - mode: 775
  {% endif %}
{% endif %}

python-swiftclient:
  git.latest:
    - name: https://github.com/openstack/python-swiftclient.git
    - target: /srv/swift/python-swiftclient
  cmd.wait:
    - name: python setup.py develop
    - cwd: /srv/swift/python-swiftclient
    - watch:
      - git: python-swiftclient

python-swift:
  git.latest:
    - name: https://github.com/openstack/swift.git
    - target: /srv/swift/swift
  cmd.wait:
    - name: python setup.py develop; pip install -r test-requirements.txt
    - cwd: /srv/swift/swift
    - watch:
      - git: python-swift

/etc/swift/swift.conf:
  file.managed:
    - source: salt://etc/swift/swift.conf
    - template: jinja
    - prefix: {{ pillar['swift_hash_path_prefix'] }}
    - suffix: {{ pillar['swift_hash_path_suffix'] }}

/etc/swift/proxy-server.conf:
  file.managed:
    - source: salt://etc/swift/proxy-server.conf
    - template: jinja

/etc/swift/object-expirer.conf:
  file.managed:
    - source: salt://etc/swift/object-expirer.conf
    - template: jinja

/etc/swift/memcache.conf:
  file.managed:
    - source: salt://etc/swift/memcache.conf

/etc/swift/test.conf:
  file.managed:
    - source: salt://etc/swift/test.conf
    - template: jinja

{% for n in range(1, (pillar['storage_zones'] + 1)) %}
/etc/swift/account-server/{{ n }}.conf:
  file.managed:
    - source: salt://etc/swift/account-server.conf
    - template: jinja
    - zone: {{ n }}
    - log_facility: {{ n + 2 }}

/etc/swift/container-server/{{ n }}.conf:
  file.managed:
    - source: salt://etc/swift/container-server.conf
    - template: jinja
    - zone: {{ n }}
    - log_facility: {{ n + 2 }}

/etc/swift/object-server/{{ n }}.conf:
  file.managed:
    - source: salt://etc/swift/object-server.conf
    - template: jinja
    - zone: {{ n }}
    - log_facility: {{ n + 2 }}
{% endfor %}

/etc/swift:
  file.directory:
    - mode: 755

/etc/swift/account-server:
  file.directory:
    - mode: 755

/etc/swift/container-server:
  file.directory:
    - mode: 755

/etc/swift/object-server:
  file.directory:
    - mode: 755

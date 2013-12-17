saio
====

saltstack state and helpers to build an openstack swift-all-in-one instance.

requires:
- salt-master with this stuff
- salt-minion, can be same box as master
- updating the hash prefix/suffix and tempauth passwords in pillar/saio/init.sls

```
    # salt-key -L
    Accepted Keys:
    saio
    
    # salt 'saio' grains.setval roles saio
    saio:
      roles: saio
    
    # salt -G 'roles:saio' state.highstate
    # salt -G 'roles:saio saio.remakerings
```
At this point you should have a configured SAIO and can start services up and run tests.
```
    # /srv/swift/swift/.unittests
    # swift-init main start
    # curl -v -H 'X-Storage-User: test:tester' -H 'X-Storage-Pass: <password>' http://127.0.0.1:8080/auth/v1.0
    # curl -v -H 'X-Auth-Token: <token-from-x-auth-token-above>' <url-from-x-storage-url-above>
    # swift -A http://127.0.0.1:8080/auth/v1.0 -U test:tester -K <password> stat
    # /srv/swift/swift/.functests
    # swift-init rest start
```

import uuid
import subprocess
from subprocess import PIPE

HAS_SAIO = False

try:
    from swift import __version__ as swiftversion
    HAS_SAIO = 'saio'
except ImportError:
    swiftversion = None
    HAS_SAIO = False


def __virtual__():
    return 'saio'


def randomish_string():
    return uuid.uuid4().hex


def _run_cmd(cmd, cwd='/'):
    proc = subprocess.Popen(cmd, cwd=cwd, stdout=PIPE)
    data = proc.communicate()[0]
    return data


def remakerings(zones=4):
    try:
        _run_cmd(['rm', '-f', '*.builder', '*.ring.gz', 'backups/*.builder',
                  'backups/*.ring.gz'], '/etc/swift')
        services = dict(account=2, container=1, object=0)
        for ring, port in services.iteritems():
            _run_cmd(['swift-ring-builder', '%s.builder' % ring,
                      'create', '10', '3', '1'], '/etc/swift')
            for zone in range(1, (zones + 1)):
                device = 'r%sz%s-127.0.0.1:60%s%s/sda' % (zone, zone, zone, port)
                _run_cmd(['swift-ring-builder', '%s.builder' % ring, 'add',
                          device, '1'], '/etc/swift')
            _run_cmd(['swift-ring-builder', '%s.builder' % ring,
                      'rebalance'], '/etc/swift')
        ret = {'name': "remakerings",
               'result': True,
               'comment': 'remade rings and deleted all your backups'}
    except:
        ret = {'name': "remakerings",
               'result': False,
               'comment': 'something failed'}
    return ret


def startmain():
    try:
        _run_cmd(['swift-init', 'main', 'start'])
        return {'result': True}
    except:
        return {'result': False}


def startrest():
    try:
        _run_cmd(['swift-init', 'rest', 'start'])
        return {'result': True}
    except:
        return {'result': False}


def startall():
    try:
        _run_cmd(['swift-init', 'all', 'start'])
        return {'result': True}
    except:
        return {'result': False}


def reloadmain():
    try:
        _run_cmd(['swift-init', 'main', 'reload'])
        return {'result': True}
    except:
        return {'result': False}


def reloadall():
    try:
        _run_cmd(['swift-init', 'all', 'reload'])
        return {'result': True}
    except:
        return {'result': False}


def restartmain():
    try:
        _run_cmd(['swift-init', 'main', 'restart'])
        return {'result': True}
    except:
        return {'result': False}

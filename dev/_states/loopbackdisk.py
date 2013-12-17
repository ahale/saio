import os
import subprocess
from subprocess import PIPE


def _run_cmd(cmd):
    """
    Run a command
    """
    proc = subprocess.Popen(cmd, stdout=PIPE)
    data = proc.communicate()[0]
    return data


def xfs(mount, path, size="1G", force=False):
    """
    creates file for mounting as loopback device and formats it xfs

    :param force: ignore file already exists
    :param mount: full path to mount point
    :param size: size of file to create
    :param path: path of file to create
    """
    ret = {'name': mount,
           'changes': {},
           'result': True,
           'comment': ''}

    try:
        file_dir = '/'.join(path.split('/')[:-1])
        file_name = ''.join(path.split('/')[-1:])
        file_path = '/'.join((file_dir, file_name))
        mount_dir = '/'.join(mount.split('/')[:-1])
        mount_name = ''.join(mount.split('/')[-1:])
        mount_path = '/'.join((mount_dir, mount_name))
    except:
        ret['comment'] = 'paths error'
        ret['result'] = False
        return ret

    root_dev = os.stat('/')[2]
    try:
        mount_dev = os.stat('%s' % mount_path)[2]
    except OSError:
        pass

    try:
        disk_file = os.stat('%s' % file_path)
    except OSError:
        pass

    if not force:
        try:
            if disk_file:
                ret['result'] = True
                ret['comment'] = 'disk file already exists, use force to overwrite'
                return ret
        except NameError:
            pass
        try:
            if mount_dev != root_dev:
                ret['result'] = True
                ret['comment'] = 'device already mounted'
                return ret
        except NameError:
            pass

    try:
        _run_cmd(['truncate', '-s', size, file_path])
        _run_cmd(['mkfs.xfs', '-f', '-L', mount_name, file_path])
        ret['comment'] = _run_cmd(['ls', file_path])
        return ret
    except:
        ret['comment'] = 'overly wide exception, who knows what failed'
        ret['result'] = False
        return ret

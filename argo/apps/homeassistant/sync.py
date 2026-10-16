#!/usr/bin/env python3
"""Apply the git-sync'd `generated` tree to /config, safely.

Per new revision: skip if nothing changed, back up changed targets, copy them in,
run HA check_config, roll back on failure, reload affected domains on success.
Never restarts HA; never touches .storage.
"""
import filecmp, json, os, shutil, subprocess, sys, time, urllib.request

SRC = os.environ.get("SRC", "/git/current")
CONFIG = os.environ.get("CONFIG", "/config")
BACKUPS = CONFIG + "/.hasync_backups"
STATE = CONFIG + "/.hasync_applied"
HA_URL = os.environ.get("HA_URL", "http://127.0.0.1:8123").rstrip("/")
TOKEN = os.environ["HA_TOKEN"]
INTERVAL = int(os.environ.get("INTERVAL", "30"))
KEEP = 10

# Mirrors YAML_FILES / YAML_DIRS in ha-data's _common.sh. Anything else in the
# generated tree is ignored.
FILES = ["configuration.yaml", "scripts.yaml", "scenes.yaml"]
DIRS = ["blueprints", "themes", "automations", "helpers", "dashboards"]

# target -> services to reload. Targets absent here take effect on next restart.
RELOAD = {
    "automations": ["automation/reload"],
    "scripts.yaml": ["script/reload"],
    "scenes.yaml": ["scene/reload"],
    "helpers": ["template/reload"],
}


def log(msg):
    print(time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), msg, flush=True)


def same(a, b):
    if os.path.isfile(a) and os.path.isfile(b):
        return filecmp.cmp(a, b, shallow=False)
    if os.path.isdir(a) and os.path.isdir(b):
        c = filecmp.dircmp(a, b)
        if c.left_only or c.right_only or c.funny_files:
            return False
        _, mismatch, errors = filecmp.cmpfiles(a, b, c.common_files, shallow=False)
        if mismatch or errors:
            return False
        return all(same(os.path.join(a, d), os.path.join(b, d)) for d in c.common_dirs)
    return False


def rm(path):
    if os.path.isdir(path) and not os.path.islink(path):
        shutil.rmtree(path)
    elif os.path.lexists(path):
        os.remove(path)


def put(src, dst):
    rm(dst)
    if os.path.isdir(src):
        shutil.copytree(src, dst)
    else:
        shutil.copy2(src, dst)


def check_config():
    r = subprocess.run(
        [sys.executable, "-m", "homeassistant", "--script", "check_config", "-c", CONFIG],
        capture_output=True, text=True)
    return r.returncode == 0, r.stdout + r.stderr


def reload_service(path):
    req = urllib.request.Request(
        "%s/api/services/%s" % (HA_URL, path), data=b"{}", method="POST",
        headers={"Authorization": "Bearer " + TOKEN, "Content-Type": "application/json"})
    try:
        urllib.request.urlopen(req, timeout=30).read()
        log("reloaded " + path)
    except Exception as e:  # non-fatal: config is already applied and valid
        log("reload %s failed: %s" % (path, e))


def apply(rev):
    changed = []
    for t in FILES + DIRS:
        s, d = os.path.join(SRC, t), os.path.join(CONFIG, t)
        if os.path.exists(s) and not same(s, d):
            changed.append(t)
    if not changed:
        log("rev %s: live already matches" % rev)
        return True

    log("rev %s: applying %s" % (rev, ", ".join(changed)))
    bdir = os.path.join(BACKUPS, time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()) + "-sync")
    os.makedirs(bdir, exist_ok=True)
    for t in changed:
        live = os.path.join(CONFIG, t)
        if os.path.exists(live):
            put(live, os.path.join(bdir, t))
    for t in changed:
        put(os.path.join(SRC, t), os.path.join(CONFIG, t))

    ok, out = check_config()
    if not ok:
        log("check_config FAILED, rolling back:\n" + out)
        for t in changed:
            b = os.path.join(bdir, t)
            if os.path.exists(b):
                put(b, os.path.join(CONFIG, t))
            else:
                rm(os.path.join(CONFIG, t))
        return False

    for old in sorted(os.listdir(BACKUPS))[:-KEEP]:
        shutil.rmtree(os.path.join(BACKUPS, old), ignore_errors=True)
    for t in changed:
        if t in RELOAD:
            for svc in RELOAD[t]:
                reload_service(svc)
        else:
            log("%s updated on disk; takes effect after a HA restart" % t)
    return True


def main():
    last = ""
    try:
        last = open(STATE).read().strip()
    except OSError:
        pass
    while True:
        try:
            rev = os.path.basename(os.path.realpath(SRC))
            if rev != last:
                # Record failures too, so a bad revision is not retried until a new one lands.
                apply(rev)
                last = rev
                open(STATE, "w").write(rev)
        except Exception as e:
            log("sync error: %r" % (e,))
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()

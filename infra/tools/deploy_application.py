# Purpose: Send the selected commit to a deployment hook and require readiness for that same commit.
"""Provider adapter: the hook must honor the JSON sha and readiness must echo release_sha."""
import argparse
import json
import os
import sys
import time
from urllib.parse import urlsplit
from urllib.request import Request, urlopen


def https_url(value):
    parsed = urlsplit(value)
    if parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password:
        raise RuntimeError('Configure HTTPS application deployment and readiness endpoints.')
    return value


def validate_settings(settings):
    hook = https_url(settings.get('DEPLOY_HOOK', ''))
    readiness = https_url(settings.get('READINESS_URL', ''))
    sha = settings.get('RELEASE_SHA', '')
    if len(sha) != 40 or any(character not in '0123456789abcdef' for character in sha):
        raise RuntimeError('A full selected Git commit SHA is required.')
    return hook, readiness, sha


def deploy(settings, open_url=urlopen, sleep=time.sleep):
    hook, readiness, sha = validate_settings(settings)
    request = Request(hook, data=json.dumps({'sha': sha}).encode(),
                      headers={'Content-Type': 'application/json'}, method='POST')
    with open_url(request, timeout=30):
        pass
    for attempt in range(60):
        try:
            with open_url(readiness, timeout=10) as response:
                body = json.load(response)
            if body.get('status') == 'healthy' and body.get('release_sha') == sha:
                print('PASS - Matching application commit is ready.')
                return
        except Exception:
            pass
        if attempt < 59:
            sleep(5)
    raise RuntimeError('Timed out waiting for the selected application commit to become ready.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Validate configuration without making requests')
    args = parser.parse_args()
    try:
        if args.check:
            validate_settings(os.environ)
            print('Application deployment configuration is present; no requests made.')
        else:
            deploy(os.environ)
    except Exception:
        print('BLOCKED - Application deployment/readiness failed. Verify the hosting adapter, '
              'selected commit and application logs. Hook URLs and responses are withheld.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

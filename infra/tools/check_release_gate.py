# Purpose: Require successful staging of the same commit and production environment reviewers before release.
"""Validate release provenance using GitHub metadata; never read database secrets."""
import json
import os
import sys
from urllib.request import Request, urlopen


def github_get(path, settings):
    request = Request('https://api.github.com/repos/' + settings['GITHUB_REPOSITORY'] + '/' + path,
                      headers={'Authorization': 'Bearer ' + settings['GH_TOKEN'],
                               'Accept': 'application/vnd.github+json',
                               'X-GitHub-Api-Version': '2022-11-28'})
    with urlopen(request, timeout=20) as response:
        return json.load(response)


def check_gate(settings, get=github_get):
    event, ref = settings.get('GITHUB_EVENT_NAME'), settings.get('GITHUB_REF')
    if event == 'push' and ref == 'refs/heads/develop':
        return 'development'
    if event == 'push' and ref == 'refs/heads/main':
        return 'staging'
    if event != 'workflow_dispatch' or ref != 'refs/heads/main':
        raise RuntimeError('Production releases must be dispatched from main.')
    run_id = settings.get('STAGING_RUN_ID', '')
    if not run_id.isdigit() or settings.get('STAGING_ACCEPTED') != 'true':
        raise RuntimeError('Provide a staging run ID and confirm staging feature acceptance.')
    if not settings.get('BACKUP_REFERENCE', '').strip():
        raise RuntimeError('Record the verified production backup or snapshot reference.')
    run = get('actions/runs/' + run_id, settings)
    if not (run.get('conclusion') == 'success' and run.get('status') == 'completed'
            and run.get('head_sha') == settings.get('GITHUB_SHA')
            and run.get('head_branch') == 'main' and run.get('event') == 'push'
            and run.get('path') == '.github/workflows/deploy.yml'):
        raise RuntimeError('Production requires a successful staging Deploy run for this exact main commit.')
    jobs = get('actions/runs/' + run_id + '/jobs?per_page=100', settings).get('jobs', [])
    successful_jobs = {job.get('name') for job in jobs
                       if job.get('conclusion') == 'success' and job.get('status') == 'completed'}
    if not {'gate', 'release-verify', 'migration-verify', 'deploy'} <= successful_jobs:
        raise RuntimeError('Staging verification and deployment jobs must actually succeed; skipped jobs do not qualify.')
    environment = get('environments/production', settings)
    reviewers = [rule for rule in environment.get('protection_rules', [])
                 if rule.get('type') == 'required_reviewers' and rule.get('reviewers')]
    if not reviewers:
        raise RuntimeError('Configure production environment required reviewers before releasing.')
    if not environment.get('deployment_branch_policy'):
        raise RuntimeError('Restrict production deployment branches before releasing.')
    return 'production'


def main():
    try:
        environment = check_gate(os.environ)
        with open(os.environ['GITHUB_OUTPUT'], 'a', encoding='utf-8') as output:
            output.write('environment=' + environment + '\n')
        print('Release provenance verified. Target:', environment)
    except Exception:
        print('BLOCKED - Release gate failed. Check the main commit, successful staging Deploy run, '
              'staging acceptance, backup reference and production environment reviewer/branch protections.',
              file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

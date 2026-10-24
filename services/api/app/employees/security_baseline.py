"""Read-back verification against a CTO-reviewed GitHub configuration snapshot.

The privileged read token belongs to a separate CTO audit identity. The routine
membership App does not gain repository Administration permissions.
"""
import hashlib
import json

from app.employees.models import now
from app.employees.service import utc


def capture_security_baseline(reader):
    repo = '/repos/Tripraft/Tripraft'
    rulesets = reader.items(repo + '/rulesets')
    repository = reader.call('GET', repo)
    organization = reader.call('GET', '/orgs/Tripraft')
    result = {
        'organization': {key: organization.get(key) for key in (
            'id', 'default_repository_permission', 'members_can_create_repositories',
            'members_can_create_public_repositories', 'members_can_create_private_repositories',
            'members_can_create_internal_repositories', 'members_can_fork_private_repositories',
            'two_factor_requirement_enabled')},
        'repository': {key: repository.get(key) for key in ('id', 'private', 'visibility', 'default_branch')},
        'rulesets': [reader.call('GET', repo + f'/rulesets/{int(rule["id"])}') for rule in rulesets],
        'classic_protection': {branch: reader.call('GET', repo + f'/branches/{branch}/protection', missing=True)
                               for branch in ('main', 'develop')},
        'owners': sorted(str(user['id']) for user in reader.items('/orgs/Tripraft/members')
                         if reader.membership(user['login']).get('role') == 'admin'),
        'teams': [{key: team.get(key) for key in ('id', 'slug', 'permission', 'permissions', 'parent')}
                  for team in reader.items(repo + '/teams')],
        'collaborators': reader.items(repo + '/collaborators', params={'affiliation': 'direct'}),
        'environments': reader.call('GET', repo + '/environments'),
        'workflow_permissions': reader.call('GET', repo + '/actions/permissions/workflow'),
    }
    # Permission fields embedded for the reading identity are not policy settings.
    for user in result['collaborators']:
        for key in ('avatar_url', 'url', 'html_url', 'followers_url', 'following_url', 'gists_url',
                    'starred_url', 'subscriptions_url', 'organizations_url', 'repos_url',
                    'events_url', 'received_events_url'):
            user.pop(key, None)
    return result


def fingerprint(snapshot):
    return hashlib.sha256(json.dumps(snapshot, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


class ReviewedBaselineGate:
    def __init__(self, reader, approved_snapshot, expires_at, approved_cto_id, cto_ids):
        self.reader, self.approved_snapshot = reader, approved_snapshot
        self.expires_at, self.approved_cto_id, self.cto_ids = expires_at, approved_cto_id, set(cto_ids)

    def __call__(self):
        if self.approved_cto_id not in self.cto_ids or utc(self.expires_at) <= now():
            return False
        snapshot = capture_security_baseline(self.reader)
        if not snapshot['owners'] or snapshot['repository']['default_branch'] != 'main':
            return False
        # Exact read-back also detects unrelated direct grants and administrative bypass changes.
        return fingerprint(snapshot) == fingerprint(self.approved_snapshot)

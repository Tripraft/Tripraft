"""GitHub App adapter. Tokens are supplied only by the trusted executor.

No Flask route instantiates this adapter. No credentials are persisted in jobs.
"""
from datetime import timedelta
import time

import jwt
import requests

from app.employees.models import now

# Scope decision: postponed. There is deliberately no environment/config switch.
# Re-enabling requires a reviewed source change and fresh CTO authorization.
GITHUB_AUTOMATION_ENABLED = False


class GitHubAutomationDisabled(RuntimeError):
    pass


class GitHubError(Exception):
    def __init__(self, status, retry_after=0):
        # Do not retain response bodies or request headers containing credentials/PII.
        self.status = status
        self.retry_after = retry_after
        self.retryable = status in (0, 429, 500, 502, 503, 504) or (status == 403 and retry_after > 0)
        super().__init__(f'github_http_{status}')


class GitHubAppToken:
    def __init__(self, app_id, installation_id, private_key_provider, transport=None):
        self.app_id, self.installation_id = app_id, installation_id
        self.private_key_provider = private_key_provider
        self.transport = transport or requests.Session()
        self._token, self._expires = None, 0

    def __call__(self):
        if not GITHUB_AUTOMATION_ENABLED:
            raise GitHubAutomationDisabled('Automatic GitHub provisioning is postponed')
        if self._token and time.time() < self._expires:
            return self._token
        stamp = int(time.time())
        assertion = jwt.encode({'iat': stamp - 30, 'exp': stamp + 540, 'iss': self.app_id},
                               self.private_key_provider(), algorithm='RS256')
        try:
            response = self.transport.post(
                f'https://api.github.com/app/installations/{int(self.installation_id)}/access_tokens',
                headers={'Authorization': f'Bearer {assertion}', 'Accept': 'application/vnd.github+json',
                         'X-GitHub-Api-Version': '2026-03-10'},
                json={'permissions': {'members': 'write', 'metadata': 'read'}}, timeout=(5, 25),
                allow_redirects=False)
        except requests.RequestException:
            raise GitHubError(0) from None
        if response.status_code != 201:
            raise GitHubError(response.status_code)
        data = response.json()
        self._token = data['token']
        # Installation tokens normally last an hour; refresh early.
        self._expires = min(stamp + 3000, __import__('datetime').datetime.fromisoformat(
            data['expires_at'].replace('Z', '+00:00')).timestamp() - 60)
        return self._token


class GitHubClient:
    org = 'Tripraft'
    repository = 'Tripraft/Tripraft'

    def __init__(self, token_provider, transport=None):
        self.token_provider = token_provider
        self.transport = transport or requests.Session()

    def call(self, method, path, payload=None, missing=False):
        if method != 'GET' and not GITHUB_AUTOMATION_ENABLED:
            raise GitHubAutomationDisabled('Automatic GitHub invitations and membership changes are disabled')
        if not path.startswith('/') or '?' in path or '..' in path:
            raise ValueError('Invalid GitHub API path')
        try:
            response = self.transport.request(method, 'https://api.github.com' + path,
                headers={'Authorization': f'Bearer {self.token_provider()}',
                         'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2026-03-10'},
                json=payload, timeout=(5, 25), allow_redirects=False)
        except requests.RequestException:
            raise GitHubError(0) from None
        if response.status_code == 404 and missing:
            return None
        if not 200 <= response.status_code < 300:
            try:
                wait = int(response.headers.get('Retry-After', '0'))
                if response.headers.get('X-RateLimit-Remaining') == '0':
                    wait = max(wait, int(response.headers.get('X-RateLimit-Reset', '0')) - int(time.time()))
            except ValueError:
                wait = 60
            raise GitHubError(response.status_code, max(0, wait))
        return None if response.status_code == 204 else response.json()

    def items(self, path, params=None):
        # Paginate with fixed trusted origin; never follow an arbitrary Link URL.
        result = []
        for number in range(1, 101):
            try:
                response = self.transport.request('GET', 'https://api.github.com' + path,
                    headers={'Authorization': f'Bearer {self.token_provider()}',
                             'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2026-03-10'},
                    params={**(params or {}), 'per_page': 100, 'page': number}, timeout=(5, 25), allow_redirects=False)
            except requests.RequestException:
                raise GitHubError(0) from None
            if response.status_code != 200:
                raise GitHubError(response.status_code, 60 if response.status_code in (403, 429) else 0)
            batch = response.json()
            if not isinstance(batch, list):
                raise GitHubError(502)
            result.extend(batch)
            if len(batch) < 100:
                return result
        raise GitHubError(502)

    def identity(self, username):
        return self.call('GET', f'/users/{username}')

    def membership(self, username):
        return self.call('GET', f'/orgs/{self.org}/memberships/{username}', missing=True)

    def invitations(self):
        return self.items(f'/orgs/{self.org}/invitations')

    def failed_invitations(self):
        return self.items(f'/orgs/{self.org}/failed_invitations')

    def invite(self, github_id, team_ids):
        return self.call('POST', f'/orgs/{self.org}/invitations',
                         {'invitee_id': int(github_id), 'role': 'direct_member', 'team_ids': team_ids})

    def cancel_invitation(self, invitation_id):
        self.call('DELETE', f'/orgs/{self.org}/invitations/{int(invitation_id)}', missing=True)

    def team(self, slug):
        return self.call('GET', f'/orgs/{self.org}/teams/{slug}')

    def team_permission(self, slug):
        return self.call('GET', f'/orgs/{self.org}/teams/{slug}/repos/{self.repository}')

    def team_membership(self, slug, username):
        return self.call('GET', f'/orgs/{self.org}/teams/{slug}/memberships/{username}', missing=True)

    def set_team(self, slug, username):
        return self.call('PUT', f'/orgs/{self.org}/teams/{slug}/memberships/{username}', {'role': 'member'})

    def remove_team(self, slug, username):
        self.call('DELETE', f'/orgs/{self.org}/teams/{slug}/memberships/{username}', missing=True)

    def remove_member(self, username):
        self.call('DELETE', f'/orgs/{self.org}/members/{username}', missing=True)


def invitation_state(employee, pending, failed):
    matching = next((invite for invite in pending if str(invite.get('id')) == employee.github_invitation_id
                     or str(invite.get('invitee_id')) == employee.github_id
                     or (invite.get('login') or '').lower() == employee.github_username.lower()
                     or (invite.get('email') or '').lower() == employee.email), None)
    if matching:
        return 'pending', matching
    if any(str(invite.get('id')) == employee.github_invitation_id for invite in failed):
        return 'failed', None
    invited_at = employee.github_invited_at
    if invited_at and invited_at.replace(tzinfo=now().tzinfo) + timedelta(days=7) <= now():
        return 'expired', None
    return 'unknown', None

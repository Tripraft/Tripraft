import pytest

from app.notifications.email.smtp import EmailService


@pytest.mark.parametrize('kind,path', [('trip', 'invitations'), ('expense', 'invitation')])
def test_smtp_invitation_uses_a_registered_web_route(kind, path, monkeypatch):
    service = EmailService()
    service._frontend_url = 'http://localhost:5173'
    sent = []
    monkeypatch.setattr(service, 'send_email', lambda *values: sent.append(values) or True)
    assert service.send_invitation('friend@example.test', 'Alex', 'Our trip', 'invite-uuid', kind)
    expected = f'http://localhost:5173/{path}/invite-uuid'
    assert expected in sent[0][2]
    assert expected in sent[0][3]

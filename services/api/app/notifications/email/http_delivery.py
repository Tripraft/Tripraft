"""Deliver existing email templates over HTTPS without exposing provider errors or keys."""
import logging
import base64
from email.message import EmailMessage

import requests

from app.core.config import Config

logger = logging.getLogger(__name__)


def http_email_configured():
    if Config.EMAIL_PROVIDER == 'gmail':
        return bool(Config.GMAIL_CLIENT_ID and Config.GMAIL_CLIENT_SECRET
                    and Config.GMAIL_REFRESH_TOKEN and Config.FROM_EMAIL)
    if Config.EMAIL_PROVIDER == 'resend':
        return bool(Config.RESEND_API_KEY and Config.FROM_EMAIL)
    return False


def send_http_email(to_email, subject, html_body, text_body=None):
    if Config.EMAIL_PROVIDER == 'gmail':
        return send_gmail_email(to_email, subject, html_body, text_body)
    if Config.EMAIL_PROVIDER == 'resend':
        return send_resend_email(to_email, subject, html_body, text_body)
    return False


def send_gmail_email(to_email, subject, html_body, text_body=None):
    """Use the sender's offline OAuth grant with Gmail's HTTPS API, without SMTP."""
    if not http_email_configured():
        return False
    try:
        token_response = requests.post(
            'https://oauth2.googleapis.com/token',
            data={'client_id': Config.GMAIL_CLIENT_ID, 'client_secret': Config.GMAIL_CLIENT_SECRET,
                  'refresh_token': Config.GMAIL_REFRESH_TOKEN, 'grant_type': 'refresh_token'},
            timeout=Config.SMTP_TIMEOUT,
        )
        token_response.raise_for_status()
        access_token = token_response.json().get('access_token')
        if not isinstance(access_token, str) or not access_token:
            logger.warning('Gmail OAuth did not return an access token')
            return False
        message = EmailMessage()
        message['From'] = f'{Config.APP_NAME} <{Config.FROM_EMAIL}>'
        message['To'] = to_email
        message['Subject'] = subject
        message.set_content(text_body or 'View the HTML version of this email.')
        message.add_alternative(html_body, subtype='html')
        raw = base64.urlsafe_b64encode(message.as_bytes()).decode('ascii')
        response = requests.post(
            'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
            headers={'Authorization': f'Bearer {access_token}'}, json={'raw': raw},
            timeout=Config.SMTP_TIMEOUT,
        )
        if 200 <= response.status_code < 300:
            return True
        logger.warning('Gmail API rejected request (HTTP %s)', response.status_code)
    except (requests.RequestException, ValueError, TypeError, AttributeError):
        logger.warning('Gmail HTTPS delivery failed; check the sender OAuth grant in Google Cloud')
    return False


def send_resend_email(to_email, subject, html_body, text_body=None):
    """Return provider acceptance; actual mailbox delivery must be checked separately."""
    if not Config.RESEND_API_KEY or not Config.FROM_EMAIL:
        return False
    payload = {
        'from': f'{Config.APP_NAME} <{Config.FROM_EMAIL}>',
        'to': [to_email], 'subject': subject, 'html': html_body,
    }
    if text_body:
        payload['text'] = text_body
    try:
        response = requests.post(
            'https://api.resend.com/emails',
            headers={'Authorization': f'Bearer {Config.RESEND_API_KEY}'},
            json=payload, timeout=Config.SMTP_TIMEOUT,
        )
        if 200 <= response.status_code < 300:
            return True
        logger.warning('HTTPS email provider rejected request (HTTP %s)', response.status_code)
    except requests.RequestException:
        # Exceptions and response bodies can contain recipient data or credentials.
        logger.warning('HTTPS email provider request failed')
    return False

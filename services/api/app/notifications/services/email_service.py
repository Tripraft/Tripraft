# Purpose: Email Service Professional email handling for expense engine.
"""
Email Service
Professional email handling for expense engine
"""

import logging
import os
import smtplib
import ssl
from html import escape
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Optional

import pybreaker
from app.core.config import Config
from app.core.resilience import smtp_breaker
from app.notifications.email.links import expense_invitation_link
# Load environment variables at module import
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)


class EmailDeliveryError(RuntimeError):
    """Safe delivery outcome; never contains recipient, token or SMTP credentials."""

    def __init__(self, code, *, retryable=False, uncertain=False):
        super().__init__(code)
        self.retryable, self.uncertain = retryable, uncertain


class EmailService:
    """Email service for sending notifications"""
    
    def __init__(self):
        """Initialize email service with configuration"""
        self.enabled = os.getenv('EMAIL_ENABLED', 'false').lower() == 'true'
        self.smtp_host = Config.SMTP_HOST
        self.smtp_port = Config.SMTP_PORT
        self.smtp_user = Config.SMTP_USER
        self.smtp_password = Config.SMTP_PASSWORD
        self.from_email = Config.FROM_EMAIL or self.smtp_user
        self.from_name = Config.APP_NAME
        
        if not self.enabled:
            logger.info("Email service is disabled")
        elif not self.smtp_user or not self.smtp_password:
            logger.warning("Email credentials not configured - email service will be disabled")
            self.enabled = False
    
    def send_email(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: Optional[str] = None,
        *, delivery_report: bool = False, message_id: Optional[str] = None
    ) -> bool:
        """
        Send an email
        
        Args:
            to_email: Recipient email address
            subject: Email subject
            html_body: HTML email body
            text_body: Plain text fallback (optional)
            
        Returns:
            True if sent successfully, False otherwise
        """
        if not self.enabled:
            if delivery_report:
                raise EmailDeliveryError('invitation_email_not_configured')
            logger.debug(f"Email to {to_email} not sent (service disabled)")
            return False
        
        submitted = False
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['From'] = f"{self.from_name} <{self.from_email}>"
            msg['To'] = to_email
            msg['Subject'] = subject
            if message_id:
                msg['Message-ID'] = message_id
            
            # Add plain text version
            if text_body:
                part1 = MIMEText(text_body, 'plain')
                msg.attach(part1)
            
            # Add HTML version
            part2 = MIMEText(html_body, 'html')
            msg.attach(part2)
            
            # Send email
            def _send():
                nonlocal submitted
                with smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=Config.SMTP_TIMEOUT) as server:
                    if delivery_report:
                        server.starttls(context=ssl.create_default_context())
                    else:
                        server.starttls()
                    server.login(self.smtp_user, self.smtp_password)
                    submitted = True
                    refused = server.send_message(msg)
                    if refused:
                        raise smtplib.SMTPRecipientsRefused(refused)

            smtp_breaker.call(_send)
            
            logger.info(f"Email sent to {to_email}: {subject}")
            return True

        except pybreaker.CircuitBreakerError:
            if delivery_report:
                raise EmailDeliveryError('smtp_circuit_open', retryable=True) from None
            logger.warning(f"SMTP circuit breaker open, email to {to_email} not sent")
            return False            
        except Exception as e:
            if delivery_report:
                if isinstance(e, (smtplib.SMTPRecipientsRefused, smtplib.SMTPSenderRefused,
                                  smtplib.SMTPDataError, smtplib.SMTPAuthenticationError)):
                    code = getattr(e, 'smtp_code', 550)
                    raise EmailDeliveryError('smtp_rejected', retryable=400 <= code < 500) from None
                raise EmailDeliveryError('smtp_delivery_uncertain' if submitted else 'smtp_connection_failed',
                                         retryable=not submitted, uncertain=submitted) from None
            logger.error(f"Failed to send email to {to_email}: {str(e)}")
            return False
    
    def send_group_invitation(
        self,
        to_email: str,
        inviter_name: str,
        group_name: str,
        invitation_id: str
    ) -> bool:
        """
        Send group invitation email
        
        Args:
            to_email: Email address of invitee
            inviter_name: Name of person sending invitation
            group_name: Name of the group
            invitation_id: Invitation ID for link
            
        Returns:
            True if sent successfully, False otherwise
        """
        invitation_link = expense_invitation_link(invitation_id)
        safe_inviter_name = escape(inviter_name, quote=True)
        safe_group_name = escape(group_name, quote=True)
        safe_invitation_link = escape(invitation_link, quote=True)
        safe_app_name = escape(Config.APP_NAME, quote=True)
        
        subject = f"{inviter_name} invited you to join '{group_name}'"
        
        html_body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <h2 style="color: #2563eb;">You've been invited!</h2>
                <p><strong>{safe_inviter_name}</strong> has invited you to join the group <strong>"{safe_group_name}"</strong>.</p>
                <p>Join this group to track and split expenses together.</p>
                <div style="margin: 30px 0;">
                    <a href="{safe_invitation_link}"
                       style="background-color: #2563eb; color: white; padding: 12px 24px; 
                              text-decoration: none; border-radius: 6px; display: inline-block;">
                        Accept Invitation
                    </a>
                </div>
                <p style="color: #666; font-size: 14px;">
                    Or copy this link: <a href="{safe_invitation_link}">{safe_invitation_link}</a>
                </p>
                <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">
                <p style="color: #9ca3af; font-size: 12px;">
                    This invitation was sent from {safe_app_name}. If you didn't expect this invitation, you can safely ignore this email.
                </p>
            </div>
        </body>
        </html>
        """
        
        text_body = f"""
        You've been invited!
        
        {inviter_name} has invited you to join the group "{group_name}".
        
        Join this group to track and split expenses together.
        
        Accept invitation: {invitation_link}
        
        ---
        This invitation was sent from {Config.APP_NAME}. If you didn't expect this invitation, you can safely ignore this email.
        """
        
        return self.send_email(to_email, subject, html_body, text_body)


# Singleton instance
email_service = EmailService()

# Purpose: Bounds best-effort auth email delivery without delaying HTTP responses.
import logging
from concurrent.futures import ThreadPoolExecutor
from threading import BoundedSemaphore

logger = logging.getLogger(__name__)
_executor = ThreadPoolExecutor(max_workers=2, thread_name_prefix='auth-email')
_slots = BoundedSemaphore(32)


def submit_auth_email(send, *args):
    """Return immediately; delivery failures are observable and explicitly retryable."""
    if not _slots.acquire(blocking=False):
        logger.warning('Auth email capacity reached; request can be retried')
        return False

    def deliver():
        try:
            if not send(*args):
                logger.warning('Auth email delivery failed; request can be retried')
        except Exception:
            logger.exception('Auth email delivery failed')
        finally:
            _slots.release()

    try:
        _executor.submit(deliver)
        return True
    except RuntimeError:
        _slots.release()
        logger.warning('Auth email worker unavailable')
        return False

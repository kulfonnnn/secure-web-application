import logging

from django.contrib.auth.signals import user_login_failed
from django.dispatch import receiver

logger = logging.getLogger("security")


def client_ip(request):
    """Adres klienta za CloudFront i ALB.

    X-Forwarded-For ma postać: [wpisy podane przez klienta,] adres klienta widziany
    przez CloudFront, adres węzła CloudFront dopisany przez ALB. Wiarygodny jest
    przedostatni wpis, bo wcześniejsze może sfałszować klient.
    """
    if request is None:
        return "-"
    header = request.META.get("HTTP_X_FORWARDED_FOR", "")
    parts = [p.strip() for p in header.split(",") if p.strip()]
    if len(parts) >= 2:
        return parts[-2]
    return request.META.get("REMOTE_ADDR", "-")


@receiver(user_login_failed)
def log_failed_login(sender, credentials, request=None, **kwargs):
    logger.warning(
        "login_failed username=%r ip=%s",
        credentials.get("username", "-"),
        client_ip(request),
    )
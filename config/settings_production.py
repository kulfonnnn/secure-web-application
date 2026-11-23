"""Ustawienia produkcyjne (AWS). Nadpisują tylko to, co zależy od środowiska AWS.

SECRET_KEY, ALLOWED_HOSTS, DATABASES i CACHES są czytane ze zmiennych środowiskowych
już w config/settings.py (wartości ustawia deploy/entrypoint.py).
"""
import os

from .settings import *  # noqa: F401,F403

DEBUG = False
CSRF_TRUSTED_ORIGINS = ["https://" + os.environ["APP_FQDN"]]

# TLS kończy się na CloudFront i ALB, a Django dostaje ruch przez HTTP
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True

# Wyciszone świadomie: przekierowanie HTTP -> HTTPS niepotrzebne (CloudFront: HTTPS Only),
# a HSTS preload jest trudny do cofnięcia
SILENCED_SYSTEM_CHECKS = [*SILENCED_SYSTEM_CHECKS, "security.W008", "security.W021"]  # noqa: F405

# Baza: połączenie szyfrowane z weryfikacją certyfikatu RDS
DATABASES["default"]["OPTIONS"] = {  # noqa: F405
    "sslmode": "verify-full",
    "sslrootcert": "/certs/rds-global-bundle.pem",
}


# Pliki statyczne: WhiteNoise. Załączniki: S3.
STATIC_ROOT = BASE_DIR / "staticfiles"  # noqa: F405

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": os.environ["AWS_STORAGE_BUCKET_NAME"],
            "region_name": os.environ["AWS_S3_REGION_NAME"],
            "default_acl": None,
            "file_overwrite": False,
        },
    },
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage",
    },
}

MIDDLEWARE = list(MIDDLEWARE)  # noqa: F405
MIDDLEWARE.insert(0, "config.middleware.HealthCheckMiddleware")
MIDDLEWARE.insert(
    MIDDLEWARE.index("django.middleware.security.SecurityMiddleware") + 1,
    "whitenoise.middleware.WhiteNoiseMiddleware",
)

# Logi: nieudane logowania do osobnego pliku (katalog zamontowany z hosta)
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "standard": {"format": "%(asctime)s %(levelname)s %(name)s %(message)s"},
    },
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "standard"},
        "security_file": {
            "class": "logging.handlers.RotatingFileHandler",
            "filename": "/var/log/bsiaw/security.log",
            "maxBytes": 5_000_000,
            "backupCount": 5,
            "formatter": "standard",
        },
    },
    "loggers": {
        "security": {
            "handlers": ["security_file", "console"],
            "level": "INFO",
            "propagate": False,
        },
    },
    "root": {"handlers": ["console"], "level": "INFO"},
}
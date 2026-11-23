import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings_production")

from django.core.wsgi import get_wsgi_application  # noqa: E402

application = get_wsgi_application()

from config import security_logging  # noqa: E402,F401  (rejestruje odbiornik sygnału)
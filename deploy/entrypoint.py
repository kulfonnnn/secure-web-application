#!/usr/bin/env python
"""Pobiera konfigurację i sekrety, ustawia zmienne środowiskowe i uruchamia proces."""
import json
import os
import sys
from urllib.parse import urlparse

import boto3


def load_config(uri, region):
    """Czyta plik KEY=VALUE z S3 (konfiguracja niepoufna zarządzana Terraformem)."""
    parsed = urlparse(uri)
    s3 = boto3.client("s3", region_name=region)
    body = s3.get_object(Bucket=parsed.netloc, Key=parsed.path.lstrip("/"))["Body"].read().decode()
    for line in body.splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())


def load_secrets(secret_id, region):
    """Pobiera sekret JSON z Secrets Managera i składa adres Redis z TLS."""
    sm = boto3.client("secretsmanager", region_name=region)
    data = json.loads(sm.get_secret_value(SecretId=secret_id)["SecretString"])
    os.environ["DJANGO_SECRET_KEY"] = data["DJANGO_SECRET_KEY"]
    os.environ["DB_PASSWORD"] = data["DB_PASSWORD"]
    os.environ["REDIS_URL"] = "rediss://:{}@{}:6379/0".format(
        data["REDIS_PASSWORD"], os.environ["REDIS_HOST"]
    )


def main():
    region = os.environ["AWS_REGION"]
    load_config(os.environ["APP_CONFIG_URI"], region)
    load_secrets(os.environ["APP_SECRET_ID"], region)
    os.execvp(sys.argv[1], sys.argv[1:])


if __name__ == "__main__":
    main()
from django.contrib.auth.models import AbstractUser
from django.db import models


# Minimal custom user
class CustomUser(AbstractUser):
    email = models.EmailField("e-mail address", unique=True)
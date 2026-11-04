from django.conf import settings
from django.core.validators import MinLengthValidator, RegexValidator
from django.db import models

TITLE_MIN_LENGTH = 5
TITLE_MAX_LENGTH = 120
CONTENT_MIN_LENGTH = 10
CONTENT_MAX_LENGTH = 5000

# Titles are plain text: no HTML brackets or control characters
title_chars_validator = RegexValidator(
    r"^[^<>\x00-\x1f\x7f]+$",
    "Title contains forbidden characters.",
)


class Forum(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Topic(models.Model):
    forum = models.ForeignKey(Forum, on_delete=models.CASCADE, related_name="topics")
    title = models.CharField(
        max_length=TITLE_MAX_LENGTH,
        validators=[MinLengthValidator(TITLE_MIN_LENGTH), title_chars_validator],
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="topics"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title


class Post(models.Model):
    topic = models.ForeignKey(Topic, on_delete=models.CASCADE, related_name="posts")
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="posts"
    )
    # Stored already sanitized (see forum/sanitizers.py)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    edited_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["created_at", "pk"]

    def __str__(self):
        return f"{self.author} in {self.topic}"

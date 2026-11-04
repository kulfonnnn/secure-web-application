import uuid

from django.conf import settings
from django.core.validators import MinLengthValidator, RegexValidator
from django.db import models, transaction
from django.db.models.signals import post_delete
from django.dispatch import receiver

TITLE_MIN_LENGTH = 5
TITLE_MAX_LENGTH = 120
CONTENT_MIN_LENGTH = 10
CONTENT_MAX_LENGTH = 5000

# Titles are plain text: no HTML brackets or control characters
title_chars_validator = RegexValidator(
    r"^[^<>\x00-\x1f\x7f]+$",
    "Title contains forbidden characters.",
)


def attachment_path(instance, filename):
    # Random name hides the original one and prevents path tricks
    extension = filename.rsplit(".", 1)[-1].lower()
    return f"attachments/{uuid.uuid4().hex}.{extension}"


def delete_file_on_commit(storage, name):
    # Remove the file from disk only after the DB change is committed
    transaction.on_commit(lambda: storage.delete(name))


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
    attachment = models.FileField(upload_to=attachment_path, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    edited_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["created_at", "pk"]

    def __str__(self):
        return f"{self.author} in {self.topic}"


# Works for every delete: forum view, admin panel and topic cascade
@receiver(post_delete, sender=Post)
def delete_attachment_file(sender, instance, **kwargs):
    if instance.attachment:
        delete_file_on_commit(instance.attachment.storage, instance.attachment.name)

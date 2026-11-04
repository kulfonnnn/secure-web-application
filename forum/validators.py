import filetype
from django.core.exceptions import ValidationError

ATTACHMENT_MAX_SIZE = 2 * 1024 * 1024
ALLOWED_ATTACHMENT_TYPES = {
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "gif": "image/gif",
    "pdf": "application/pdf",
}


def validate_attachment(file):
    if file.size > ATTACHMENT_MAX_SIZE:
        raise ValidationError("Attachment can't be larger than 2 MB.")
    extension = file.name.rsplit(".", 1)[-1].lower() if "." in file.name else ""
    if extension not in ALLOWED_ATTACHMENT_TYPES:
        raise ValidationError("Allowed file types: PNG, JPG, GIF, PDF.")
    # Check real file content (magic bytes), not only the name
    head = file.read(261)
    file.seek(0)
    kind = filetype.guess(head)
    if kind is None or kind.mime != ALLOWED_ATTACHMENT_TYPES[extension]:
        raise ValidationError("File content doesn't match its extension.")

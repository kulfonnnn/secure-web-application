from django import forms

from .models import CONTENT_MAX_LENGTH, CONTENT_MIN_LENGTH, Post, Topic
from .sanitizers import sanitize_html, visible_text


class PostContentField(forms.CharField):
    # Limits raw size, sanitizes HTML, then checks there is real text left
    def __init__(self, **kwargs):
        kwargs.setdefault("label", "Content")
        kwargs.setdefault("max_length", CONTENT_MAX_LENGTH)
        kwargs.setdefault("widget", forms.Textarea(attrs={"class": "form-control", "rows": 8}))
        super().__init__(**kwargs)

    def clean(self, value):
        value = super().clean(value)
        cleaned = sanitize_html(value)
        if len(visible_text(cleaned)) < CONTENT_MIN_LENGTH:
            raise forms.ValidationError(
                f"Post must contain at least {CONTENT_MIN_LENGTH} characters of text."
            )
        return cleaned


class TopicForm(forms.ModelForm):
    content = PostContentField()

    class Meta:
        model = Topic
        fields = ("title", "content")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["title"].widget.attrs.update({"class": "form-control"})


class PostForm(forms.ModelForm):
    content = PostContentField()

    class Meta:
        model = Post
        fields = ("content",)

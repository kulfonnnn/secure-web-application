from html import unescape

from django.contrib import admin

from .forms import PostForm
from .models import Forum, Post, Topic
from .sanitizers import visible_text


@admin.register(Forum)
class ForumAdmin(admin.ModelAdmin):
    list_display = ("name", "description", "created_at")


class PostInline(admin.TabularInline):
    model = Post
    extra = 0
    fields = ("author", "content", "created_at")
    readonly_fields = ("author", "content", "created_at")


@admin.register(Topic)
class TopicAdmin(admin.ModelAdmin):
    list_display = ("title", "forum", "author", "created_at")
    list_filter = ("forum",)
    search_fields = ("title", "author__username")
    inlines = [PostInline]


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    # Admin edits go through the same sanitization as the site
    form = PostForm
    fields = ("topic", "author", "content")
    list_display = ("short_content", "author", "topic", "created_at", "edited_at")
    list_filter = ("topic__forum", "created_at")
    search_fields = ("content", "author__username")

    @admin.display(description="Content")
    def short_content(self, obj):
        # Plain text preview (admin escapes it again when rendering)
        return unescape(visible_text(obj.content))[:60]

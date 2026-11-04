from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from django.urls import reverse

from .forms import PostForm, TopicForm
from .models import Forum, Post, Topic
from .sanitizers import sanitize_html

User = get_user_model()

VALID_CONTENT = "This is a valid post content."


class ForumTestCase(TestCase):
    def setUp(self):
        # Rate limit counters live in Redis, reset them for every test
        cache.clear()
        self.alice = User.objects.create_user("alice", "alice@example.com", "S3cure-pass-123")
        self.bob = User.objects.create_user("bob", "bob@example.com", "S3cure-pass-123")
        self.forum = Forum.objects.create(name="Test forum")
        self.client.force_login(self.alice)

    def create_topic(self, author=None, title="Valid topic", content=VALID_CONTENT):
        author = author or self.alice
        topic = Topic.objects.create(forum=self.forum, title=title, author=author)
        Post.objects.create(topic=topic, author=author, content=content)
        return topic


class ModelTests(ForumTestCase):
    def test_seed_forums_exist(self):
        self.assertTrue(Forum.objects.filter(name="Web security").exists())

    def test_post_stores_author_and_date(self):
        post = self.create_topic().posts.get()
        self.assertEqual(post.author, self.alice)
        self.assertIsNotNone(post.created_at)
        self.assertIsNone(post.edited_at)


class SanitizationTests(TestCase):
    def test_script_removed(self):
        self.assertEqual(sanitize_html("<script>alert(1)</script>Hello"), "Hello")

    def test_event_handler_removed(self):
        self.assertEqual(sanitize_html('<img src=x onerror="alert(1)">'), "")

    def test_javascript_url_removed(self):
        self.assertNotIn("javascript:", sanitize_html('<a href="javascript:alert(1)">x</a>'))

    def test_allowed_formatting_kept(self):
        html = "<p><strong>bold</strong> and <em>italic</em></p>"
        self.assertEqual(sanitize_html(html), html)


class FormValidationTests(TestCase):
    def test_required_fields(self):
        form = TopicForm(data={})
        self.assertIn("title", form.errors)
        self.assertIn("content", form.errors)

    def test_title_too_short(self):
        form = TopicForm(data={"title": "abc", "content": VALID_CONTENT})
        self.assertIn("title", form.errors)

    def test_title_forbidden_characters(self):
        form = TopicForm(data={"title": "<b>Hello</b>", "content": VALID_CONTENT})
        self.assertIn("title", form.errors)

    def test_content_too_long(self):
        form = PostForm(data={"content": "a" * 5001})
        self.assertIn("content", form.errors)

    def test_content_only_script_rejected(self):
        form = PostForm(data={"content": "<script>alert('xss')</script>"})
        self.assertIn("content", form.errors)

    def test_content_sanitized_on_clean(self):
        form = PostForm(data={"content": "<p>Safe text here</p><script>alert(1)</script>"})
        self.assertTrue(form.is_valid())
        self.assertEqual(form.cleaned_data["content"], "<p>Safe text here</p>")

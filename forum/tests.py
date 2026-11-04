from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from django.urls import reverse

from .models import Forum, Post, Topic

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

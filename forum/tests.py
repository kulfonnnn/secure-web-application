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


class AccessTests(ForumTestCase):
    def test_anonymous_redirected_to_login(self):
        self.client.logout()
        url = reverse("forum:forum_list")
        response = self.client.get(url)
        self.assertRedirects(response, f"{reverse('accounts:login')}?next={url}")


class TopicViewTests(ForumTestCase):
    def test_create_topic(self):
        response = self.client.post(
            reverse("forum:topic_create", args=[self.forum.pk]),
            {"title": "My first topic", "content": VALID_CONTENT},
        )
        topic = Topic.objects.get(title="My first topic")
        self.assertRedirects(response, reverse("forum:topic_detail", args=[topic.pk]))
        self.assertEqual(topic.author, self.alice)
        self.assertEqual(topic.posts.get().content, VALID_CONTENT)

    def test_topic_list_shows_topic(self):
        self.create_topic(title="Listed topic")
        response = self.client.get(reverse("forum:topic_list", args=[self.forum.pk]))
        self.assertContains(response, "Listed topic")

    def test_topic_detail_shows_posts(self):
        topic = self.create_topic()
        response = self.client.get(reverse("forum:topic_detail", args=[topic.pk]))
        self.assertContains(response, VALID_CONTENT)
        self.assertContains(response, "alice")

    def test_reply_to_topic(self):
        topic = self.create_topic()
        self.client.force_login(self.bob)
        self.client.post(
            reverse("forum:topic_detail", args=[topic.pk]), {"content": "Reply from Bob here."}
        )
        self.assertEqual(topic.posts.count(), 2)
        self.assertEqual(topic.posts.last().author, self.bob)

    def test_xss_not_rendered(self):
        self.client.post(
            reverse("forum:topic_create", args=[self.forum.pk]),
            {"title": "XSS attempt", "content": "Hello there <script>alert(1)</script>"},
        )
        topic = Topic.objects.get(title="XSS attempt")
        response = self.client.get(reverse("forum:topic_detail", args=[topic.pk]))
        self.assertNotContains(response, "<script>alert(1)</script>")


class PostOwnershipTests(ForumTestCase):
    def setUp(self):
        super().setUp()
        self.topic = self.create_topic()
        self.reply = Post.objects.create(
            topic=self.topic, author=self.alice, content="Second post by Alice."
        )

    def test_author_can_edit(self):
        response = self.client.post(
            reverse("forum:post_edit", args=[self.reply.pk]), {"content": "Edited content here."}
        )
        self.assertRedirects(response, reverse("forum:topic_detail", args=[self.topic.pk]))
        self.reply.refresh_from_db()
        self.assertEqual(self.reply.content, "Edited content here.")
        self.assertIsNotNone(self.reply.edited_at)

    def test_other_user_cannot_edit(self):
        self.client.force_login(self.bob)
        response = self.client.post(
            reverse("forum:post_edit", args=[self.reply.pk]), {"content": "Hacked by Bob!!!"}
        )
        self.assertEqual(response.status_code, 403)
        self.reply.refresh_from_db()
        self.assertEqual(self.reply.content, "Second post by Alice.")

    def test_author_can_delete_reply(self):
        self.client.post(reverse("forum:post_delete", args=[self.reply.pk]))
        self.assertFalse(Post.objects.filter(pk=self.reply.pk).exists())
        self.assertTrue(Topic.objects.filter(pk=self.topic.pk).exists())

    def test_deleting_first_post_deletes_topic(self):
        first = self.topic.posts.first()
        self.client.post(reverse("forum:post_delete", args=[first.pk]))
        self.assertFalse(Topic.objects.filter(pk=self.topic.pk).exists())

    def test_other_user_cannot_delete(self):
        self.client.force_login(self.bob)
        response = self.client.post(reverse("forum:post_delete", args=[self.reply.pk]))
        self.assertEqual(response.status_code, 403)
        self.assertTrue(Post.objects.filter(pk=self.reply.pk).exists())

    def test_staff_can_delete(self):
        self.bob.is_staff = True
        self.bob.save()
        self.client.force_login(self.bob)
        self.client.post(reverse("forum:post_delete", args=[self.reply.pk]))
        self.assertFalse(Post.objects.filter(pk=self.reply.pk).exists())


class SpamProtectionTests(ForumTestCase):
    def test_sixth_post_in_a_minute_is_blocked(self):
        topic = self.create_topic()
        url = reverse("forum:topic_detail", args=[topic.pk])
        for i in range(5):
            response = self.client.post(url, {"content": f"Reply number {i} here."})
            self.assertEqual(response.status_code, 302)
        response = self.client.post(url, {"content": "One reply too many."})
        self.assertEqual(response.status_code, 429)
        self.assertEqual(topic.posts.count(), 6)  # first post + 5 replies

    def test_too_large_request_rejected(self):
        topic = self.create_topic()
        response = self.client.post(
            reverse("forum:topic_detail", args=[topic.pk]), {"content": "a" * 300_000}
        )
        self.assertEqual(response.status_code, 400)


class SecurityHeaderTests(ForumTestCase):
    def test_csp_header_present(self):
        response = self.client.get(reverse("forum:forum_list"))
        self.assertIn("default-src 'self'", response.headers["Content-Security-Policy"])


class AdminModerationTests(ForumTestCase):
    def setUp(self):
        super().setUp()
        self.admin = User.objects.create_superuser("admin", "admin@example.com", "S3cure-pass-123")
        self.client.force_login(self.admin)
        self.topic = self.create_topic()
        self.post = self.topic.posts.get()

    def test_admin_lists_posts_and_users(self):
        response = self.client.get(reverse("admin:forum_post_changelist"))
        self.assertContains(response, VALID_CONTENT)
        response = self.client.get(reverse("admin:accounts_customuser_changelist"))
        self.assertContains(response, "alice")

    def test_admin_edit_is_sanitized(self):
        response = self.client.post(
            reverse("admin:forum_post_change", args=[self.post.pk]),
            {
                "topic": self.topic.pk,
                "author": self.alice.pk,
                "content": "<p>Moderated text here</p><script>alert(1)</script>",
            },
        )
        self.assertEqual(response.status_code, 302)
        self.post.refresh_from_db()
        self.assertEqual(self.post.content, "<p>Moderated text here</p>")

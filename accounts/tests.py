from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse


class LogoutTests(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            "alice", "alice@example.com", "S3cure-pass-123"
        )
        self.client.force_login(self.user)

    def test_logout_requires_post(self):
        response = self.client.get(reverse("accounts:logout"))
        self.assertEqual(response.status_code, 405)
        self.assertIn("_auth_user_id", self.client.session)

    def test_logout_with_post(self):
        response = self.client.post(reverse("accounts:logout"))
        self.assertRedirects(response, reverse("accounts:login"))
        self.assertNotIn("_auth_user_id", self.client.session)

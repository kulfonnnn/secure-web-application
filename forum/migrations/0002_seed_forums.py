from django.db import migrations

FORUMS = [
    ("General", "General discussion"),
    ("Web security", "XSS, CSRF, authentication and other web security topics"),
    ("Off-topic", "Everything else"),
]


def create_forums(apps, schema_editor):
    Forum = apps.get_model("forum", "Forum")
    for name, description in FORUMS:
        Forum.objects.get_or_create(name=name, defaults={"description": description})


def delete_forums(apps, schema_editor):
    Forum = apps.get_model("forum", "Forum")
    Forum.objects.filter(name__in=[name for name, _ in FORUMS]).delete()


class Migration(migrations.Migration):
    dependencies = [("forum", "0001_initial")]
    operations = [migrations.RunPython(create_forums, delete_forums)]

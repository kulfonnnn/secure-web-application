from django.db import migrations

# One general forum: users open their own topics and reply in others'.
# More forums can be added in the admin panel.
FORUMS = [
    ("General", "General discussion"),
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

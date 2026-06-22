import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("catalog", "0003_delete_shared_decks"),
    ]

    operations = [
        migrations.AlterField(
            model_name="deck",
            name="owner",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="owned_decks",
                to=settings.AUTH_USER_MODEL,
            ),
        ),
    ]

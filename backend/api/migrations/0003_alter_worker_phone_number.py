# Generated by Django 5.2.4 on 2025-07-07 14:08

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0002_alter_category_options_alter_worker_options_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='worker',
            name='phone_number',
            field=models.CharField(max_length=30),
        ),
    ]

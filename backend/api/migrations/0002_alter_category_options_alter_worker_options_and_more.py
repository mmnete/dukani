# Generated by Django 5.2.4 on 2025-07-07 14:03

import django.core.validators
import django.db.models.deletion
from decimal import Decimal
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='category',
            options={'ordering': ['name'], 'verbose_name_plural': 'Product Categories'},
        ),
        migrations.AlterModelOptions(
            name='worker',
            options={'ordering': ['first_name', 'last_name']},
        ),
        migrations.AlterField(
            model_name='globalproduct',
            name='barcode',
            field=models.CharField(blank=True, max_length=100, null=True, unique=True),
        ),
        migrations.AlterField(
            model_name='missedsaleentry',
            name='is_synced',
            field=models.BooleanField(default=False),
        ),
        migrations.AlterField(
            model_name='missedsaleentry',
            name='product',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='missed_sales_linked', to='api.product'),
        ),
        migrations.AlterField(
            model_name='missedsaleentry',
            name='recorded_at',
            field=models.DateTimeField(auto_now_add=True),
        ),
        migrations.AlterField(
            model_name='missedsaleentry',
            name='shop',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='missed_sale_entries', to='api.shop'),
        ),
        migrations.AlterField(
            model_name='missedsaleentry',
            name='worker',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='missed_sale_entries', to='api.worker'),
        ),
        migrations.AlterField(
            model_name='product',
            name='barcode',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AlterField(
            model_name='product',
            name='quality_type',
            field=models.CharField(blank=True, choices=[('GENUINE', 'Genuine'), ('USED', 'Used'), ('FAKE', 'Fake/Aftermarket'), ('REFURBISHED', 'Refurbished')], max_length=20, null=True),
        ),
        migrations.AlterField(
            model_name='product',
            name='quantity_type',
            field=models.CharField(choices=[('UNIT', 'Unit(s)'), ('WEIGHT_VOLUME', 'Weight/Volume (e.g., Kg, Liters)')], default='UNIT', max_length=20),
        ),
        migrations.AlterField(
            model_name='saleentry',
            name='is_synced',
            field=models.BooleanField(default=False),
        ),
        migrations.AlterField(
            model_name='saleentry',
            name='recorded_at',
            field=models.DateTimeField(auto_now_add=True),
        ),
        migrations.AlterField(
            model_name='saleentry',
            name='shop',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='sale_entries', to='api.shop'),
        ),
        migrations.AlterField(
            model_name='saleentry',
            name='worker',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='sale_entries', to='api.worker'),
        ),
        migrations.AlterField(
            model_name='shop',
            name='managers',
            field=models.ManyToManyField(related_name='managed_shops', to=settings.AUTH_USER_MODEL),
        ),
        migrations.AlterField(
            model_name='stockentry',
            name='is_synced',
            field=models.BooleanField(default=False),
        ),
        migrations.AlterField(
            model_name='stockentry',
            name='purchase_price',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True, validators=[django.core.validators.MinValueValidator(Decimal('0.00'))]),
        ),
        migrations.AlterField(
            model_name='stockentry',
            name='recorded_at',
            field=models.DateTimeField(auto_now_add=True),
        ),
        migrations.AlterField(
            model_name='stockentry',
            name='worker',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='stock_entries', to='api.worker'),
        ),
        migrations.AlterField(
            model_name='worker',
            name='phone_number',
            field=models.CharField(max_length=30, unique=True),
        ),
        migrations.AddConstraint(
            model_name='missedsaleentry',
            constraint=models.CheckConstraint(condition=models.Q(('product__isnull', False), ('product_name_text__isnull', False), _connector='OR'), name='product_or_product_name_text_required'),
        ),
    ]

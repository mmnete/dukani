# dukani/backend/api/models.py

import uuid
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.db.models import Sum
from decimal import Decimal
from django.utils import timezone
import string
import random
from django.core.exceptions import ValidationError

# --- Choices for quantity_type ---
QUANTITY_TYPE_CHOICES = [
    ("UNIT", "Unit(s)"),
    ("WEIGHT_VOLUME", "Weight/Volume (e.g., Kg, Liters)"),
]
UNIT = "UNIT"  # Constant for 'Unit' quantity type
WEIGHT_VOLUME = "WEIGHT_VOLUME"

# --- Choices for quality_type (NEW) ---
QUALITY_TYPE_CHOICES = [
    ("GENUINE", "Genuine"),
    ("USED", "Used"),
    ("FAKE", "Fake/Aftermarket"),
    ("REFURBISHED", "Refurbished"),
]
GENUINE = "GENUINE"
USED = "USED"
FAKE = "FAKE"
REFURBISHED = "REFURBISHED"

# --- Choices for product status (NEW) ---
PRODUCT_STATUS_CHOICES = [
    ("PENDING_REVIEW", "Pending Review"),  # Newly added product, needs manager review
    ("REVIEWED", "Reviewed"),  # Manager has reviewed and approved
    (
        "LINKED",
        "Linked to Global Product",
    ),  # Automatically set if linked to GlobalProduct
    ("ARCHIVED", "Archived"),  # Product is no longer active
]
PENDING_REVIEW = "PENDING_REVIEW"
REVIEWED = "REVIEWED"
LINKED = "LINKED"
ARCHIVED = "ARCHIVED"


# --- Shop Category Model ---
class ShopCategory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Shop Categories"
        ordering = ["name"]

    def __str__(self):
        return self.name


# --- Shop Model ---
class Shop(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, unique=True)
    business_id = models.CharField(max_length=100, unique=True, blank=True, null=True)
    address = models.CharField(max_length=255, blank=True, null=True)
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, blank=True, null=True
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, blank=True, null=True
    )
    managers = models.ManyToManyField(User, related_name="managed_shops")
    categories = models.ManyToManyField(ShopCategory, related_name="shops", blank=True)
    require_image_upload = models.BooleanField(default=False)  # NEW FIELD
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


# --- Worker Model ---
class Worker(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    shop = models.ForeignKey(Shop, on_delete=models.CASCADE, related_name="workers")
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100, blank=True, null=True)
    phone_number = models.CharField(
        max_length=30
    )  # Used for worker identification/login
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["first_name", "last_name"]
        unique_together = (
            "shop",
            "phone_number",
        )  # A phone number should be unique per shop

    def __str__(self):
        return f"{self.first_name} {self.last_name or ''} ({self.shop.name})"

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name or ''}".strip()


# --- Product Category Model (for Global Products) ---
class Category(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Product Categories"
        ordering = ["name"]

    def __str__(self):
        return self.name


# --- Global Product Catalog Model ---
class GlobalProduct(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, unique=True)
    barcode = models.CharField(max_length=100, unique=True, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    image = models.ImageField(
        upload_to="global_product_images/", blank=True, null=True
    )  # CHANGED from image_url
    suggested_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        validators=[MinValueValidator(Decimal("0.00"))],
    )
    category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        related_name="global_products",
        blank=True,
        null=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


# --- Shop-Specific Product Model ---
class Product(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    shop = models.ForeignKey(Shop, on_delete=models.CASCADE, related_name="products")
    global_product = models.ForeignKey(
        GlobalProduct,
        on_delete=models.SET_NULL,
        related_name="shop_products",
        blank=True,
        null=True,
    )
    name = models.CharField(
        max_length=255
    )  # Shop-specific name (can override global or be unique)
    barcode = models.CharField(
        max_length=100, blank=True, null=True
    )  # Shop-specific barcode (can override global or be unique)
    description = models.TextField(blank=True, null=True)
    price = models.DecimalField(
        max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal("0.00"))]
    )  # Shop-specific selling price
    quantity_type = models.CharField(
        max_length=20, choices=QUANTITY_TYPE_CHOICES, default="UNIT"
    )
    quality_type = models.CharField(
        max_length=20, choices=QUALITY_TYPE_CHOICES, blank=True, null=True
    )  # NEW FIELD
    status = models.CharField(
        max_length=20, choices=PRODUCT_STATUS_CHOICES, default=PENDING_REVIEW
    )  # NEW FIELD
    image = models.ImageField(
        upload_to="shop_product_images/", blank=True, null=True
    )  # CHANGED from image_url
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["shop", "name"]
        unique_together = (
            "shop",
            "name",
        )  # A product name must be unique within a given shop

    def __str__(self):
        return f"{self.name} ({self.shop.name})"

    @property
    def current_stock(self):
        """
        Calculates the current stock of the product in this specific shop.
        """
        total_received = self.stock_received.aggregate(Sum("quantity"))[
            "quantity__sum"
        ] or Decimal("0.000")
        total_sold = self.sales.aggregate(Sum("quantity"))["quantity__sum"] or Decimal(
            "0.000"
        )
        return total_received - total_sold


# --- Stock Entry Model ---
class StockEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    shop = models.ForeignKey(
        Shop, on_delete=models.CASCADE, related_name="stock_entries"
    )
    worker = models.ForeignKey(
        Worker,
        on_delete=models.SET_NULL,
        related_name="stock_entries",
        blank=True,
        null=True,
    )
    product = models.ForeignKey(
        Product, on_delete=models.CASCADE, related_name="stock_received"
    )
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        validators=[MinValueValidator(Decimal("0.001"))],
    )  # Allow decimals for weight/volume
    purchase_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        validators=[MinValueValidator(Decimal("0.00"))],
    )
    notes = models.TextField(blank=True, null=True)
    recorded_at = models.DateTimeField(auto_now_add=True)
    is_synced = models.BooleanField(default=False)  # For mobile app synchronization

    class Meta:
        verbose_name_plural = "Stock Entries"
        ordering = ["-recorded_at"]

    def __str__(self):
        return f"Stock: {self.product.name} - {self.quantity} {self.product.quantity_type} in {self.shop.name}"


# --- Sale Entry Model ---
class SaleEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    shop = models.ForeignKey(
        Shop, on_delete=models.CASCADE, related_name="sale_entries"
    )
    worker = models.ForeignKey(
        Worker,
        on_delete=models.SET_NULL,
        related_name="sale_entries",
        blank=True,
        null=True,
    )  # CORRECTED: on_on_delete to on_delete
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name="sales")
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        validators=[MinValueValidator(Decimal("0.001"))],
    )
    selling_price = models.DecimalField(
        max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal("0.00"))]
    )
    notes = models.TextField(blank=True, null=True)
    recorded_at = models.DateTimeField(auto_now_add=True)
    is_synced = models.BooleanField(default=False)  # For mobile app synchronization

    class Meta:
        verbose_name_plural = "Sale Entries"
        ordering = ["-recorded_at"]

    def __str__(self):
        return f"Sale: {self.product.name} - {self.quantity} {self.product.quantity_type} for {self.selling_price} in {self.shop.name}"


# --- Missed Sale Entry Model ---
class MissedSaleEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    shop = models.ForeignKey(
        Shop, on_delete=models.CASCADE, related_name="missed_sale_entries"
    )
    worker = models.ForeignKey(
        Worker,
        on_delete=models.SET_NULL,
        related_name="missed_sale_entries",
        blank=True,
        null=True,
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.SET_NULL,
        related_name="missed_sales_linked",
        blank=True,
        null=True,
    )  # Link to existing product if applicable
    product_name_text = models.CharField(
        max_length=255, blank=True, null=True
    )  # For free-text entry if product not found
    quantity_requested = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        validators=[MinValueValidator(Decimal("0.001"))],
    )
    reason = models.TextField(
        blank=True, null=True
    )  # E.g., "Out of stock", "Not carried"
    notes = models.TextField(blank=True, null=True)
    recorded_at = models.DateTimeField(auto_now_add=True)
    is_synced = models.BooleanField(default=False)  # For mobile app synchronization

    class Meta:
        verbose_name_plural = "Missed Sale Entries"
        ordering = ["-recorded_at"]
        # Add a check to ensure either product or product_name_text is provided
        constraints = [
            models.CheckConstraint(
                check=models.Q(product__isnull=False)
                | models.Q(product_name_text__isnull=False),
                name="product_or_product_name_text_required",
            )
        ]

    def __str__(self):
        product_info = self.product.name if self.product else self.product_name_text
        return f"Missed Sale: {product_info} - {self.quantity_requested} in {self.shop.name} ({self.reason})"


class InviteToken(models.Model):
    worker = models.OneToOneField(
        "Worker", on_delete=models.CASCADE, related_name="invite_token"
    )
    shop = models.ForeignKey(
        "Shop", on_delete=models.CASCADE, related_name="invite_tokens"
    )
    created_by = models.ForeignKey(
        "auth.User",
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_invite_tokens",
    )
    code = models.CharField(max_length=12, unique=True)
    expires_at = models.DateTimeField()

    def is_valid(self):
        return timezone.now() < self.expires_at

    def clean(self):
        # Ensure only one active token per worker per shop
        if (
            InviteToken.objects.filter(
                worker=self.worker, shop=self.shop, expires_at__gt=timezone.now()
            )
            .exclude(pk=self.pk)
            .exists()
        ):
            raise ValidationError(
                "An active invite token already exists for this worker and shop."
            )

    def _generate_unique_code(self):
        length = 8
        chars = string.ascii_uppercase + string.digits
        while True:
            new_code = "".join(random.choices(chars, k=length))
            if not InviteToken.objects.filter(code=new_code).exists():
                return new_code

    def save(self, *args, **kwargs):
        if not self.code:
            self.code = self._generate_unique_code()

        self.full_clean()  # Calls clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"InviteToken(code={self.code}, worker={self.worker}, shop={self.shop})"

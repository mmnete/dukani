# dukani/backend/api/serializers.py

from rest_framework import serializers
from django.contrib.auth.models import User
from decimal import Decimal
from django.db import transaction
from django.db.utils import IntegrityError
from django.db.models import F
from django.core.files.uploadedfile import InMemoryUploadedFile  # For image handling
import imghdr  # To validate image type

from .models import (
    Shop,
    Worker,
    Category,
    GlobalProduct,
    Product,
    StockEntry,
    SaleEntry,
    MissedSaleEntry,
    ShopCategory,
    QUANTITY_TYPE_CHOICES,
    QUALITY_TYPE_CHOICES,
    PRODUCT_STATUS_CHOICES,
    UNIT,
    PENDING_REVIEW,
    LINKED,
)


# --- ShopCategory Serializer ---
class ShopCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ShopCategory
        fields = "__all__"


# --- User Serializer (for managers in ShopSerializer) ---
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "first_name", "last_name"]
        read_only_fields = ["username", "email"]


# --- Shop Serializer ---
class ShopSerializer(serializers.ModelSerializer):
    managers = serializers.PrimaryKeyRelatedField(
        many=True, queryset=User.objects.all(), required=False
    )
    categories = serializers.PrimaryKeyRelatedField(
        many=True, queryset=ShopCategory.objects.all(), required=False
    )
    manager_usernames = serializers.SerializerMethodField()
    category_names = serializers.SerializerMethodField()

    class Meta:
        model = Shop
        fields = [
            "id",
            "name",
            "business_id",
            "address",
            "latitude",
            "longitude",
            "managers",
            "categories",
            "manager_usernames",
            "category_names",
            "require_image_upload",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def get_manager_usernames(self, obj):
        return [manager.username for manager in obj.managers.all()]

    def get_category_names(self, obj):
        return [category.name for category in obj.categories.all()]

    def create(self, validated_data):
        managers_data = validated_data.pop("managers", [])
        categories_data = validated_data.pop("categories", [])
        shop = Shop.objects.create(**validated_data)
        shop.managers.set(managers_data)
        shop.categories.set(categories_data)
        return shop

    def update(self, instance, validated_data):
        managers_data = validated_data.pop("managers", None)
        categories_data = validated_data.pop("categories", None)

        instance = super().update(instance, validated_data)

        if managers_data is not None:
            instance.managers.set(managers_data)
        if categories_data is not None:
            instance.categories.set(categories_data)
        return instance


# --- Worker Serializer ---
class WorkerSerializer(serializers.ModelSerializer):
    shop = serializers.PrimaryKeyRelatedField(queryset=Shop.objects.all())
    shop_name = serializers.CharField(source="shop.name", read_only=True)
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = Worker
        fields = [
            "id",
            "shop",
            "shop_name",
            "first_name",
            "last_name",
            "full_name",
            "phone_number",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def validate(self, data):
        if self.instance:
            if (
                Worker.objects.filter(
                    shop=data["shop"], phone_number=data["phone_number"]
                )
                .exclude(id=self.instance.id)
                .exists()
            ):
                raise serializers.ValidationError(
                    "A worker with this phone number already exists in this shop."
                )
        else:
            if Worker.objects.filter(
                shop=data["shop"], phone_number=data["phone_number"]
            ).exists():
                raise serializers.ValidationError(
                    "A worker with this phone number already exists in this shop."
                )
        return data


# --- Category Serializer (for Product Categories) ---
class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = "__all__"


# --- GlobalProduct Serializer ---
class GlobalProductSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(), allow_null=True, required=False
    )
    category_name = serializers.CharField(source="category.name", read_only=True)
    image = serializers.ImageField(
        required=False, allow_null=True, use_url=False
    )  # REMOVED THIS LINE

    class Meta:
        model = GlobalProduct
        fields = [
            "id",
            "name",
            "barcode",
            "description",
            "image",
            "suggested_price",
            "category",
            "category_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]


# --- Product Serializer (Shop-Specific Product) ---
class ProductSerializer(serializers.ModelSerializer):
    shop = serializers.PrimaryKeyRelatedField(queryset=Shop.objects.all())
    shop_name = serializers.CharField(source="shop.name", read_only=True)

    global_product_id = serializers.PrimaryKeyRelatedField(
        queryset=GlobalProduct.objects.all(),
        write_only=True,
        required=False,
        allow_null=True,
    )

    global_product_name = serializers.CharField(
        source="global_product.name", read_only=True
    )
    global_product_category_name = serializers.CharField(
        source="global_product.category.name", read_only=True
    )

    # New fields for Product
    image = serializers.ImageField(
        required=False, allow_null=True, use_url=False
    )  # REMOVED THIS LINE
    quality_type = serializers.ChoiceField(
        choices=QUALITY_TYPE_CHOICES, required=False, allow_blank=True, allow_null=True
    )
    status = serializers.ChoiceField(
        choices=PRODUCT_STATUS_CHOICES, read_only=False
    )  # Status is set internally

    # Fields for creating a new GlobalProduct on the fly
    new_global_product_name = serializers.CharField(
        write_only=True, required=False, allow_blank=True
    )
    new_global_product_barcode = serializers.CharField(
        write_only=True, required=False, allow_blank=True
    )
    new_global_product_description = serializers.CharField(
        write_only=True, required=False, allow_blank=True
    )
    new_global_product_suggested_price = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        write_only=True,
        required=False,
        allow_null=True,
    )
    new_global_product_category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = Product
        fields = [
            "id",
            "shop",
            "shop_name",
            "global_product",
            "global_product_id",
            "global_product_name",
            "global_product_category_name",
            "name",
            "barcode",
            "description",
            "price",
            "quantity_type",
            "quality_type",
            "image",
            "status",
            "created_at",
            "updated_at",
            "new_global_product_name",
            "new_global_product_barcode",
            "new_global_product_description",
            "new_global_product_suggested_price",
            "new_global_product_category_id",
        ]
        read_only_fields = ["created_at", "updated_at"]

    def validate(self, data):
        global_product_id = data.get("global_product_id")
        new_global_product_name = data.get("new_global_product_name")
        new_global_product_suggested_price = data.get(
            "new_global_product_suggested_price"
        )

        if global_product_id and new_global_product_name:
            raise serializers.ValidationError(
                "Cannot provide both an existing 'global_product_id' and 'new_global_product_name'."
            )

        if new_global_product_name and not new_global_product_suggested_price:
            raise serializers.ValidationError(
                "Suggested price is required for new global products."
            )

        return data

    @transaction.atomic
    def create(self, validated_data):
        global_product_id = validated_data.pop("global_product_id", None)
        new_global_product_name = validated_data.pop("new_global_product_name", None)
        new_global_product_barcode = validated_data.pop(
            "new_global_product_barcode", None
        )
        new_global_product_description = validated_data.pop(
            "new_global_product_description", None
        )
        new_global_product_suggested_price = validated_data.pop(
            "new_global_product_suggested_price", None
        )
        new_global_product_category_id = validated_data.pop(
            "new_global_product_category_id", None
        )

        global_product_instance = None

        if global_product_id:
            global_product_instance = global_product_id
        elif new_global_product_name:
            global_product_instance = GlobalProduct.objects.create(
                name=new_global_product_name,
                barcode=new_global_product_barcode,
                description=new_global_product_description,
                suggested_price=new_global_product_suggested_price,
                category=new_global_product_category_id,
            )

        # Set initial status for new products
        validated_data["status"] = LINKED if global_product_instance else PENDING_REVIEW

        product = Product.objects.create(
            global_product=global_product_instance, **validated_data
        )
        return product

    @transaction.atomic
    def update(self, instance, validated_data):
        global_product_id = validated_data.pop("global_product_id", None)
        new_global_product_name = validated_data.pop("new_global_product_name", None)
        new_global_product_barcode = validated_data.pop(
            "new_global_product_barcode", None
        )
        new_global_product_description = validated_data.pop(
            "new_global_product_description", None
        )
        new_global_product_suggested_price = validated_data.pop(
            "new_global_product_suggested_price", None
        )
        new_global_product_category_id = validated_data.pop(
            "new_global_product_category_id", None
        )

        if global_product_id:
            instance.global_product = global_product_id
            instance.status = LINKED  # Update status if linked
        elif new_global_product_name:
            new_global_product_instance = GlobalProduct.objects.create(
                name=new_global_product_name,
                barcode=new_global_product_barcode,
                description=new_global_product_description,
                suggested_price=new_global_product_suggested_price,
                category=new_global_product_category_id,
            )
            instance.global_product = new_global_product_instance
            instance.status = (
                LINKED  # Update status if new global product is created and linked
            )
        elif (
            "global_product_id" in self.initial_data
            and not global_product_id
            and not new_global_product_name
        ):
            instance.global_product = None
            instance.status = PENDING_REVIEW  # Set to pending review if unlinked

        # Update status if explicitly provided (e.g., manager changing from PENDING_REVIEW to REVIEWED)
        if "status" in validated_data:
            instance.status = validated_data.pop("status")

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        instance.save()
        return instance


# --- StockEntry Serializer ---
class StockEntrySerializer(serializers.ModelSerializer):
    shop = serializers.PrimaryKeyRelatedField(queryset=Shop.objects.all())
    worker = serializers.PrimaryKeyRelatedField(queryset=Worker.objects.all())

    # Existing product ID (optional if creating new product on the fly)
    product = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(), required=False, allow_null=True
    )

    # Fields for creating a new product on the fly via stock entry
    product_name_text = serializers.CharField(
        max_length=255,
        required=False,
        allow_blank=True,
        help_text="Provide product name if product ID is not known or for new items.",
    )
    barcode_text = serializers.CharField(
        max_length=255,
        required=False,
        allow_blank=True,
        help_text="Provide barcode if scanning a new item.",
    )
    product_quantity_type = serializers.ChoiceField(
        choices=QUANTITY_TYPE_CHOICES,
        required=False,
        help_text="Quantity type for new product (UNIT, WEIGHT_VOLUME).",
    )
    product_quality_type = serializers.ChoiceField(
        choices=QUALITY_TYPE_CHOICES,
        required=False,
        allow_blank=True,
        allow_null=True,
        help_text="Quality type for new product (Genuine, Used, Fake, etc.).",
    )
    image_file = serializers.ImageField(
        required=False,
        allow_null=True,
        write_only=True,  # This field is only for upload, not for reading back
        help_text="Image file for a new product, if required by shop settings.",
    )

    class Meta:
        model = StockEntry
        fields = [
            "id",
            "shop",
            "worker",
            "product",
            "product_name_text",
            "barcode_text",
            "product_quantity_type",
            "product_quality_type",
            "image_file",
            "quantity",
            "purchase_price",
            "notes",
            "recorded_at",
            "is_synced",
        ]
        read_only_fields = ["recorded_at", "is_synced"]

    def validate_image_file(self, value):
        if value:
            # Basic check to ensure it's an image
            if not isinstance(value, InMemoryUploadedFile):
                raise serializers.ValidationError("Invalid image file format.")

            # Read a small chunk to determine image type
            file_start = value.read(1024)
            value.seek(0)  # Reset file pointer

            img_type = imghdr.what(None, file_start)
            if img_type not in [
                "jpeg",
                "png",
                "gif",
                "bmp",
                "tiff",
            ]:  # Common image types
                raise serializers.ValidationError(
                    "Uploaded file is not a recognized image type."
                )
        return value

    def validate(self, data):
        product = data.get("product")
        product_name_text = data.get("product_name_text")
        barcode_text = data.get("barcode_text")
        quantity = data["quantity"]
        shop = data["shop"]
        worker = data["worker"]
        image_file = data.get("image_file")

        # Validate worker belongs to shop
        if worker.shop != shop:
            raise serializers.ValidationError(
                {"worker": "Worker is not assigned to the specified shop."}
            )

        # Validate product relationship to shop
        if product and product.shop != shop:
            raise serializers.ValidationError(
                {"product": "Product is not assigned to the specified shop."}
            )

        # Ensure either product ID OR (product_name_text or barcode_text) is provided
        if product and (product_name_text or barcode_text):
            raise serializers.ValidationError(
                "Cannot provide both an existing 'product' ID and new product details ('product_name_text' or 'barcode_text')."
            )
        if not product and not (product_name_text or barcode_text):
            raise serializers.ValidationError(
                "Either 'product' ID or new product details ('product_name_text' or 'barcode_text') must be provided."
            )

        # If creating a new product, name is mandatory
        if not product and not product_name_text:
            raise serializers.ValidationError(
                {
                    "product_name_text": "Product name is required when creating a new product."
                }
            )

        # Check if image upload is required by the shop
        if shop.require_image_upload and not product and not image_file:
            raise serializers.ValidationError(
                {
                    "image_file": "Image upload is required for new products in this shop."
                }
            )

        # Determine the product's quantity_type for validation
        target_product_type = None
        if product:
            target_product_type = product.quantity_type
        elif "product_quantity_type" in data:
            target_product_type = data["product_quantity_type"]
        else:
            target_product_type = UNIT  # Default for new products if not specified

        if target_product_type == UNIT:
            if quantity % 1 != 0:
                raise serializers.ValidationError(
                    {
                        "quantity": f"Quantity must be a whole number for '{UNIT}' type products."
                    }
                )

        return data

    @transaction.atomic
    def create(self, validated_data):
        product_instance = validated_data.get("product")
        product_name_text = validated_data.pop("product_name_text", None)
        barcode_text = validated_data.pop("barcode_text", None)
        product_quantity_type = validated_data.pop(
            "product_quantity_type", UNIT
        )  # Default to UNIT
        product_quality_type = validated_data.pop("product_quality_type", None)
        image_file = validated_data.pop("image_file", None)
        shop = validated_data["shop"]

        if not product_instance:  # If no existing product ID was provided
            # Try to find an existing Product in THIS shop by name or barcode
            if product_name_text:  # Prioritize name search
                try:
                    product_instance = Product.objects.get(
                        shop=shop, name=product_name_text
                    )
                except Product.DoesNotExist:
                    pass

            if (
                not product_instance and barcode_text
            ):  # Then try barcode search if name didn't yield
                try:
                    product_instance = Product.objects.get(
                        shop=shop, barcode=barcode_text
                    )
                except Product.DoesNotExist:
                    pass

            if (
                not product_instance
            ):  # If still no product found, create a new one for this shop
                new_product_data = {
                    "shop": shop,
                    "name": product_name_text,
                    "barcode": barcode_text,
                    "quantity_type": product_quantity_type,
                    "quality_type": product_quality_type,
                    "price": validated_data.get(
                        "purchase_price", Decimal("0.00")
                    ),  # Use purchase price as initial selling price
                    "image": image_file,  # Assign the uploaded image
                    "global_product": None,  # No global product linked initially
                    "status": PENDING_REVIEW,  # Mark for manager review
                }
                product_instance = Product.objects.create(**new_product_data)

        # Assign the found/created product instance to the validated data for StockEntry
        validated_data["product"] = product_instance
        stock_entry = StockEntry.objects.create(**validated_data)
        return stock_entry


# --- SaleEntry Serializer ---
class SaleEntrySerializer(serializers.ModelSerializer):
    shop = serializers.PrimaryKeyRelatedField(queryset=Shop.objects.all())
    worker = serializers.PrimaryKeyRelatedField(queryset=Worker.objects.all())
    product = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all())

    class Meta:
        model = SaleEntry
        fields = [
            "id",
            "shop",
            "worker",
            "product",
            "quantity",
            "selling_price",
            "notes",
            "recorded_at",
            "is_synced",
        ]
        read_only_fields = ["recorded_at", "is_synced"]

    def validate(self, data):
        product = data["product"]
        quantity = data["quantity"]
        shop = data["shop"]
        worker = data["worker"]

        # Validate that the worker belongs to the specified shop
        if worker.shop != shop:
            raise serializers.ValidationError(
                {"worker": "Worker is not assigned to the specified shop."}
            )

        # Validate that the product belongs to the specified shop
        if product.shop != shop:
            raise serializers.ValidationError(
                {"product": "Product is not assigned to the specified shop."}
            )

        # Validate quantity based on product type
        if product.quantity_type == UNIT:
            if quantity % 1 != 0:
                raise serializers.ValidationError(
                    {
                        "quantity": f"Quantity must be a whole number for '{UNIT}' type products."
                    }
                )
        return data

    @transaction.atomic
    def create(self, validated_data):
        product = validated_data["product"]
        quantity = validated_data["quantity"]

        # Check if there's enough stock
        if product.current_stock < quantity:
            raise serializers.ValidationError(
                {
                    "quantity": f"Not enough stock for {product.name}. Current stock: {product.current_stock}"
                }
            )

        sale_entry = SaleEntry.objects.create(**validated_data)
        return sale_entry


# --- MissedSaleEntry Serializer ---
class MissedSaleEntrySerializer(serializers.ModelSerializer):
    shop = serializers.PrimaryKeyRelatedField(queryset=Shop.objects.all())
    worker = serializers.PrimaryKeyRelatedField(queryset=Worker.objects.all())

    product = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(), required=False, allow_null=True
    )
    product_name_text = serializers.CharField(
        max_length=255, required=False, allow_blank=True
    )

    class Meta:
        model = MissedSaleEntry
        fields = [
            "id",
            "shop",
            "worker",
            "product",
            "product_name_text",
            "quantity_requested",
            "reason",
            "notes",
            "recorded_at",
            "is_synced",
        ]
        read_only_fields = ["recorded_at", "is_synced"]

    def validate(self, data):
        product = data.get("product")
        product_name_text = data.get("product_name_text")
        quantity_requested = data["quantity_requested"]
        shop = data["shop"]
        worker = data["worker"]

        if worker.shop != shop:
            raise serializers.ValidationError(
                {"worker": "Worker is not assigned to the specified shop."}
            )

        if not product and not product_name_text:
            raise serializers.ValidationError(
                "Either 'product' or 'product_name_text' must be provided."
            )
        if product and product_name_text:
            raise serializers.ValidationError(
                "Cannot provide both 'product' and 'product_name_text'. Choose one."
            )

        if product and product.shop != shop:
            raise serializers.ValidationError(
                {"product": "Product is not assigned to the specified shop."}
            )

        # Quantity validation for missed sales:
        # If product is linked, use its quantity_type.
        # If not linked (text-based), assume UNIT for validation.
        target_quantity_type = product.quantity_type if product else UNIT

        if target_quantity_type == UNIT:
            if quantity_requested % 1 != 0:
                raise serializers.ValidationError(
                    {
                        "quantity_requested": f"Quantity must be a whole number for '{UNIT}' type products."
                    }
                )

        return data


class StockEntryCreateUpdateSerializer(serializers.Serializer):
    # Fields for existing product
    shop = serializers.PrimaryKeyRelatedField(queryset=Shop.objects.all())
    worker = serializers.PrimaryKeyRelatedField(queryset=Worker.objects.all())
    product = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(), required=False, allow_null=True
    )

    # Fields for creating new product on the fly
    product_name_text = serializers.CharField(
        max_length=255, required=False, allow_blank=True
    )
    barcode_text = serializers.CharField(
        max_length=50, required=False, allow_blank=True
    )
    description_text = serializers.CharField(
        max_length=255, required=False, allow_blank=True
    )  # For new product description
    price = serializers.DecimalField(
        max_digits=10, decimal_places=2, required=False, allow_null=True
    )  # Price for new product
    image_file = serializers.ImageField(required=False, allow_null=True)

    # Common fields for stock entry
    quantity = serializers.DecimalField(max_digits=10, decimal_places=3)
    purchase_price = serializers.DecimalField(
        max_digits=10, decimal_places=2, required=False, allow_null=True
    )
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate(self, data):
        product = data.get("product")
        product_name_text = data.get("product_name_text")

        if not product and not product_name_text:
            raise serializers.ValidationError(
                "Either 'product' ID or 'product_name_text' must be provided."
            )
        if product and product_name_text:
            raise serializers.ValidationError(
                "Provide either 'product' ID or 'product_name_text', not both."
            )

        if product:
            # If an existing product is selected, ensure it belongs to the specified shop
            if product.shop != data["shop"]:
                raise serializers.ValidationError(
                    {
                        "product": "The selected product does not belong to the specified shop."
                    }
                )
            # If quantity type is UNIT, ensure quantity is a whole number
            if product.quantity_type == UNIT and data["quantity"] % 1 != 0:
                raise serializers.ValidationError(
                    {
                        "quantity": "Quantity must be a whole number for unit-based products."
                    }
                )
        elif product_name_text:
            # If creating a new product, ensure price is provided if not explicitly null
            if data.get("price") is None:
                raise serializers.ValidationError(
                    {"price": "Price is required for new products."}
                )
            # Ensure quantity is a whole number for new UNIT products (default UNIT)
            if data["quantity"] % 1 != 0:  # Assuming new products default to UNIT
                raise serializers.ValidationError(
                    {
                        "quantity": "Quantity must be a whole number for new unit-based products."
                    }
                )

        if data["quantity"] <= 0:
            raise serializers.ValidationError(
                {"quantity": "Quantity must be greater than 0."}
            )
        if data.get("purchase_price") is not None and data["purchase_price"] <= 0:
            raise serializers.ValidationError(
                {"purchase_price": "Purchase price must be greater than 0."}
            )

        return data

    def create(self, validated_data):
        # Extract fields related to new product creation
        shop = validated_data.pop("shop")
        worker = validated_data.pop("worker")
        product = validated_data.pop(
            "product", None
        )  # Pop product, might be None for new product
        product_name_text = validated_data.pop("product_name_text", None)
        barcode_text = validated_data.pop("barcode_text", None)
        description_text = validated_data.pop("description_text", None)
        price = validated_data.pop("price", None)
        image_file = validated_data.pop("image_file", None)

        if product_name_text and not product:
            # Create a new Product instance if product_name_text is provided and no existing product is linked
            product = Product.objects.create(
                shop=shop,
                name=product_name_text,
                barcode=barcode_text,
                description=description_text,
                price=(
                    price if price is not None else Decimal("0.00")
                ),  # Use provided price or default
                quantity_type=UNIT,  # Default to UNIT for new products
                status=PENDING_REVIEW,  # New products are pending review by default
                image=image_file,
            )

        # Ensure product is set for the StockEntry
        if not product:
            raise serializers.ValidationError(
                {"product": "Product must be provided or created."}
            )

        # Create the StockEntry instance using the resolved product
        stock_entry = StockEntry.objects.create(
            shop=shop,
            worker=worker,
            product=product,
            **validated_data,  # Pass remaining validated data (quantity, purchase_price, notes)
        )
        return stock_entry

    def update(self, instance, validated_data):
        pass  # Not used for this action

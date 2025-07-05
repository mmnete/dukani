# dukani/backend/api/serializers.py

from rest_framework import serializers
from django.contrib.auth.models import User
from decimal import Decimal  # Import Decimal for comparisons
from django.db import transaction
from django.db.utils import IntegrityError
from django.db.models import F  # Import F object for database expressions

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
        read_only_fields = [
            "username",
            "email",
        ]  # Prevent direct modification via shop serializer


# --- Shop Serializer ---
class ShopSerializer(serializers.ModelSerializer):
    managers = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=User.objects.all(),
        required=False,  # Managers can be added after shop creation
    )
    categories = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=ShopCategory.objects.all(),
        required=False,  # Categories can be added after shop creation
    )
    # Read-only fields to display names instead of UUIDs
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
    full_name = serializers.CharField(read_only=True)  # From Worker model property

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
        # Ensure that a worker's phone number is unique within their shop
        if self.instance:  # If updating an existing worker
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
        else:  # If creating a new worker
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

    class Meta:
        model = GlobalProduct
        fields = [
            "id",
            "name",
            "barcode",
            "description",
            "image_url",
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

    # This field is for writing (input) the global product ID
    global_product_id = serializers.PrimaryKeyRelatedField(
        queryset=GlobalProduct.objects.all(),
        write_only=True,  # This field is only for input
        required=False,
        allow_null=True,
    )

    # These fields are for reading (output) information about the linked global product
    global_product_name = serializers.CharField(
        source="global_product.name", read_only=True
    )
    global_product_category_name = serializers.CharField(
        source="global_product.category.name", read_only=True
    )

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
            "global_product",  # This will be read-only by default as it's a ForeignKey
            "global_product_id",
            "global_product_name",
            "global_product_category_name",
            "name",
            "barcode",
            "description",
            "price",
            "quantity_type",
            "image_url",
            "created_at",
            "updated_at",
            "new_global_product_name",
            "new_global_product_barcode",
            "new_global_product_description",
            "new_global_product_suggested_price",
            "new_global_product_category_id",
        ]
        read_only_fields = ["created_at", "updated_at"]
        # No need for extra_kwargs for global_product as it's handled by its nature as a ForeignKey
        # and the explicit global_product_id for writing.

    def validate(self, data):
        global_product_id = data.get("global_product_id")
        new_global_product_name = data.get("new_global_product_name")
        new_global_product_suggested_price = data.get(
            "new_global_product_suggested_price"
        )
        new_global_product_category_id = data.get("new_global_product_category_id")

        # Rule 1: Cannot provide both existing global_product_id and new global product info
        if global_product_id and new_global_product_name:
            raise serializers.ValidationError(
                "Cannot provide both an existing 'global_product_id' and 'new_global_product_name'."
            )

        # Rule 2: If creating a new global product, name and suggested_price are required
        if new_global_product_name and not new_global_product_suggested_price:
            raise serializers.ValidationError(
                "Suggested price is required for new global products."
            )

        # Removed custom validation for 'shop' and 'name' uniqueness
        # Django's UniqueTogetherValidator will handle this if configured in the model.

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
            # Create a new GlobalProduct
            global_product_instance = GlobalProduct.objects.create(
                name=new_global_product_name,
                barcode=new_global_product_barcode,
                description=new_global_product_description,
                suggested_price=new_global_product_suggested_price,
                category=new_global_product_category_id,
            )

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
        elif new_global_product_name:
            # Create a new GlobalProduct and link it
            new_global_product_instance = GlobalProduct.objects.create(
                name=new_global_product_name,
                barcode=new_global_product_barcode,
                description=new_global_product_description,
                suggested_price=new_global_product_suggested_price,
                category=new_global_product_category_id,
            )
            instance.global_product = new_global_product_instance
        elif (
            "global_product_id" in self.initial_data
            and not global_product_id
            and not new_global_product_name
        ):
            # If global_product_id was explicitly sent as null, set it to null
            instance.global_product = None

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        instance.save()
        return instance


# --- StockEntry Serializer ---
class StockEntrySerializer(serializers.ModelSerializer):
    shop = serializers.PrimaryKeyRelatedField(queryset=Shop.objects.all())
    worker = serializers.PrimaryKeyRelatedField(queryset=Worker.objects.all())
    product = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all())

    class Meta:
        model = StockEntry
        fields = [
            "id",
            "shop",
            "worker",
            "product",
            "quantity",
            "purchase_price",
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
        if product.quantity_type == "UNIT":
            # Check if quantity has a fractional part for UNIT type
            if quantity % 1 != 0:  # Correct way to check if Decimal is a whole number
                raise serializers.ValidationError(
                    {
                        "quantity": "Quantity must be a whole number for 'UNIT' type products."
                    }
                )
        return data


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
        if product.quantity_type == "UNIT":
            # Check if quantity has a fractional part for UNIT type
            if quantity % 1 != 0:  # Correct way to check if Decimal is a whole number
                raise serializers.ValidationError(
                    {
                        "quantity": "Quantity must be a whole number for 'UNIT' type products."
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

        # Create the sale entry
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

        # Validate that the worker belongs to the specified shop
        if worker.shop != shop:
            raise serializers.ValidationError(
                {"worker": "Worker is not assigned to the specified shop."}
            )

        # Ensure either product or product_name_text is provided, but not both
        if not product and not product_name_text:
            raise serializers.ValidationError(
                "Either 'product' or 'product_name_text' must be provided."
            )
        if product and product_name_text:
            raise serializers.ValidationError(
                "Cannot provide both 'product' and 'product_name_text'. Choose one."
            )

        # If a product is linked, validate it belongs to the specified shop
        if product and product.shop != shop:
            raise serializers.ValidationError(
                {"product": "Product is not assigned to the specified shop."}
            )

        # If a product is linked and is of type 'UNIT', validate quantity is a whole number
        if product and product.quantity_type == "UNIT":
            if (
                quantity_requested % 1 != 0
            ):  # Correct way to check if Decimal is a whole number
                raise serializers.ValidationError(
                    {
                        "quantity_requested": "Quantity must be a whole number for 'UNIT' type products."
                    }
                )
        # If no product is linked (i.e., product_name_text is used), assume UNIT type and validate quantity is a whole number
        elif not product and quantity_requested % 1 != 0:
            raise serializers.ValidationError(
                {
                    "quantity_requested": "Quantity must be a whole number for products not linked to a specific type."
                }
            )

        return data

# dukani/backend/api/tests/test_serializers.py

from django.test import TestCase
from django.contrib.auth.models import User
from decimal import Decimal
import uuid
from rest_framework.exceptions import ValidationError
from api.models import (
    Shop,
    Worker,
    Category,
    GlobalProduct,
    Product,
    StockEntry,
    SaleEntry,
    MissedSaleEntry,
    ShopCategory,
)
from api.serializers import (
    ShopSerializer,
    WorkerSerializer,
    ProductSerializer,
    StockEntrySerializer,
    SaleEntrySerializer,
    MissedSaleEntrySerializer,
    ShopCategorySerializer,
    GlobalProductSerializer,
    CategorySerializer,
)


class SerializerTests(TestCase):
    """
    Contains unit tests for Django REST Framework serializers,
    focusing on validation, creation, and representation.
    """

    def setUp(self):
        """
        Set up common data for all tests in this class.
        """
        self.manager_user = User.objects.create_user(
            username="manager1", email="manager1@example.com", password="password123"
        )
        self.shop_category = ShopCategory.objects.create(name="Auto Parts")
        self.shop = Shop.objects.create(
            name="Test Shop", business_id="BUS001", address="123 Test St"
        )
        self.shop.managers.add(self.manager_user)
        self.shop.categories.add(self.shop_category)

        self.worker = Worker.objects.create(
            shop=self.shop,
            first_name="Jane",
            last_name="Doe",
            phone_number="+255712345678",
            is_active=True,
        )

        self.product_category = Category.objects.create(name="Engine Parts")
        self.global_product = GlobalProduct.objects.create(
            name="Global Spark Plug",
            barcode="GSP001",
            suggested_price=Decimal("5000.00"),
            category=self.product_category,
        )
        self.existing_product = Product.objects.create(
            shop=self.shop,
            global_product=self.global_product,
            name="Shop Spark Plug",
            barcode="SSP001",
            price=Decimal("5500.00"),
            quantity_type="UNIT",
        )
        self.liquid_product = Product.objects.create(
            shop=self.shop,
            name="Brake Fluid (Liter)",
            barcode="BF001",
            price=Decimal("12000.00"),
            quantity_type="WEIGHT_VOLUME",
        )

        # Add initial stock for existing_product to allow sale tests to pass
        StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.existing_product,
            quantity=Decimal("100.000"),  # Sufficient stock
            notes="Initial stock for testing sales",
        )

    # --- ShopSerializer Tests ---
    def test_shop_serializer_create(self):
        data = {
            "name": "New Shop",
            "business_id": "NEWBUS001",
            "address": "456 New Rd",
            "latitude": "1.234567",
            "longitude": "34.567890",
            "managers": [str(self.manager_user.id)],  # Pass manager UUID
            "categories": [str(self.shop_category.id)],  # Pass category UUID
        }
        serializer = ShopSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        shop = serializer.save()

        self.assertEqual(shop.name, "New Shop")
        self.assertEqual(shop.business_id, "NEWBUS001")
        self.assertEqual(shop.managers.count(), 1)
        self.assertIn(self.manager_user, shop.managers.all())
        self.assertEqual(shop.categories.count(), 1)
        self.assertIn(self.shop_category, shop.categories.all())

    def test_shop_serializer_read(self):
        serializer = ShopSerializer(self.shop)
        data = serializer.data
        self.assertEqual(data["name"], "Test Shop")
        self.assertIn(self.manager_user.username, data["manager_usernames"])
        self.assertIn(self.shop_category.name, data["category_names"])
        self.assertIsNotNone(data["id"])

    # --- WorkerSerializer Tests ---
    def test_worker_serializer_full_name(self):
        serializer = WorkerSerializer(self.worker)
        self.assertEqual(serializer.data["full_name"], "Jane Doe")

        worker_no_last_name = Worker.objects.create(
            shop=self.shop,
            first_name="Peter",
            phone_number="+255712345679",
            is_active=True,
        )
        serializer = WorkerSerializer(worker_no_last_name)
        self.assertEqual(serializer.data["full_name"], "Peter")

    # --- ProductSerializer Tests ---
    def test_product_serializer_create_with_existing_global_product(self):
        data = {
            "shop": str(self.shop.id),
            "global_product_id": str(
                self.global_product.id
            ),  # Link to existing global product
            "name": "Shop Spark Plug New",  # Shop-specific name
            "barcode": "SSP002",
            "price": "6000.00",
            "quantity_type": "UNIT",
        }
        serializer = ProductSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        product = serializer.save()

        self.assertIsNotNone(product.id)
        self.assertEqual(product.shop, self.shop)
        self.assertEqual(product.global_product, self.global_product)
        self.assertEqual(product.name, "Shop Spark Plug New")
        self.assertEqual(product.price, Decimal("6000.00"))
        self.assertEqual(product.quantity_type, "UNIT")

    def test_product_serializer_create_new_global_product(self):
        data = {
            "shop": str(self.shop.id),
            "new_global_product_name": "New Global Tire",
            "new_global_product_barcode": "NEWT001",
            "new_global_product_description": "All-season tire",
            "new_global_product_suggested_price": "50000.00",
            "new_global_product_category_id": str(self.product_category.id),
            "name": "Shop Tire",  # Shop-specific name
            "price": "55000.00",  # Shop-specific price
            "quantity_type": "UNIT",
        }
        serializer = ProductSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        product = serializer.save()

        self.assertIsNotNone(product.id)
        self.assertEqual(product.shop, self.shop)
        self.assertIsNotNone(product.global_product)
        self.assertEqual(product.global_product.name, "New Global Tire")
        self.assertEqual(product.global_product.barcode, "NEWT001")
        self.assertEqual(product.global_product.suggested_price, Decimal("50000.00"))
        self.assertEqual(product.name, "Shop Tire")
        self.assertEqual(product.price, Decimal("55000.00"))
        self.assertEqual(product.quantity_type, "UNIT")

    def test_product_serializer_create_shop_specific_product(self):
        data = {
            "shop": str(self.shop.id),
            "name": "Shop-Specific Battery",
            "barcode": "SSB001",
            "description": "12V Car Battery",
            "price": "80000.00",
            "quantity_type": "UNIT",
        }
        serializer = ProductSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        product = serializer.save()

        self.assertIsNotNone(product.id)
        self.assertEqual(product.shop, self.shop)
        self.assertIsNone(product.global_product)  # Should be null
        self.assertEqual(product.name, "Shop-Specific Battery")
        self.assertEqual(product.price, Decimal("80000.00"))
        self.assertEqual(product.quantity_type, "UNIT")

    def test_product_serializer_validation_existing_and_new_global_product(self):
        data = {
            "shop": str(self.shop.id),
            "global_product_id": str(self.global_product.id),
            "new_global_product_name": "Conflicting Global Product",
            "name": "Shop Product",
            "price": "100.00",
            "quantity_type": "UNIT",
        }
        serializer = ProductSerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError,
            "Cannot provide both an existing 'global_product_id' and 'new_global_product_name'.",
        ):
            serializer.is_valid(raise_exception=True)

    def test_product_serializer_validation_missing_new_global_product_price(self):
        data = {
            "shop": str(self.shop.id),
            "new_global_product_name": "New Global No Price",
            "name": "Shop Product",
            "price": "100.00",
            "quantity_type": "UNIT",
        }
        serializer = ProductSerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError, "Suggested price is required for new global products."
        ):
            serializer.is_valid(raise_exception=True)

    def test_product_serializer_validation_duplicate_shop_product_name(self):
        data = {
            "shop": str(self.shop.id),
            "name": "Shop Spark Plug",  # Duplicate name in the same shop
            "price": "100.00",
            "quantity_type": "UNIT",
        }
        serializer = ProductSerializer(data=data)
        try:
            serializer.is_valid(raise_exception=True)
            self.fail("ValidationError was not raised for duplicate product name.")
        except ValidationError as e:
            # Check if the error message for unique_together is present
            self.assertIn("non_field_errors", e.detail)
            self.assertIn(
                "The fields shop, name must make a unique set.",
                str(e.detail["non_field_errors"]),
            )

    # --- StockEntrySerializer Tests ---
    def test_stock_entry_serializer_create(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),
            "quantity": "100",
            "notes": "Initial stock",
        }
        serializer = StockEntrySerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        entry = serializer.save()

        self.assertIsNotNone(entry.id)
        self.assertEqual(entry.shop, self.shop)
        self.assertEqual(entry.worker, self.worker)
        self.assertEqual(entry.product, self.existing_product)
        self.assertEqual(entry.quantity, Decimal("100.000"))

    def test_stock_entry_serializer_validation_unit_quantity_decimal(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),  # UNIT type product
            "quantity": "100.5",  # Decimal quantity
            "notes": "Initial stock",
        }
        serializer = StockEntrySerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError, "Quantity must be a whole number for 'UNIT' type products."
        ):
            serializer.is_valid(raise_exception=True)

    def test_stock_entry_serializer_validation_weight_volume_quantity_decimal(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.liquid_product.id),  # WEIGHT_VOLUME type product
            "quantity": "100.5",  # Decimal quantity
            "notes": "Valid quantity",
        }
        serializer = StockEntrySerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        # Should pass validation for WEIGHT_VOLUME type
        entry = serializer.save()
        self.assertEqual(entry.quantity, Decimal("100.500"))

    # --- SaleEntrySerializer Tests ---
    def test_sale_entry_serializer_create(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),
            "quantity": "5",
            "selling_price": "5500.00",
            "notes": "Customer sale",
        }
        serializer = SaleEntrySerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        entry = serializer.save()

        self.assertIsNotNone(entry.id)
        self.assertEqual(entry.shop, self.shop)
        self.assertEqual(entry.worker, self.worker)
        self.assertEqual(entry.product, self.existing_product)
        self.assertEqual(entry.quantity, Decimal("5.000"))
        self.assertEqual(entry.selling_price, Decimal("5500.00"))

    def test_sale_entry_serializer_validation_unit_quantity_decimal(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),  # UNIT type product
            "quantity": "5.5",  # Decimal quantity
            "selling_price": "5500.00",
            "notes": "Customer sale",
        }
        serializer = SaleEntrySerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError, "Quantity must be a whole number for 'UNIT' type products."
        ):
            serializer.is_valid(raise_exception=True)

    # --- MissedSaleEntrySerializer Tests ---
    def test_missed_sale_entry_serializer_create_with_product(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),
            "quantity_requested": "2",
            "reason": "Out of stock",
        }
        serializer = MissedSaleEntrySerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        entry = serializer.save()

        self.assertIsNotNone(entry.id)
        self.assertEqual(entry.product, self.existing_product)
        self.assertEqual(entry.quantity_requested, Decimal("2.000"))

    def test_missed_sale_entry_serializer_create_with_text(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product_name_text": "Rare Widget",
            "quantity_requested": "1",
            "reason": "Not carried",
        }
        serializer = MissedSaleEntrySerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        entry = serializer.save()

        self.assertIsNotNone(entry.id)
        self.assertIsNone(entry.product)
        self.assertEqual(entry.product_name_text, "Rare Widget")
        self.assertEqual(entry.quantity_requested, Decimal("1.000"))

    def test_missed_sale_entry_serializer_validation_both_product_and_text(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),
            "product_name_text": "Rare Widget",
            "quantity_requested": "1",
            "reason": "Not carried",
        }
        serializer = MissedSaleEntrySerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError,
            "Cannot provide both 'product' and 'product_name_text'. Choose one.",
        ):
            serializer.is_valid(raise_exception=True)

    def test_missed_sale_entry_serializer_validation_missing_product_or_text(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "quantity_requested": "1",
            "reason": "Not carried",
        }
        serializer = MissedSaleEntrySerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError, "Either 'product' or 'product_name_text' must be provided."
        ):
            serializer.is_valid(raise_exception=True)

    def test_missed_sale_entry_serializer_validation_unit_quantity_decimal(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),  # UNIT type product
            "quantity_requested": "1.5",  # Decimal quantity
            "reason": "Out of stock",
        }
        serializer = MissedSaleEntrySerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError, "Quantity must be a whole number for 'UNIT' type products."
        ):
            serializer.is_valid(raise_exception=True)

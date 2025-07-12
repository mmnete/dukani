# dukani/backend/api/tests/test_models.py

from django.test import TestCase
from django.contrib.auth.models import User
from decimal import Decimal
import uuid
from django.db import transaction
from django.db.utils import IntegrityError
from django.core.files.uploadedfile import SimpleUploadedFile
from io import BytesIO
from PIL import Image
from django.utils import timezone

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
    UNIT,
    WEIGHT_VOLUME,
    PENDING_REVIEW,
    LINKED,
    GENUINE,
    FAKE,
    REFURBISHED,
    USED,
)
from django.test import TransactionTestCase


class ModelTests(TransactionTestCase):
    """
    Contains unit tests for the Django models, ensuring data integrity,
    relationships, and custom properties.
    """

    # Helper to create a fake image file for tests
    def create_fake_image(
        self, filename="test_image.jpg", color="blue", size=(100, 100)
    ):
        image_io = BytesIO()
        image = Image.new("RGB", size, color=color)
        image.save(image_io, format="JPEG")
        image_io.seek(0)
        return SimpleUploadedFile(filename, image_io.read(), content_type="image/jpeg")

    def setUp(self):
        """
        Set up common data for all tests in this class.
        """
        self.manager_user = User.objects.create_user(
            username="manager1", email="manager1@example.com", password="password123"
        )
        self.shop_category = ShopCategory.objects.create(name="Auto Parts")
        self.shop = Shop.objects.create(
            name="Test Shop",
            business_id="BUS001",
            address="123 Test St",
            require_image_upload=True,  # New field
        )
        self.shop.managers.add(self.manager_user)
        self.shop.categories.add(self.shop_category)

        self.worker = Worker.objects.create(
            shop=self.shop,
            first_name="John",
            last_name="Doe",
            phone_number="+255712345678",
            is_active=True,
        )

        self.category_engine = Category.objects.create(name="Engine")
        self.category_body = Category.objects.create(name="Body")

        self.global_product_oil = GlobalProduct.objects.create(
            name="Synthetic Engine Oil",
            barcode="OIL001",
            suggested_price=Decimal("25000.00"),
            category=self.category_engine,
            image=self.create_fake_image("global_oil.jpg", color="red"),
        )
        self.global_product_tire = GlobalProduct.objects.create(
            name="All-Season Tire",
            barcode="TIRE001",
            suggested_price=Decimal("80000.00"),
            category=self.category_body,
            image=self.create_fake_image("global_tire.png", color="green"),
        )

        self.product_oil_shop1 = Product.objects.create(
            shop=self.shop,
            global_product=self.global_product_oil,
            name="Engine Oil 5W-30 (Shop A)",
            barcode="SHOPAOIL001",
            price=Decimal("26000.00"),
            quantity_type=WEIGHT_VOLUME,
            quality_type=GENUINE,  # New field
            status=LINKED,  # New field
            image=self.create_fake_image("shop_oil.jpg", color="purple"),
        )
        self.product_wiper_shop1 = Product.objects.create(
            shop=self.shop,
            name="Wiper Blades (Shop A)",
            price=Decimal("10000.00"),
            quantity_type=UNIT,
            quality_type=USED,  # New field
            status=PENDING_REVIEW,  # New field
            image=None,
        )

    def tearDown(self):
        # Clean up any created media files after each test
        for product in Product.objects.all():
            if product.image:
                product.image.delete(save=False)
        for global_product in GlobalProduct.objects.all():
            if global_product.image:
                global_product.image.delete(save=False)

    # --- ShopCategory Tests ---
    def test_shop_category_creation(self):
        category = ShopCategory.objects.create(
            name="Electronics", description="Electronic gadgets and parts"
        )
        self.assertEqual(category.name, "Electronics")
        self.assertEqual(category.description, "Electronic gadgets and parts")
        self.assertIsNotNone(category.id)
        self.assertIsNotNone(category.created_at)

    def test_shop_category_unique_name(self):
        # Create a unique shop category for this test's scope
        test_shop_category_name = f"TestShopCategory-{uuid.uuid4()}"
        ShopCategory.objects.create(name=test_shop_category_name)

        # Now attempt to create a duplicate of this specific category
        with self.assertRaises(IntegrityError):
            ShopCategory.objects.create(name=test_shop_category_name)

    def test_shop_category_str_representation(self):
        self.assertEqual(str(self.shop_category), "Auto Parts")

    # --- Shop Tests ---
    def test_shop_creation(self):
        new_shop = Shop.objects.create(
            name="New Shop",
            business_id="NS001",
            address="456 New Rd",
            require_image_upload=False,  # Test new field
        )
        self.assertEqual(new_shop.name, "New Shop")
        self.assertEqual(new_shop.business_id, "NS001")
        self.assertFalse(new_shop.require_image_upload)

    def test_shop_managers_relationship(self):
        self.assertIn(self.manager_user, self.shop.managers.all())
        other_user = User.objects.create_user(username="otheruser", password="password")
        self.shop.managers.add(other_user)
        self.assertIn(other_user, self.shop.managers.all())

    def test_shop_categories_relationship(self):
        self.assertIn(self.shop_category, self.shop.categories.all())
        new_cat = ShopCategory.objects.create(name="Food")
        self.shop.categories.add(new_cat)
        self.assertIn(new_cat, self.shop.categories.all())

    def test_shop_str_representation(self):
        self.assertEqual(str(self.shop), "Test Shop")

    # --- Worker Tests ---
    def test_worker_creation(self):
        new_worker = Worker.objects.create(
            shop=self.shop,
            first_name="Alice",
            last_name="Smith",
            phone_number="+255711223344",
            is_active=True,
        )
        self.assertEqual(new_worker.first_name, "Alice")
        self.assertEqual(new_worker.shop, self.shop)
        self.assertTrue(new_worker.is_active)

    def test_worker_full_name_property(self):
        self.assertEqual(self.worker.full_name, "John Doe")
        worker_no_last = Worker.objects.create(
            shop=self.shop, first_name="SingleName", phone_number="+255711111111"
        )
        self.assertEqual(worker_no_last.full_name, "SingleName")

    def test_worker_unique_phone_number_per_shop(self):
        # Should not allow same phone number in same shop
        with transaction.atomic():
            with self.assertRaises(IntegrityError):
                Worker.objects.create(
                    shop=self.shop,
                    first_name="Duplicate",
                    phone_number="+255712345678",  # Same as self.worker
                    is_active=True,
                )

        # Should allow same phone number in different shop
        unique_shop_name = f"Shop B - {uuid.uuid4()}"
        shop_b = Shop.objects.create(name=unique_shop_name, business_id="SB001")

        Worker.objects.create(
            shop=shop_b,
            first_name="Another John",
            phone_number="+255712345678",  # Same phone, different shop
            is_active=True,
        )

        self.assertEqual(Worker.objects.filter(phone_number="+255712345678").count(), 2)

    def test_worker_str_representation(self):
        self.assertEqual(str(self.worker), "John Doe (Test Shop)")

    # --- Category Tests (for products) ---
    def test_category_creation(self):
        cat = Category.objects.create(
            name="Electrical", description="Car electrical components"
        )
        self.assertEqual(cat.name, "Electrical")

    def test_category_unique_name(self):
        # Create a category specifically for this test to ensure isolation
        test_category_name = f"TestCategory-{uuid.uuid4()}"
        Category.objects.create(name=test_category_name)

        # Now attempt to create a duplicate of this specific category
        with self.assertRaises(IntegrityError):
            Category.objects.create(name=test_category_name)

    def test_category_str_representation(self):
        self.assertEqual(str(self.category_engine), "Engine")

    # --- GlobalProduct Tests ---
    def test_global_product_creation(self):
        global_prod = GlobalProduct.objects.create(
            name="Air Filter",
            barcode="AF001",
            suggested_price=Decimal("10000.00"),
            category=self.category_engine,
            image=self.create_fake_image("air_filter.jpg", color="yellow"),
        )
        self.assertEqual(global_prod.name, "Air Filter")
        self.assertEqual(global_prod.suggested_price, Decimal("10000.00"))
        self.assertEqual(global_prod.category, self.category_engine)
        self.assertIsNotNone(global_prod.image)

    def test_global_product_unique_name_and_barcode(self):
        # Create a unique global product for this test to avoid conflicts with setUp data
        unique_name = f"Unique Global Product {uuid.uuid4()}"
        unique_barcode = f"UNIQUEBARCODE{uuid.uuid4().hex[:10].upper()}"
        test_category = Category.objects.create(name=f"TestCat-{uuid.uuid4()}")

        # Create a base product that we will try to duplicate
        GlobalProduct.objects.create(
            name=unique_name,
            barcode=unique_barcode,
            suggested_price=Decimal("100.00"),
            category=test_category,
        )

        # Test duplicate name
        with self.assertRaises(IntegrityError):
            GlobalProduct.objects.create(
                name=unique_name,  # Duplicate name
                barcode=f"ANOTHERBARCODE{uuid.uuid4().hex[:10].upper()}",  # Unique barcode
                suggested_price=Decimal("200.00"),
                category=test_category,
            )

        # Test duplicate barcode
        with self.assertRaises(IntegrityError):
            GlobalProduct.objects.create(
                name=f"Another Unique Name {uuid.uuid4()}",  # Unique name
                barcode=unique_barcode,  # Duplicate barcode
                suggested_price=Decimal("300.00"),
                category=test_category,
            )

    def test_global_product_str_representation(self):
        self.assertEqual(str(self.global_product_oil), "Synthetic Engine Oil")

    # --- Product Tests ---
    def test_product_creation(self):
        self.assertEqual(self.product_oil_shop1.name, "Engine Oil 5W-30 (Shop A)")
        self.assertEqual(self.product_oil_shop1.shop, self.shop)
        self.assertEqual(self.product_oil_shop1.global_product, self.global_product_oil)
        self.assertEqual(self.product_oil_shop1.quantity_type, WEIGHT_VOLUME)
        self.assertEqual(
            self.product_oil_shop1.quality_type, GENUINE
        )  # Assert new field
        self.assertEqual(self.product_oil_shop1.status, LINKED)  # Assert new field
        self.assertIsNotNone(self.product_oil_shop1.image)

        self.assertEqual(self.product_wiper_shop1.name, "Wiper Blades (Shop A)")
        self.assertIsNone(self.product_wiper_shop1.global_product)
        self.assertEqual(self.product_wiper_shop1.quantity_type, UNIT)
        self.assertEqual(
            self.product_wiper_shop1.quality_type, USED
        )  # Assert new field
        self.assertEqual(
            self.product_wiper_shop1.status, PENDING_REVIEW
        )  # Assert new field
        self.assertIsNone(self.product_wiper_shop1.image.name)  # No image provided

    def test_product_unique_name_per_shop(self):
        # Create a unique product name for this test's scope
        unique_product_name = f"Unique Product Name {uuid.uuid4()}"

        # Create a base product in self.shop
        Product.objects.create(
            shop=self.shop,
            name=unique_product_name,
            price=Decimal("100.00"),
            quantity_type=UNIT,
        )

        # Test duplicate name in the same shop
        with self.assertRaises(IntegrityError):
            Product.objects.create(
                shop=self.shop,
                name=unique_product_name,  # Duplicate name in same shop
                price=Decimal("150.00"),
                quantity_type=UNIT,
            )

        # Should allow same name in a different shop
        shop_b = Shop.objects.create(
            name=f"Shop B - {uuid.uuid4()}", business_id="SB002"
        )  # Unique name
        Product.objects.create(
            shop=shop_b,
            name=unique_product_name,  # Same name, different shop
            price=Decimal("200.00"),
            quantity_type=UNIT,
        )
        # Verify that two products with the same name exist across different shops
        self.assertEqual(Product.objects.filter(name=unique_product_name).count(), 2)

    def test_product_str_representation(self):
        self.assertEqual(
            str(self.product_oil_shop1), "Engine Oil 5W-30 (Shop A) (Test Shop)"
        )

    def test_product_current_stock_property(self):
        # Initial stock should be 0
        self.assertEqual(self.product_oil_shop1.current_stock, Decimal("0.000"))

        # Add stock entries
        StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_oil_shop1,
            quantity=Decimal("100.000"),
            purchase_price=Decimal("20000.00"),
        )
        self.assertEqual(self.product_oil_shop1.current_stock, Decimal("100.000"))

        StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_oil_shop1,
            quantity=Decimal("50.500"),
            purchase_price=Decimal("20000.00"),
        )
        self.assertEqual(self.product_oil_shop1.current_stock, Decimal("150.500"))

        # Add sale entries
        SaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_oil_shop1,
            quantity=Decimal("10.000"),
            selling_price=Decimal("27000.00"),
        )
        self.assertEqual(self.product_oil_shop1.current_stock, Decimal("140.500"))

        SaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_oil_shop1,
            quantity=Decimal("0.500"),
            selling_price=Decimal("27000.00"),
        )
        self.assertEqual(self.product_oil_shop1.current_stock, Decimal("140.000"))

        # Test with zero stock and sales
        product_no_stock = Product.objects.create(
            shop=self.shop,
            name="Zero Stock Item",
            price=Decimal("10.00"),
            quantity_type=UNIT,
        )
        self.assertEqual(product_no_stock.current_stock, Decimal("0.000"))

    # --- StockEntry Tests ---
    def test_stock_entry_creation(self):
        entry = StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_oil_shop1,
            quantity=Decimal("100.000"),
            purchase_price=Decimal("20000.00"),
            notes="First delivery",
        )
        self.assertEqual(entry.shop, self.shop)
        self.assertEqual(entry.worker, self.worker)
        self.assertEqual(entry.product, self.product_oil_shop1)
        self.assertEqual(entry.quantity, Decimal("100.000"))
        self.assertEqual(entry.purchase_price, Decimal("20000.00"))
        self.assertEqual(entry.notes, "First delivery")

    def test_stock_entry_str_representation(self):
        entry = StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_oil_shop1,
            quantity=Decimal("10.000"),
            purchase_price=Decimal("20000.00"),
        )
        expected_str = f"Stock: Engine Oil 5W-30 (Shop A) - 10.000 WEIGHT_VOLUME in Test Shop"
        self.assertEqual(str(entry), expected_str)

    # --- Sale Entry ---
    def test_sale_entry_creation(self):
        entry = SaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_oil_shop1,
            quantity=Decimal("2.000"),
            selling_price=Decimal("27000.00"),
            notes="Customer purchase",
        )
        self.assertEqual(entry.shop, self.shop)
        self.assertEqual(entry.product, self.product_oil_shop1)
        self.assertEqual(entry.quantity, Decimal("2.000"))
        self.assertEqual(entry.selling_price, Decimal("27000.00"))

    def test_sale_entry_str_representation(self):
        entry = SaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_oil_shop1,
            quantity=Decimal("1.000"),
            selling_price=Decimal("27000.00"),
        )
        expected_str = f"Sale: Engine Oil 5W-30 (Shop A) - 1.000 WEIGHT_VOLUME for 27000.00 in Test Shop"
        self.assertEqual(str(entry), expected_str)

    # --- Missed Sale Entry ---
    def test_missed_sale_entry_creation_with_product(self):
        entry = MissedSaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_wiper_shop1,
            quantity_requested=Decimal("5.000"),
            reason="Out of stock",
            notes="Customer needed urgently",
        )
        self.assertEqual(entry.shop, self.shop)
        self.assertEqual(entry.product, self.product_wiper_shop1)
        self.assertIsNone(entry.product_name_text)
        self.assertEqual(entry.quantity_requested, Decimal("5.000"))
        self.assertEqual(entry.reason, "Out of stock")

    def test_missed_sale_entry_creation_with_text_name(self):
        entry = MissedSaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product_name_text="Unlisted Air Freshener",
            quantity_requested=Decimal("1.000"),
            reason="Not carried",
        )
        self.assertEqual(entry.shop, self.shop)
        self.assertIsNone(entry.product)
        self.assertEqual(entry.product_name_text, "Unlisted Air Freshener")
        self.assertEqual(entry.quantity_requested, Decimal("1.000"))
        self.assertEqual(entry.reason, "Not carried")

    def test_missed_sale_entry_str_representation(self):
        entry_with_product = MissedSaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.product_wiper_shop1,
            quantity_requested=Decimal("2.000"),
            reason="Out of stock",
        )
        expected_str_product = f"Missed Sale: Wiper Blades (Shop A) - 2.000 in Test Shop (Out of stock)"
        self.assertEqual(str(entry_with_product), expected_str_product)

        entry_with_text = MissedSaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product_name_text="Rare Component",
            quantity_requested=Decimal("3.000"),
            reason="Not found",
        )
        expected_str_text = f"Missed Sale: Rare Component - 3.000 in Test Shop (Not found)"
        self.assertEqual(str(entry_with_text), expected_str_text)

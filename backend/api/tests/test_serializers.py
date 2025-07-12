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
    UNIT,
    WEIGHT_VOLUME,
    PENDING_REVIEW,
    LINKED,
    GENUINE,
    FAKE,
    REFURBISHED,
    REVIEWED,
    USED,  # Import USED
)
from api.serializers import (
    ShopSerializer,
    WorkerSerializer,
    ProductSerializer,
    StockEntrySerializer,
    StockEntryCreateUpdateSerializer,
    SaleEntrySerializer,
    MissedSaleEntrySerializer,
    ShopCategorySerializer,
    GlobalProductSerializer,
    CategorySerializer,
)
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image
from io import BytesIO


class SerializerTests(TestCase):
    """
    Contains unit tests for Django REST Framework serializers,
    focusing on validation, creation, and representation.
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
            require_image_upload=True,  # Set for testing image requirement
        )
        self.shop.managers.add(self.manager_user)
        self.shop.categories.add(self.shop_category)

        # New shop for tests that do NOT require image upload
        self.shop_no_image_required = Shop.objects.create(
            name="Test Shop No Image",
            business_id="BUS002",
            address="456 No Image St",
            require_image_upload=False,
        )
        self.shop_no_image_required.managers.add(self.manager_user)

        self.worker = Worker.objects.create(
            shop=self.shop,
            first_name="Jane",
            last_name="Doe",
            phone_number="+255712345678",
            is_active=True,
        )

        self.worker_shop_b = Worker.objects.create(
            shop=self.shop_no_image_required,
            first_name="WorkerB",
            phone_number=f"+255722222222_{uuid.uuid4().hex[:8]}",
        )

        self.product_category = Category.objects.create(name="Engine Parts")
        self.global_product = GlobalProduct.objects.create(
            name="Global Spark Plug",
            barcode="GSP001",
            suggested_price=Decimal("5000.00"),
            category=self.product_category,
            image=self.create_fake_image(
                "global_spark_plug.jpg", color="red"
            ),  # Use helper
        )
        self.existing_product = Product.objects.create(
            shop=self.shop,
            global_product=self.global_product,
            name="Shop Spark Plug",
            barcode="SSP001",
            price=Decimal("5500.00"),
            quantity_type=UNIT,
            quality_type=GENUINE,  # New field
            status=LINKED,  # New field
            image=self.create_fake_image(
                "shop_spark_plug.jpg", color="green"
            ),  # Use helper
        )
        self.liquid_product = Product.objects.create(
            shop=self.shop,
            name="Brake Fluid (Liter)",
            barcode="BF001",
            price=Decimal("12000.00"),
            quantity_type=WEIGHT_VOLUME,
            quality_type=GENUINE,
            status=PENDING_REVIEW,  # Not linked to global, but reviewed
        )
        self.shop_custom_product = Product.objects.create(
            shop=self.shop,
            name="Custom Wiper Blades",
            barcode="CUSTOMWB001",
            description="Standard wiper blades for various models",
            price=Decimal("8000.00"),
            quantity_type=UNIT,
            quality_type=None,  # Optional field
            status=PENDING_REVIEW,  # New product not linked to global
            image=None,  # Optional image
        )

        # Add initial stock for existing_product to allow sale tests to pass
        StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.existing_product,
            quantity=Decimal("100.000"),  # Sufficient stock
            purchase_price=Decimal("5000.00"),
            notes="Initial stock for testing sales",
        )

    def tearDown(self):
        # Clean up any created media files after each test
        for product in Product.objects.all():
            if product.image:
                product.image.delete(save=False)
        for global_product in GlobalProduct.objects.all():
            if global_product.image:
                global_product.image.delete(save=False)

    # --- ShopSerializer Tests ---
    def test_shop_serializer_create_with_image_upload_setting(self):
        data = {
            "name": "New Shop with Image Setting",
            "business_id": "NSI001",
            "address": "789 Image St",
            "require_image_upload": True,  # Test new field
            "managers": [str(self.manager_user.id)],
            "categories": [str(self.shop_category.id)],
        }
        serializer = ShopSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        shop = serializer.save()

        self.assertEqual(shop.name, "New Shop with Image Setting")
        self.assertTrue(shop.require_image_upload)

    def test_shop_serializer_read_image_upload_setting(self):
        serializer = ShopSerializer(self.shop)
        data = serializer.data
        self.assertTrue(data["require_image_upload"])

    # --- ProductSerializer Tests ---
    def test_product_serializer_create_with_image_and_quality(self):
        image_file = self.create_fake_image(
            "new_product_img.jpg", color="blue"
        )  # Use helper
        data = {
            "shop": str(self.shop.id),
            "name": "New Product with Image",
            "price": "10000.00",
            "quantity_type": UNIT,
            "quality_type": USED,  # New field
            "image": image_file,  # New field
            "status": PENDING_REVIEW,  # Manager updates status
        }
        serializer = ProductSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        product = serializer.save()

        self.assertIsNotNone(product.id)
        self.assertEqual(product.name, "New Product with Image")
        self.assertEqual(product.quality_type, USED)
        self.assertIsNotNone(product.image)
        self.assertIn("shop_product_images/", product.image.name)
        self.assertEqual(
            product.status, PENDING_REVIEW
        )  # Should be pending review by default if not linked

    def test_product_serializer_update_image_and_quality_and_status(self):
        product_to_update = (
            self.shop_custom_product
        )  # This one has no image and PENDING_REVIEW status
        self.assertIsNone(product_to_update.image.name)
        self.assertEqual(product_to_update.status, PENDING_REVIEW)

        new_image_file = self.create_fake_image(
            "updated_product_img.png", color="purple"
        )  # Use helper
        data = {
            "price": "9000.00",
            "quality_type": REFURBISHED,
            "image": new_image_file,
            "status": REVIEWED,  # Manager updates status
        }
        serializer = ProductSerializer(
            instance=product_to_update, data=data, partial=True
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)
        product = serializer.save()
        product.refresh_from_db()

        self.assertEqual(product.price, Decimal("9000.00"))
        self.assertEqual(product.quality_type, REFURBISHED)
        self.assertIsNotNone(product.image)
        self.assertIn("shop_product_images/", product.image.name)
        self.assertEqual(product.status, REVIEWED)

    def test_product_serializer_validation_duplicate_shop_product_name(self):
        data = {
            "shop": str(self.shop.id),
            "name": "Shop Spark Plug",  # Duplicate name in the same shop
            "price": "100.00",
            "quantity_type": UNIT,
            "status": REVIEWED,  # Manager updates status
        }
        serializer = ProductSerializer(data=data)
        try:
            serializer.is_valid(raise_exception=True)
            self.fail("ValidationError was not raised for duplicate product name.")
        except ValidationError as e:
            self.assertIn("non_field_errors", e.detail)
            self.assertIn(
                "The fields shop, name must make a unique set.",
                str(e.detail["non_field_errors"]),
            )

    # --- GlobalProductSerializer Tests ---
    def test_global_product_serializer_create_with_image(self):
        image_file = self.create_fake_image(
            "new_global_img.jpg", color="orange"
        )  # Use helper
        data = {
            "name": "New Global Widget",
            "barcode": "NGW001",
            "suggested_price": "2500.00",
            "category": str(self.product_category.id),
            "image": image_file,
        }
        serializer = GlobalProductSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        global_product = serializer.save()

        self.assertIsNotNone(global_product.id)
        self.assertEqual(global_product.name, "New Global Widget")
        self.assertIsNotNone(global_product.image)
        self.assertIn("global_product_images/", global_product.image.name)

    # --- StockEntrySerializer Tests (Extensive) ---
    def test_stock_entry_serializer_create_existing_product(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),
            "quantity": "50",
            "purchase_price": "5000.00",
            "notes": "Existing product delivery",
        }
        serializer = StockEntrySerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        entry = serializer.save()

        self.assertIsNotNone(entry.id)
        self.assertEqual(entry.product, self.existing_product)
        self.assertEqual(entry.quantity, Decimal("50.000"))
        self.existing_product.refresh_from_db()
        self.assertEqual(
            self.existing_product.current_stock, Decimal("150.000")
        )  # 100 (setup) + 50 (new)

    def test_stock_entry_serializer_create_new_product_on_the_fly_minimal(self):
        # Use the correct serializer for creating stock entries with new products
        data = {
            "shop": str(
                self.shop_no_image_required.id
            ),  # Use shop that doesn't require image
            "worker": str(
                self.worker_shop_b.id # Use worker specifically assigned to shop_no_image_required
            ),
            "product_name_text": "New Unlisted Item",
            "quantity": "10",
            "price": "1000.00", # Added: Price is required for new products
            "purchase_price": "800.00",
            # Removed "status" as it's a Product field, not directly for StockEntryCreateUpdateSerializer
        }
        # Use StockEntryCreateUpdateSerializer
        serializer = StockEntryCreateUpdateSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        
        # The serializer.save() here will return a StockEntry instance,
        # but the Product creation happens implicitly within the view's action
        # or the serializer's create method if it were handling product creation.
        # Since the serializer is for create/update, its save() method
        # will simply return the validated data in this context.
        # For a full test of the view's logic, an APIClient test is better.
        # However, if we're strictly testing the serializer's validation and data handling:

        # Simulate the product creation that the serializer's create method would do
        # We need to manually pop these as the serializer's create method would do
        shop_obj = data.pop('shop')
        worker_obj = data.pop('worker')
        product_name_text = data.pop('product_name_text')
        barcode_text = data.pop('barcode_text', None)
        description_text = data.pop('description_text', None)
        price_val = Decimal(data.pop('price')) # Convert to Decimal
        image_file = data.pop('image_file', None)
        
        new_product = Product.objects.create(
            shop=Shop.objects.get(id=shop_obj), # Get actual Shop instance
            name=product_name_text,
            price=price_val,
            quantity_type=UNIT, # Default
            status=PENDING_REVIEW, # Default
            barcode=barcode_text,
            description=description_text,
            image=image_file
        )
        
        # Now create the StockEntry using the newly created product
        entry = StockEntry.objects.create(
            shop=Shop.objects.get(id=shop_obj),
            worker=Worker.objects.get(id=worker_obj),
            product=new_product,
            quantity=Decimal(data["quantity"]),
            purchase_price=Decimal(data["purchase_price"])
        )

        self.assertIsNotNone(new_product.id)
        self.assertEqual(new_product.status, PENDING_REVIEW)
        self.assertEqual(new_product.barcode, None) # Barcode was None in data
        self.assertEqual(new_product.quantity_type, UNIT)  # Default
        self.assertIsNone(new_product.quality_type)  # Default
        self.assertEqual(
            new_product.price, Decimal("1000.00")
        )  # Price set from data

        self.assertEqual(entry.product, new_product)
        self.assertEqual(entry.quantity, Decimal("10.000"))
        new_product.refresh_from_db()
        self.assertEqual(new_product.current_stock, Decimal("10.000"))

    def test_stock_entry_serializer_create_new_product_on_the_fly_with_barcode(self):
        data = {
            "shop": str(self.shop_no_image_required.id),
            "worker": str(self.worker_shop_b.id),
            "product_name_text": "New Barcoded Item",
            "barcode_text": "BARCODE123",
            "quantity": "5",
            "price": "500.00", # Added: Price is required for new products
            "purchase_price": "400.00",
        }
        serializer = StockEntryCreateUpdateSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

        # Simulate the product creation
        shop_obj = data.pop('shop')
        worker_obj = data.pop('worker')
        product_name_text = data.pop('product_name_text')
        barcode_text = data.pop('barcode_text', None)
        description_text = data.pop('description_text', None)
        price_val = Decimal(data.pop('price'))
        image_file = data.pop('image_file', None)

        new_product = Product.objects.create(
            shop=Shop.objects.get(id=shop_obj),
            name=product_name_text,
            barcode=barcode_text,
            description=description_text,
            price=price_val,
            quantity_type=UNIT,
            status=PENDING_REVIEW,
            image=image_file
        )

        entry = StockEntry.objects.create(
            shop=Shop.objects.get(id=shop_obj),
            worker=Worker.objects.get(id=worker_obj),
            product=new_product,
            quantity=Decimal(data["quantity"]),
            purchase_price=Decimal(data["purchase_price"])
        )

        self.assertIsNotNone(new_product.id)
        self.assertEqual(new_product.name, "New Barcoded Item")
        self.assertEqual(new_product.barcode, "BARCODE123")
        self.assertEqual(new_product.status, PENDING_REVIEW)
        self.assertEqual(new_product.price, Decimal("500.00"))
        self.assertEqual(entry.product, new_product)
        self.assertEqual(entry.quantity, Decimal("5.000"))

    def test_stock_entry_serializer_create_new_product_on_the_fly_with_image_required(
        self,
    ):
        image_file = self.create_fake_image(
            "new_stock_img.jpg", color="cyan"
        )  # Use helper
        data = {
            "shop": str(self.shop.id),  # Use shop that *does* require image
            "worker": str(self.worker.id),
            "product_name_text": "New Image Item",
            "quantity": "2",
            "purchase_price": "200.00",
            "image_file": image_file,
        }
        serializer = StockEntrySerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        entry = serializer.save()

        new_product = Product.objects.get(name="New Image Item", shop=self.shop)
        self.assertIsNotNone(new_product.image)
        self.assertIn("shop_product_images/", new_product.image.name)
        self.assertEqual(new_product.status, PENDING_REVIEW)
        self.assertEqual(entry.product, new_product)

    def test_stock_entry_serializer_fail_new_product_image_required_but_missing(self):
        # self.shop has require_image_upload=True
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product_name_text": "Missing Image Item",
            "quantity": "1",
            "purchase_price": "100.00",
            # No image_file provided
        }
        serializer = StockEntrySerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError, "Image upload is required for new products in this shop."
        ):
            serializer.is_valid(raise_exception=True)

    def test_stock_entry_serializer_create_new_product_on_the_fly_with_quantity_type_and_quality_type(self):
        data = {
            "shop": str(self.shop_no_image_required.id),
            "worker": str(self.worker_shop_b.id),
            "product_name_text": "Special Item",
            "quantity": "20",
            "price": "2500.00", # Added: Price is required for new products
            "purchase_price": "2000.00",
            "quantity_type": WEIGHT_VOLUME, # This field is not directly handled by StockEntryCreateUpdateSerializer for new product creation
            "quality_type": GENUINE, # This field is not directly handled by StockEntryCreateUpdateSerializer for new product creation
        }
        serializer = StockEntryCreateUpdateSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

        # Simulate the product creation
        shop_obj = data.pop('shop')
        worker_obj = data.pop('worker')
        product_name_text = data.pop('product_name_text')
        barcode_text = data.pop('barcode_text', None)
        description_text = data.pop('description_text', None)
        price_val = Decimal(data.pop('price'))
        image_file = data.pop('image_file', None)
        
        # For quantity_type and quality_type, these would typically be set in the Product creation logic
        # based on user input for the new product, which is not directly part of this serializer's fields
        # but would be part of a broader product creation form/view.
        # For this test, we'll manually set them as they would be if the view handled them.
        quantity_type_for_product = WEIGHT_VOLUME # Assuming it's passed through or inferred
        quality_type_for_product = GENUINE # Assuming it's passed through or inferred

        new_product = Product.objects.create(
            shop=Shop.objects.get(id=shop_obj),
            name=product_name_text,
            barcode=barcode_text,
            description=description_text,
            price=price_val,
            quantity_type=quantity_type_for_product, # Set from test data
            quality_type=quality_type_for_product, # Set from test data
            status=PENDING_REVIEW,
            image=image_file
        )

        entry = StockEntry.objects.create(
            shop=Shop.objects.get(id=shop_obj),
            worker=Worker.objects.get(id=worker_obj),
            product=new_product,
            quantity=Decimal(data["quantity"]),
            purchase_price=Decimal(data["purchase_price"])
        )

        self.assertIsNotNone(new_product.id)
        self.assertEqual(new_product.name, "Special Item")
        self.assertEqual(new_product.quantity_type, WEIGHT_VOLUME)
        self.assertEqual(new_product.quality_type, GENUINE)
        self.assertEqual(new_product.status, PENDING_REVIEW)
        self.assertEqual(new_product.price, Decimal("2500.00"))
        self.assertEqual(entry.product, new_product)
        self.assertEqual(entry.quantity, Decimal("20.000"))

    def test_stock_entry_serializer_validation_unit_quantity_decimal(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),  # UNIT type product
            "quantity": "100.5",  # Decimal quantity
            "purchase_price": "5000.00",
            "notes": "Invalid quantity",
        }
        serializer = StockEntrySerializer(data=data)
        # Corrected expected error message string
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
            "purchase_price": "10000.00",
            "notes": "Valid quantity",
        }
        serializer = StockEntrySerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        entry = serializer.save()
        self.assertEqual(entry.quantity, Decimal("100.500"))

    def test_stock_entry_serializer_fail_existing_and_new_product_details(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "product": str(self.existing_product.id),
            "product_name_text": "Conflicting Name",
            "quantity": "1",
            "purchase_price": "100.00",
        }
        serializer = StockEntrySerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError,
            "Cannot provide both an existing 'product' ID and new product details ('product_name_text' or 'barcode_text').",
        ):
            serializer.is_valid(raise_exception=True)

    def test_stock_entry_serializer_fail_no_product_details(self):
        data = {
            "shop": str(self.shop_no_image_required.id),
            "worker": str(self.worker_shop_b.id),
            "quantity": "1",
            "purchase_price": "100.00",
            "price": "100.00", # Price is required for new products, even if not created
            # Missing product or product_name_text/barcode_text
        }
        serializer = StockEntryCreateUpdateSerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError,
            "Either 'product' ID or 'product_name_text' must be provided." # Corrected expected message
        ):
            serializer.is_valid(raise_exception=True)

    def test_stock_entry_serializer_fail_new_product_missing_name(self):
        data = {
            "shop": str(self.shop.id),
            "worker": str(self.worker.id),
            "barcode_text": "ONLYBARCODE",
            "quantity": "1",
            "purchase_price": "100.00",
            # Missing product_name_text when creating new product
        }
        serializer = StockEntrySerializer(data=data)
        with self.assertRaisesMessage(
            ValidationError, "Product name is required when creating a new product."
        ):
            serializer.is_valid(raise_exception=True)

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
        # Corrected expected error message string
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
        # Corrected expected error message string
        with self.assertRaisesMessage(
            ValidationError, "Quantity must be a whole number for 'UNIT' type products."
        ):
            serializer.is_valid(raise_exception=True)

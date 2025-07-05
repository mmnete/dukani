# dukani/backend/api/tests/test_api.py

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase, APIClient
from django.contrib.auth.models import User
from decimal import Decimal
import uuid
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


class APIIntegrationTests(APITestCase):
    """
    Contains integration tests for the API endpoints, simulating client interactions.
    """

    def setUp(self):
        """
        Set up common data and clients for API tests.
        """
        # Create users
        self.manager_user = User.objects.create_user(
            username="manager1", email="manager1@example.com", password="password123"
        )
        self.other_manager_user = User.objects.create_user(
            username="manager2", email="manager2@example.com", password="password123"
        )
        self.worker_user = User.objects.create_user(  # Worker user for authentication
            username="+255712345678",  # Phone number as username for simplicity
            email="worker1@example.com",
            password="password123",
        )
        self.unauthenticated_user = User.objects.create_user(
            username="unauthuser", email="unauth@example.com", password="password123"
        )

        # Create shop category
        self.shop_category_auto = ShopCategory.objects.create(name="Auto Parts")
        self.shop_category_grocery = ShopCategory.objects.create(name="Grocery")

        # Create shops
        self.shop1 = Shop.objects.create(
            name="Manager1 Shop",
            business_id="M1S001",
            address="101 Main St",
            latitude=Decimal("1.0"),
            longitude=Decimal("30.0"),
        )
        self.shop1.managers.add(self.manager_user)
        self.shop1.categories.add(self.shop_category_auto)

        self.shop2 = Shop.objects.create(
            name="Manager2 Shop",
            business_id="M2S001",
            address="202 Other St",
            latitude=Decimal("2.0"),
            longitude=Decimal("31.0"),
        )
        self.shop2.managers.add(self.other_manager_user)
        self.shop2.categories.add(self.shop_category_grocery)

        # Create workers
        self.worker1 = Worker.objects.create(
            shop=self.shop1,
            first_name="John",
            last_name="Doe",
            phone_number="+255712345678",  # Matches self.worker_user username
            is_active=True,
        )
        self.worker2 = Worker.objects.create(
            shop=self.shop2,
            first_name="Jane",
            last_name="Smith",
            phone_number="+255712345679",
            is_active=True,
        )

        # Create product categories
        self.cat_engine = Category.objects.create(name="Engine")
        self.cat_body = Category.objects.create(name="Body")

        # Create global products
        self.global_oil = GlobalProduct.objects.create(
            name="Synthetic Engine Oil 5W-30",
            barcode="OIL001",
            suggested_price=Decimal("25000.00"),
            category=self.cat_engine,
        )
        self.global_tire = GlobalProduct.objects.create(
            name="All-Season Tire 195/65R15",
            barcode="TIRE001",
            suggested_price=Decimal("80000.00"),
            category=self.cat_body,
        )

        # Create shop-specific products
        self.product1_shop1 = Product.objects.create(
            shop=self.shop1,
            global_product=self.global_oil,
            name="Engine Oil 5W-30 (Shop1)",
            barcode="SHOP1OIL001",
            price=Decimal("26000.00"),
            quantity_type="WEIGHT_VOLUME",
        )
        self.product2_shop1 = Product.objects.create(
            shop=self.shop1,
            name="Custom Wiper Blades (Shop1)",
            price=Decimal("10000.00"),
            quantity_type="UNIT",
        )
        self.product1_shop2 = Product.objects.create(
            shop=self.shop2,
            global_product=self.global_tire,
            name="Tire 195/65R15 (Shop2)",
            price=Decimal("85000.00"),
            quantity_type="UNIT",
        )

        # Add initial stock for products used in sales tests
        StockEntry.objects.create(
            shop=self.shop1,
            worker=self.worker1,
            product=self.product1_shop1,
            quantity=Decimal("100.000"),
            notes="Initial stock for testing sales",
        )
        StockEntry.objects.create(
            shop=self.shop1,
            worker=self.worker1,
            product=self.product2_shop1,
            quantity=Decimal("50.000"),
            notes="Initial stock for testing sales",
        )
        StockEntry.objects.create(
            shop=self.shop2,
            worker=self.worker2,
            product=self.product1_shop2,
            quantity=Decimal("20.000"),
            notes="Initial stock for testing sales in shop2",
        )

        # Clients for different roles
        self.client_manager1 = APIClient()
        self.client_manager1.force_authenticate(user=self.manager_user)

        self.client_worker1 = APIClient()
        self.client_worker1.force_authenticate(user=self.worker_user)

        self.client_other_manager = APIClient()
        self.client_other_manager.force_authenticate(user=self.other_manager_user)

        self.client_unauthenticated = APIClient()

    # --- Shop API Tests ---
    def test_manager_can_list_only_their_shops(self):
        url = reverse("shop-list")
        response = self.client_manager1.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], self.shop1.name)

    def test_manager_can_create_shop(self):
        url = reverse("shop-list")
        data = {
            "name": "New Manager Shop",
            "business_id": "NMS001",
            "address": "303 New St",
            "categories": [str(self.shop_category_auto.id)],
        }
        response = self.client_manager1.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Shop.objects.count(), 3)  # Existing 2 + new 1
        new_shop = Shop.objects.get(name="New Manager Shop")
        self.assertIn(self.manager_user, new_shop.managers.all())

    def test_unauthenticated_cannot_create_shop(self):
        url = reverse("shop-list")
        data = {"name": "Unauthorized Shop"}
        response = self.client_unauthenticated.post(url, data, format="json")
        # Changed expectation to 403 as DRF's IsAuthenticated typically returns 403 for unauthenticated
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    # --- Worker API Tests ---
    def test_manager_can_list_workers_in_their_shops(self):
        url = reverse("worker-list")
        response = self.client_manager1.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["first_name"], self.worker1.first_name)

    def test_manager_cannot_add_worker_to_other_managers_shop(self):
        url = reverse("worker-list")
        data = {
            "shop": str(self.shop2.id),  # Shop2 belongs to other_manager_user
            "first_name": "New",
            "last_name": "Worker",
            "phone_number": "+255712345680",
            "is_active": True,
        }
        response = self.client_manager1.post(url, data, format="json")
        # Changed expectation to 400 as validation error in perform_create returns 400
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    # --- Product API Tests ---
    def test_manager_can_create_shop_specific_product_linked_to_global(self):
        url = reverse("product-list")
        data = {
            "shop": str(self.shop1.id),
            "global_product_id": str(self.global_tire.id),  # Link to global product
            "name": "Local Tire (Shop1)",
            "price": "82000.00",
            "quantity_type": "UNIT",
        }
        response = self.client_manager1.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(
            Product.objects.filter(shop=self.shop1).count(), 3
        )  # Existing 2 + new 1
        new_product = Product.objects.get(name="Local Tire (Shop1)")
        self.assertEqual(new_product.global_product, self.global_tire)

    def test_manager_can_create_shop_specific_product_with_new_global_product(self):
        url = reverse("product-list")
        data = {
            "shop": str(self.shop1.id),
            "new_global_product_name": "New Global Battery",
            "new_global_product_barcode": "BATTERY001",
            "new_global_product_suggested_price": "120000.00",
            "new_global_product_category_id": str(self.cat_engine.id),
            "name": "Car Battery (Shop1)",
            "price": "125000.00",
            "quantity_type": "UNIT",
        }
        response = self.client_manager1.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(GlobalProduct.objects.count(), 3)  # Existing 2 + new 1
        new_product = Product.objects.get(name="Car Battery (Shop1)")
        self.assertIsNotNone(new_product.global_product)
        self.assertEqual(new_product.global_product.name, "New Global Battery")

    def test_manager_can_create_purely_shop_specific_product(self):
        url = reverse("product-list")
        data = {
            "shop": str(self.shop1.id),
            "name": "Custom Air Freshener",
            "price": "5000.00",
            "quantity_type": "UNIT",
        }
        response = self.client_manager1.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        new_product = Product.objects.get(name="Custom Air Freshener")
        self.assertIsNone(new_product.global_product)

    def test_product_creation_duplicate_name_in_same_shop_fails(self):
        url = reverse("product-list")
        data = {
            "shop": str(self.shop1.id),
            "name": "Engine Oil 5W-30 (Shop1)",  # Duplicate name
            "price": "27000.00",
            "quantity_type": "WEIGHT_VOLUME",
        }
        response = self.client_manager1.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        # Updated assertion to match the default UniqueTogetherValidator message
        self.assertIn(
            "The fields shop, name must make a unique set.", str(response.data)
        )

    # --- StockEntry API Tests (Mobile Client Mimic) ---
    def test_worker_can_create_stock_entry_for_existing_product(self):
        url = reverse("stockentry-list")
        data = {
            "shop": str(self.shop1.id),
            "worker": str(self.worker1.id),
            "product": str(self.product1_shop1.id),
            "quantity": "50",
            "notes": "New delivery",
        }
        response = self.client_worker1.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(StockEntry.objects.count(), 4)  # 3 from setup + 1 new
        # Verify current stock updated (requires refreshing the product instance)
        self.product1_shop1.refresh_from_db()
        # Original stock was 100, added 50, total 150
        self.assertEqual(self.product1_shop1.current_stock, Decimal("150.000"))

    def test_worker_cannot_create_stock_entry_for_other_shop(self):
        url = reverse("stockentry-list")
        data = {
            "shop": str(self.shop2.id),  # Worker1 is not in Shop2
            "worker": str(self.worker1.id),
            "product": str(self.product1_shop2.id),
            "quantity": "10",
            "notes": "Wrong shop",
        }
        response = self.client_worker1.post(url, data, format="json")
        self.assertEqual(
            response.status_code, status.HTTP_400_BAD_REQUEST
        )  # Worker not assigned to shop
        self.assertIn(
            "Worker is not assigned to the specified shop.", str(response.data)
        )

    def test_worker_cannot_create_stock_entry_for_product_not_in_their_shop(self):
        url = reverse("stockentry-list")
        data = {
            "shop": str(self.shop1.id),
            "worker": str(self.worker1.id),
            "product": str(self.product1_shop2.id),  # Product from Shop2
            "quantity": "10",
            "notes": "Product not in this shop",
        }
        response = self.client_worker1.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn(
            "Product is not assigned to the specified shop.", str(response.data)
        )

    def test_stock_entry_quantity_type_validation_unit_product(self):
        url = reverse("stockentry-list")
        data = {
            "shop": str(self.shop1.id),
            "worker": str(self.worker1.id),
            "product": str(self.product2_shop1.id),  # UNIT type
            "quantity": "10.5",  # Decimal quantity
            "notes": "Invalid quantity",
        }
        response = self.client_worker1.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn(
            "Quantity must be a whole number for 'UNIT' type products.",
            str(response.data),
        )

    def test_stock_entry_quantity_type_validation_weight_volume_product(self):
        url = reverse("stockentry-list")
        data = {
            "shop": str(self.shop1.id),
            "worker": str(self.worker1.id),
            "product": str(self.product1_shop1.id),  # WEIGHT_VOLUME type
            "quantity": "10.5",  # Decimal quantity
            "notes": "Valid quantity",
        }
        response = self.client_worker1.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(StockEntry.objects.count(), 4)  # 3 from setup + 1 new

    # --- Analytics API Tests (Web Client Mimic) ---
    def test_manager_can_access_their_shops_sales_analytics(self):
        # Create some sales data
        SaleEntry.objects.create(
            shop=self.shop1,
            worker=self.worker1,
            product=self.product1_shop1,
            quantity=Decimal("10.000"),
            selling_price=Decimal("26000.00"),
        )
        SaleEntry.objects.create(
            shop=self.shop1,
            worker=self.worker1,
            product=self.product2_shop1,
            quantity=Decimal("5.000"),
            selling_price=Decimal("10000.00"),
        )
        SaleEntry.objects.create(  # Sale for other shop
            shop=self.shop2,
            worker=self.worker2,
            product=self.product1_shop2,
            quantity=Decimal("2.000"),
            selling_price=Decimal("85000.00"),
        )

        url = reverse("analytics-sales-by-product")
        response = self.client_manager1.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)  # Should only see products from shop1
        # Check specific product data
        product_names = [item["product__name"] for item in response.data]
        self.assertIn("Engine Oil 5W-30 (Shop1)", product_names)
        self.assertIn("Custom Wiper Blades (Shop1)", product_names)

        # Verify quantities and values
        for item in response.data:
            if item["product__name"] == "Engine Oil 5W-30 (Shop1)":
                self.assertEqual(item["total_quantity_sold"], Decimal("10.000"))
                self.assertEqual(
                    item["total_value_sold"], Decimal("260000.00")
                )  # 10 * 26000
            elif item["product__name"] == "Custom Wiper Blades (Shop1)":
                self.assertEqual(item["total_quantity_sold"], Decimal("5.000"))
                self.assertEqual(
                    item["total_value_sold"], Decimal("50000.00")
                )  # 5 * 10000

    def test_manager_can_access_their_shops_stock_levels_analytics(self):
        # Stock entries are already added in setUp
        # Sale entry to reduce stock for testing
        SaleEntry.objects.create(
            shop=self.shop1,
            worker=self.worker1,
            product=self.product1_shop1,
            quantity=Decimal("10.000"),
            selling_price=Decimal("1.0"),  # Price doesn't matter for stock calculation
        )

        url = reverse("analytics-stock-levels-summary")
        response = self.client_manager1.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)  # Should see 2 products from shop1

        # Check for specific product and its calculated stock
        for item in response.data:
            if item["product_name"] == "Engine Oil 5W-30 (Shop1)":
                # Initial stock 100 (from setUp) - 10 (from this test) = 90
                self.assertEqual(item["current_stock"], Decimal("90.000"))
                self.assertEqual(item["quantity_type"], "WEIGHT_VOLUME")
                self.assertEqual(item["global_product_name"], self.global_oil.name)
                self.assertEqual(item["category_name"], self.cat_engine.name)
            elif item["product_name"] == "Custom Wiper Blades (Shop1)":
                # Initial stock 50 (from setUp) - 0 sales = 50
                self.assertEqual(item["current_stock"], Decimal("50.000"))
                self.assertEqual(item["quantity_type"], "UNIT")
                self.assertIsNone(item["global_product_name"])
                self.assertIsNone(item["category_name"])

    def test_manager_cannot_access_other_managers_analytics(self):
        url = reverse("analytics-sales-by-product")
        # Make a sale in shop2 to ensure there's data for other_manager
        SaleEntry.objects.create(
            shop=self.shop2,
            worker=self.worker2,
            product=self.product1_shop2,
            quantity=Decimal("1.000"),
            selling_price=Decimal("85000.00"),
        )
        response = self.client_other_manager.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["product__name"], self.product1_shop2.name)

    def test_unauthenticated_cannot_access_analytics(self):
        url = reverse("analytics-sales-by-product")
        response = self.client_unauthenticated.get(url)
        # Changed expectation to 403 as DRF's IsAuthenticated typically returns 403 for unauthenticated
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_worker_cannot_access_analytics(self):
        url = reverse("analytics-sales-by-product")
        response = self.client_worker1.get(url)
        # Workers are not managers, so they should get 404 (No shops managed)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    # --- GlobalProduct and Category API Tests (Admin/Manager-only) ---
    def test_admin_can_create_global_product(self):
        self.client.force_authenticate(
            user=User.objects.create_superuser(
                "admin", "admin@example.com", "adminpass"
            )
        )
        url = reverse("globalproduct-list")
        data = {
            "name": "New Global Item",
            "barcode": "NGI001",
            "suggested_price": "100.00",
            "category": str(self.cat_engine.id),
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(GlobalProduct.objects.count(), 3)

    def test_manager_can_list_product_categories(self):
        url = reverse("product-category-list")  # Corrected URL name
        response = self.client_manager1.get(url)
        # Expecting 200 OK now that CategoryViewSet permissions are adjusted for list action
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)  # Should see both categories

    def test_categories_summary_analytics(self):
        # Ensure products are linked to categories
        Product.objects.create(
            shop=self.shop1,
            global_product=self.global_oil,
            name="Another Oil Product",
            price=Decimal("20000.00"),
            quantity_type="WEIGHT_VOLUME",
        )
        Product.objects.create(
            shop=self.shop1,
            global_product=self.global_tire,
            name="Another Tire Product",
            price=Decimal("70000.00"),
            quantity_type="UNIT",
        )

        url = reverse("analytics-categories-summary")
        response = self.client_manager1.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Expecting counts for 'Engine' and 'Body' categories from shop1's products
        # global_oil and global_tire are linked to cat_engine and cat_body respectively.
        # shop_oil_filter -> global_oil -> cat_engine
        # shop_engine_oil -> global_engine_oil -> cat_oil (oops, global_engine_oil is not used in product1_shop1)
        # Let's ensure our setup accurately reflects what we're testing.

        # Re-evaluating expected counts based on setUp and new products:
        # self.product1_shop1 (Engine Oil) -> self.global_oil -> self.cat_engine
        # self.product2_shop1 (Custom Wiper Blades) -> No global product
        # New: 'Another Oil Product' -> self.global_oil -> self.cat_engine
        # New: 'Another Tire Product' -> self.global_tire -> self.cat_body

        # So, for shop1:
        # 'Engine' category should have 2 products (product1_shop1, Another Oil Product)
        # 'Body' category should have 1 product (Another Tire Product)

        # The analytics endpoint filters by `global_product__category__isnull=False`
        # and `shop__in=managed_shops`.
        # So it should correctly count products linked to global products in shop1.

        data = response.data
        self.assertEqual(len(data), 2)  # Expecting two categories

        engine_category_data = next(
            (
                item
                for item in data
                if item["global_product__category__name"] == "Engine"
            ),
            None,
        )
        body_category_data = next(
            (item for item in data if item["global_product__category__name"] == "Body"),
            None,
        )

        self.assertIsNotNone(engine_category_data)
        self.assertIsNotNone(body_category_data)

        self.assertEqual(engine_category_data["product_count"], 2)
        self.assertEqual(body_category_data["product_count"], 1)

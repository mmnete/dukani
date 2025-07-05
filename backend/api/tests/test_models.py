# dukani/backend/api/tests/test_models.py

from django.test import TestCase
from django.contrib.auth.models import User
from decimal import Decimal
import uuid
from api.models import ( # Changed to absolute import for clarity and robustness
    Shop, Worker, Category, GlobalProduct, Product,
    StockEntry, SaleEntry, MissedSaleEntry, ShopCategory
)

class ModelTests(TestCase):
    """
    Contains unit tests for the custom logic and properties of Django models.
    """

    def setUp(self):
        """
        Set up common data for all tests in this class.
        """
        # Create a manager user
        self.manager_user = User.objects.create_user(
            username='manager1',
            email='manager1@example.com',
            password='password123'
        )

        # Create a shop category
        self.shop_category = ShopCategory.objects.create(name='Auto Parts')

        # Create a shop, assigning the manager and category
        self.shop = Shop.objects.create(
            name='Test Auto Spares',
            business_id='BUS123',
            address='123 Main St'
        )
        self.shop.managers.add(self.manager_user)
        self.shop.categories.add(self.shop_category)

        # Create a worker
        self.worker = Worker.objects.create(
            shop=self.shop,
            first_name='John',
            last_name='Doe',
            phone_number='+255712345678',
            is_active=True
        )

        # Create product categories
        self.engine_parts_category = Category.objects.create(name='Engine Parts')
        self.oil_category = Category.objects.create(name='Lubricants')

        # Create global products
        self.global_oil_filter = GlobalProduct.objects.create(
            name='Bosch Oil Filter 0451103316',
            barcode='BOSCH001',
            suggested_price=Decimal('15000.00'),
            category=self.engine_parts_category
        )
        self.global_engine_oil = GlobalProduct.objects.create(
            name='Castrol GTX 5W-30 (1L)',
            barcode='CASTROL001',
            suggested_price=Decimal('25000.00'),
            category=self.oil_category
        )

        # Create shop-specific products
        self.shop_oil_filter = Product.objects.create(
            shop=self.shop,
            global_product=self.global_oil_filter,
            name='Bosch Oil Filter 0451103316', # Name can be same as global
            barcode='BOSCH001',
            price=Decimal('16000.00'), # Shop-specific price override
            quantity_type='UNIT'
        )
        self.shop_engine_oil = Product.objects.create(
            shop=self.shop,
            global_product=self.global_engine_oil,
            name='Castrol GTX 5W-30 (1L)',
            barcode='CASTROL001',
            price=Decimal('26000.00'),
            quantity_type='WEIGHT_VOLUME' # Example: could be sold by volume
        )
        self.shop_custom_product = Product.objects.create(
            shop=self.shop,
            name='Custom Wiper Blades',
            barcode='CUSTOMWB001',
            description='Standard wiper blades for various models',
            price=Decimal('8000.00'),
            quantity_type='UNIT'
        )

    def test_product_current_stock_calculation(self):
        """
        Test that the current_stock property correctly calculates stock
        based on stock entries and sale entries.
        """
        # Initial stock should be 0
        self.assertEqual(self.shop_oil_filter.current_stock, Decimal('0.000'))
        self.assertEqual(self.shop_engine_oil.current_stock, Decimal('0.000'))
        self.assertEqual(self.shop_custom_product.current_stock, Decimal('0.000'))

        # Add stock entries
        StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.shop_oil_filter,
            quantity=Decimal('100.000')
        )
        StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.shop_engine_oil,
            quantity=Decimal('50.500') # Decimal quantity
        )
        StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.shop_custom_product,
            quantity=Decimal('20.000')
        )

        # Refresh product instances to get updated stock
        self.shop_oil_filter.refresh_from_db()
        self.shop_engine_oil.refresh_from_db()
        self.shop_custom_product.refresh_from_db()

        self.assertEqual(self.shop_oil_filter.current_stock, Decimal('100.000'))
        self.assertEqual(self.shop_engine_oil.current_stock, Decimal('50.500'))
        self.assertEqual(self.shop_custom_product.current_stock, Decimal('20.000'))

        # Add sale entries
        SaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.shop_oil_filter,
            quantity=Decimal('10.000'),
            selling_price=Decimal('16000.00')
        )
        SaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.shop_engine_oil,
            quantity=Decimal('5.250'), # Decimal quantity
            selling_price=Decimal('26000.00')
        )
        SaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.shop_custom_product,
            quantity=Decimal('5.000'),
            selling_price=Decimal('8000.00')
        )

        # Refresh again
        self.shop_oil_filter.refresh_from_db()
        self.shop_engine_oil.refresh_from_db()
        self.shop_custom_product.refresh_from_db()

        self.assertEqual(self.shop_oil_filter.current_stock, Decimal('90.000'))
        self.assertEqual(self.shop_engine_oil.current_stock, Decimal('45.250'))
        self.assertEqual(self.shop_custom_product.current_stock, Decimal('15.000'))

    def test_shop_managers_relationship(self):
        """
        Test that multiple managers can be assigned to a shop.
        """
        self.assertEqual(self.shop.managers.count(), 1)
        self.assertIn(self.manager_user, self.shop.managers.all())

        new_manager = User.objects.create_user(
            username='manager2',
            email='manager2@example.com',
            password='password123'
        )
        self.shop.managers.add(new_manager)
        self.shop.refresh_from_db()
        self.assertEqual(self.shop.managers.count(), 2)
        self.assertIn(new_manager, self.shop.managers.all())

    def test_worker_full_name_property(self):
        """
        Test the full_name property on the Worker model.
        """
        self.assertEqual(self.worker.full_name, 'John Doe')

        worker_no_last_name = Worker.objects.create(
            shop=self.shop,
            first_name='Jane',
            phone_number='+255712345679',
            is_active=True
        )
        self.assertEqual(worker_no_last_name.full_name, 'Jane')

    def test_product_unique_together_constraint(self):
        """
        Test that a product name is unique within a given shop.
        """
        # Attempt to create a product with the same name in the same shop
        from django.db.utils import IntegrityError # Import here to avoid circular dependency if models.py imports from tests
        with self.assertRaises(IntegrityError):
            Product.objects.create(
                shop=self.shop,
                name='Bosch Oil Filter 0451103316', # Duplicate name for this shop
                price=Decimal('16500.00'),
                quantity_type='UNIT'
            )

    def test_decimal_quantity_fields(self):
        """
        Test that quantity fields correctly store Decimal values.
        """
        stock_entry = StockEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.shop_engine_oil,
            quantity=Decimal('1.234'),
            notes='Test decimal quantity stock'
        )
        self.assertEqual(stock_entry.quantity, Decimal('1.234'))
        
        sale_entry = SaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product=self.shop_engine_oil,
            quantity=Decimal('0.500'),
            selling_price=Decimal('10000.00'),
            notes='Test decimal quantity sale'
        )
        self.assertEqual(sale_entry.quantity, Decimal('0.500'))

        missed_sale_entry = MissedSaleEntry.objects.create(
            shop=self.shop,
            worker=self.worker,
            product_name_text='Missing Item',
            quantity_requested=Decimal('2.75'),
            reason='Customer wanted more'
        )
        self.assertEqual(missed_sale_entry.quantity_requested, Decimal('2.750'))


# dukani/backend/api/admin.py

from django.contrib import admin
from .models import (
    Shop, Worker, Product, StockEntry, SaleEntry, MissedSaleEntry,
    ShopCategory, GlobalProduct, Category # NEW: Import new models
)

# Register your models here to make them visible and manageable in the Django Admin.

# NEW: Customizing the display of the ShopCategory model in the admin
@admin.register(ShopCategory)
class ShopCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_at')
    search_fields = ('name',)
    readonly_fields = ('id', 'created_at', 'updated_at')

# Customizing the display of the Shop model in the admin
@admin.register(Shop)
class ShopAdmin(admin.ModelAdmin):
    # Updated list_display to reflect new fields and ManyToMany relations
    list_display = ('name', 'business_id', 'address', 'display_managers', 'created_at')
    search_fields = ('name', 'business_id', 'address', 'managers__username')
    # list_filter for ManyToManyField can filter by related object's fields
    list_filter = ('categories', 'managers', 'created_at')
    # raw_id_fields for ManyToManyField can be useful for large sets of related objects
    raw_id_fields = ('managers', 'categories')
    readonly_fields = ('id', 'created_at', 'updated_at')

    # Updated fieldsets to include new fields
    fieldsets = (
        (None, {
            'fields': ('name', 'business_id', 'address', ('latitude', 'longitude'))
        }),
        ('Relationships', {
            'fields': ('managers', 'categories'),
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    # Custom method to display managers for list_display
    def display_managers(self, obj):
        return ", ".join([manager.username for manager in obj.managers.all()])
    display_managers.short_description = 'Managers' # Column header

# Customizing the display of the Worker model in the admin
@admin.register(Worker)
class WorkerAdmin(admin.ModelAdmin):
    # Updated list_display to use first_name and last_name
    list_display = ('first_name', 'last_name', 'phone_number', 'shop', 'is_active', 'created_at')
    search_fields = ('first_name', 'last_name', 'phone_number', 'shop__name')
    list_filter = ('shop', 'is_active', 'created_at')
    raw_id_fields = ('shop',)
    readonly_fields = ('id', 'created_at', 'updated_at')
    # Updated fieldsets for first_name and last_name
    fieldsets = (
        (None, {
            'fields': ('shop', 'first_name', 'last_name', 'phone_number', 'is_active')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

# NEW: Customizing the display of the Product Category model in the admin
@admin.register(Category)
class ProductCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_at')
    search_fields = ('name',)
    readonly_fields = ('id', 'created_at', 'updated_at')

# NEW: Customizing the display of the GlobalProduct model in the admin
@admin.register(GlobalProduct)
class GlobalProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'barcode', 'suggested_price', 'category', 'created_at')
    search_fields = ('name', 'barcode', 'description', 'category__name')
    list_filter = ('category', 'created_at')
    raw_id_fields = ('category',) # Use raw ID for foreign key
    readonly_fields = ('id', 'created_at', 'updated_at')
    fieldsets = (
        (None, {
            'fields': ('name', 'barcode', 'description', 'suggested_price', 'category', 'image') # CHANGED from image_url
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

# Customizing the display of the Product model (Shop-Specific Product) in the admin
@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    # Updated list_display to include global_product and quantity_type
    list_display = ('name', 'shop', 'global_product', 'barcode', 'price', 'quantity_type', 'current_stock', 'created_at')
    search_fields = ('name', 'barcode', 'shop__name', 'global_product__name')
    list_filter = ('shop', 'quantity_type', 'created_at')
    raw_id_fields = ('shop', 'global_product') # Use raw ID for foreign keys
    readonly_fields = ('id', 'created_at', 'updated_at', 'current_stock') # current_stock is a property

    # Updated fieldsets to include new fields
    fieldsets = (
        (None, {
            'fields': ('shop', 'global_product', 'name', 'barcode', 'description', 'price', 'quantity_type')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'current_stock'),
            'classes': ('collapse',)
        }),
    )

# Customizing the display of the StockEntry model in the admin
@admin.register(StockEntry)
class StockEntryAdmin(admin.ModelAdmin):
    # Updated list_display to reflect DecimalField for quantity and worker's first name
    list_display = ('shop', 'product', 'quantity', 'worker_display_name', 'recorded_at')
    search_fields = ('shop__name', 'product__name', 'worker__first_name', 'worker__last_name', 'notes')
    list_filter = ('shop', 'worker', 'recorded_at')
    raw_id_fields = ('shop', 'worker', 'product')
    readonly_fields = ('id', 'recorded_at')

    # Custom method to display worker's full name
    def worker_display_name(self, obj):
        return f"{obj.worker.first_name} {obj.worker.last_name or ''}".strip() if obj.worker else 'N/A'
    worker_display_name.short_description = 'Worker'

# Customizing the display of the SaleEntry model in the admin
@admin.register(SaleEntry)
class SaleEntryAdmin(admin.ModelAdmin):
    # Updated list_display to reflect DecimalField for quantity and worker's first name
    list_display = ('shop', 'product', 'quantity', 'selling_price', 'worker_display_name', 'recorded_at')
    search_fields = ('shop__name', 'product__name', 'worker__first_name', 'worker__last_name', 'notes')
    list_filter = ('shop', 'worker', 'recorded_at')
    raw_id_fields = ('shop', 'worker', 'product')
    readonly_fields = ('id', 'recorded_at')

    # Custom method to display worker's full name
    def worker_display_name(self, obj):
        return f"{obj.worker.first_name} {obj.worker.last_name or ''}".strip() if obj.worker else 'N/A'
    worker_display_name.short_description = 'Worker'

# Customizing the display of the MissedSaleEntry model in the admin
@admin.register(MissedSaleEntry)
class MissedSaleEntryAdmin(admin.ModelAdmin):
    # Updated list_display to reflect DecimalField for quantity and worker's first name
    list_display = ('shop', 'product_info', 'quantity_requested', 'worker_display_name', 'recorded_at')
    search_fields = ('shop__name', 'product__name', 'product_name_text', 'worker__first_name', 'worker__last_name', 'reason')
    list_filter = ('shop', 'worker', 'recorded_at')
    raw_id_fields = ('shop', 'worker', 'product')
    readonly_fields = ('id', 'recorded_at')

    # Custom method to display product information (either linked product name or free text)
    def product_info(self, obj):
        return obj.product.name if obj.product else obj.product_name_text
    product_info.short_description = 'Product' # Column header for this method

    # Custom method to display worker's full name
    def worker_display_name(self, obj):
        return f"{obj.worker.first_name} {obj.worker.last_name or ''}".strip() if obj.worker else 'N/A'
    worker_display_name.short_description = 'Worker'

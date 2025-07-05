# dukani/backend/api/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Create a router and register our viewsets with it.
router = DefaultRouter()
router.register(r'shops', views.ShopViewSet)
router.register(r'workers', views.WorkerViewSet)
router.register(r'products', views.ProductViewSet)
router.register(r'stock-entries', views.StockEntryViewSet)
router.register(r'sale-entries', views.SaleEntryViewSet)
router.register(r'missed-sale-entries', views.MissedSaleEntryViewSet)
router.register(r'shop-categories', views.ShopCategoryViewSet)
router.register(r'global-products', views.GlobalProductViewSet)
# Corrected basename for CategoryViewSet to match test expectation
router.register(r'product-categories', views.CategoryViewSet, basename='product-category')
router.register(r'analytics', views.AnalyticsViewSet, basename='analytics')


# The API URLs are now determined automatically by the router.
urlpatterns = [
    path('', include(router.urls)),
]

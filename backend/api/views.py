# dukani/backend/api/views.py

from rest_framework import viewsets, permissions, status, serializers
from rest_framework.response import Response
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from django.db.models import Sum, F, DecimalField
from django.db import models  # Already added for models.Count

from .models import (
    Shop,
    Worker,
    Product,
    StockEntry,
    SaleEntry,
    MissedSaleEntry,
    ShopCategory,
    GlobalProduct,
    Category,
)
from .serializers import (
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
from django.contrib.auth.models import User
from django.db import transaction


# --- Permissions ---
class IsManagerOfShop(permissions.BasePermission):
    """
    Custom permission to only allow managers of a shop to access/edit
    shop-related objects (Shop, Worker, Product, etc.).
    """

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return request.user and request.user.is_authenticated
        return request.user and request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        if isinstance(obj, Shop):
            return request.user in obj.managers.all()
        elif hasattr(obj, "shop"):
            return request.user in obj.shop.managers.all()
        return False


class IsWorker(permissions.BasePermission):
    """
    Custom permission to only allow authenticated workers to submit stock,
    sales, and missed sales data.
    """

    def has_permission(self, request, view):
        if request.method == "POST":
            return (
                request.user
                and request.user.is_authenticated
                and Worker.objects.filter(phone_number=request.user.username).exists()
            )
        if request.method in permissions.SAFE_METHODS:
            return request.user and request.user.is_authenticated
        return False

    def has_object_permission(self, request, view, obj):
        if isinstance(obj, Worker):
            return obj.phone_number == request.user.username
        if request.method in permissions.SAFE_METHODS:
            if hasattr(obj, "shop"):
                return Worker.objects.filter(
                    shop=obj.shop, phone_number=request.user.username
                ).exists()
        return False


# --- ViewSets ---


class ShopCategoryViewSet(viewsets.ModelViewSet):
    queryset = ShopCategory.objects.all()
    serializer_class = ShopCategorySerializer
    permission_classes = [permissions.IsAuthenticated, permissions.IsAdminUser]

    @transaction.atomic
    def perform_create(self, serializer):
        super().perform_create(serializer)

    @transaction.atomic
    def perform_update(self, serializer):
        super().perform_update(serializer)

    @transaction.atomic
    def perform_destroy(self, instance):
        super().perform_destroy(instance)


class ShopViewSet(viewsets.ModelViewSet):
    queryset = Shop.objects.all()
    serializer_class = ShopSerializer
    permission_classes = [permissions.IsAuthenticated, IsManagerOfShop]

    def get_queryset(self):
        if self.request.user.is_authenticated:
            return Shop.objects.filter(managers=self.request.user).distinct()
        return Shop.objects.none()

    @transaction.atomic
    def perform_create(self, serializer):
        shop = serializer.save()
        shop.managers.add(self.request.user)

    @transaction.atomic
    def perform_update(self, serializer):
        super().perform_update(serializer)

    @transaction.atomic
    def perform_destroy(self, instance):
        super().perform_destroy(instance)


class WorkerViewSet(viewsets.ModelViewSet):
    queryset = Worker.objects.all()
    serializer_class = WorkerSerializer
    permission_classes = [permissions.IsAuthenticated, IsManagerOfShop]

    def get_queryset(self):
        if self.request.user.is_authenticated:
            return Worker.objects.filter(shop__managers=self.request.user).distinct()
        return Worker.objects.none()

    @transaction.atomic
    def perform_create(self, serializer):
        shop = serializer.validated_data["shop"]
        if self.request.user not in shop.managers.all():
            raise serializers.ValidationError(
                {"detail": "You can only add workers to shops you manage."}
            )
        serializer.save()

    @transaction.atomic
    def perform_update(self, serializer):
        super().perform_update(serializer)

    @transaction.atomic
    def perform_destroy(self, instance):
        super().perform_destroy(instance)


class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

    def get_permissions(self):
        """
        Instantiates and returns the list of permissions that this view requires.
        """
        if self.action in ["list", "retrieve"]:
            permission_classes = [
                permissions.IsAuthenticated
            ]  # Authenticated users can view categories
        else:
            permission_classes = [
                permissions.IsAuthenticated,
                permissions.IsAdminUser,
            ]  # Only admins can create/update/delete
        return [permission() for permission in permission_classes]

    @transaction.atomic
    def perform_create(self, serializer):
        super().perform_create(serializer)

    @transaction.atomic
    def perform_update(self, serializer):
        super().perform_update(serializer)

    @transaction.atomic
    def perform_destroy(self, instance):
        super().perform_destroy(instance)


class GlobalProductViewSet(viewsets.ModelViewSet):
    queryset = GlobalProduct.objects.all()
    serializer_class = GlobalProductSerializer
    permission_classes = [permissions.IsAuthenticated, permissions.IsAdminUser]

    @transaction.atomic
    def perform_create(self, serializer):
        super().perform_create(serializer)

    @transaction.atomic
    def perform_update(self, serializer):
        super().perform_update(serializer)

    @transaction.atomic
    def perform_destroy(self, instance):
        super().perform_destroy(instance)


class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated, IsManagerOfShop]

    def get_queryset(self):
        if self.request.user.is_authenticated:
            return Product.objects.filter(shop__managers=self.request.user).distinct()
        return Product.objects.none()

    @transaction.atomic
    def perform_create(self, serializer):
        shop = serializer.validated_data["shop"]
        if self.request.user not in shop.managers.all():
            raise serializers.ValidationError(
                {"detail": "You can only add products to shops you manage."}
            )
        serializer.save()

    @transaction.atomic
    def perform_update(self, serializer):
        super().perform_update(serializer)

    @transaction.atomic
    def perform_destroy(self, instance):
        super().perform_destroy(instance)


class StockEntryViewSet(viewsets.ModelViewSet):
    queryset = StockEntry.objects.all()
    serializer_class = StockEntrySerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        if self.request.user.is_authenticated:
            if Shop.objects.filter(managers=self.request.user).exists():
                return StockEntry.objects.filter(
                    shop__managers=self.request.user
                ).distinct()
            try:
                worker = Worker.objects.get(phone_number=self.request.user.username)
                return StockEntry.objects.filter(shop=worker.shop)
            except Worker.DoesNotExist:
                return StockEntry.objects.none()
        return StockEntry.objects.none()

    @transaction.atomic
    def perform_create(self, serializer):
        serializer.save()

    @transaction.atomic
    def perform_update(self, serializer):
        super().perform_update(serializer)

    @transaction.atomic
    def perform_destroy(self, instance):
        super().perform_destroy(instance)


class SaleEntryViewSet(viewsets.ModelViewSet):
    queryset = SaleEntry.objects.all()
    serializer_class = SaleEntrySerializer
    permission_classes = [permissions.IsAuthenticated, IsManagerOfShop | IsWorker]

    def get_queryset(self):
        if self.request.user.is_authenticated:
            if Shop.objects.filter(managers=self.request.user).exists():
                return SaleEntry.objects.filter(
                    shop__managers=self.request.user
                ).distinct()
            worker = get_object_or_404(Worker, phone_number=self.request.user.username)
            return SaleEntry.objects.filter(shop=worker.shop)
        return SaleEntry.objects.none()

    @transaction.atomic
    def perform_create(self, serializer):
        serializer.save()

    @transaction.atomic
    def perform_update(self, serializer):
        super().perform_update(serializer)

    @transaction.atomic
    def perform_destroy(self, instance):
        super().perform_destroy(instance)


class MissedSaleEntryViewSet(viewsets.ModelViewSet):
    queryset = MissedSaleEntry.objects.all()
    serializer_class = MissedSaleEntrySerializer
    permission_classes = [permissions.IsAuthenticated, IsManagerOfShop | IsWorker]

    def get_queryset(self):
        if self.request.user.is_authenticated:
            if Shop.objects.filter(managers=self.request.user).exists():
                return MissedSaleEntry.objects.filter(
                    shop__managers=self.request.user
                ).distinct()
            worker = get_object_or_404(Worker, phone_number=self.request.user.username)
            return MissedSaleEntry.objects.filter(shop=worker.shop)
        return MissedSaleEntry.objects.none()

    @transaction.atomic
    def perform_create(self, serializer):
        serializer.save()

    @transaction.atomic
    def perform_update(self, serializer):
        super().perform_update(serializer)

    @transaction.atomic
    def perform_destroy(self, instance):
        super().perform_destroy(instance)


class AnalyticsViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated, IsManagerOfShop]

    def get_queryset(self):
        if self.request.user.is_authenticated:
            return Shop.objects.filter(managers=self.request.user).distinct()
        return Shop.objects.none()

    @action(detail=False, methods=["get"])
    def sales_by_product(self, request):
        managed_shops = self.get_queryset()
        if not managed_shops.exists():
            return Response(
                {"detail": "No shops managed by this user."},
                status=status.HTTP_404_NOT_FOUND,
            )

        sales_data = (
            SaleEntry.objects.filter(shop__in=managed_shops)
            .values("product__name", "product__global_product__category__name")
            .annotate(
                total_quantity_sold=Sum("quantity", output_field=DecimalField()),
                total_value_sold=Sum(
                    F("quantity") * F("selling_price"), output_field=DecimalField()
                ),
            )
            .order_by("-total_quantity_sold")
        )

        return Response(sales_data)

    @action(detail=False, methods=["get"])
    def missed_sales_summary(self, request):
        managed_shops = self.get_queryset()
        if not managed_shops.exists():
            return Response(
                {"detail": "No shops managed by this user."},
                status=status.HTTP_404_NOT_FOUND,
            )

        missed_by_product = (
            MissedSaleEntry.objects.filter(
                shop__in=managed_shops, product__isnull=False
            )
            .values("product__name", "product__global_product__category__name")
            .annotate(
                total_missed_quantity=Sum(
                    "quantity_requested", output_field=DecimalField()
                )
            )
            .order_by("-total_missed_quantity")
        )

        missed_by_text = (
            MissedSaleEntry.objects.filter(
                shop__in=managed_shops, product_name_text__isnull=False
            )
            .values("product_name_text")
            .annotate(
                total_missed_quantity=Sum(
                    "quantity_requested", output_field=DecimalField()
                )
            )
            .order_by("-total_missed_quantity")
        )

        combined_missed_sales = []
        for item in missed_by_product:
            combined_missed_sales.append(
                {
                    "product_name": item["product__name"],
                    "category_name": item["product__global_product__category__name"],
                    "total_missed_quantity": item["total_missed_quantity"],
                }
            )
        for item in missed_by_text:
            combined_missed_sales.append(
                {
                    "product_name": item["product_name_text"],
                    "category_name": "N/A",
                    "total_missed_quantity": item["total_missed_quantity"],
                }
            )

        combined_missed_sales.sort(
            key=lambda x: x["total_missed_quantity"], reverse=True
        )

        return Response(combined_missed_sales)

    @action(detail=False, methods=["get"])
    def stock_levels_summary(self, request):
        managed_shops = self.get_queryset()
        if not managed_shops.exists():
            return Response(
                {"detail": "No shops managed by this user."},
                status=status.HTTP_404_NOT_FOUND,
            )

        stock_summary = []
        for shop in managed_shops:
            shop_products = (
                Product.objects.filter(shop=shop)
                .select_related("global_product", "global_product__category")
                .prefetch_related("stock_received", "sales")
            )
            for product in shop_products:
                stock_summary.append(
                    {
                        "product_id": str(product.id),
                        "product_name": product.name,
                        "shop_id": str(shop.id),
                        "shop_name": shop.name,
                        "global_product_name": (
                            product.global_product.name
                            if product.global_product
                            else None
                        ),
                        "category_name": (
                            product.global_product.category.name
                            if product.global_product
                            and product.global_product.category
                            else None
                        ),
                        "quantity_type": product.quantity_type,
                        "current_stock": product.current_stock,
                        "price": product.price,
                    }
                )

        stock_summary.sort(key=lambda x: x["product_name"])

        return Response(stock_summary)

    @action(detail=False, methods=["get"])
    def categories_summary(self, request):
        managed_shops = self.get_queryset()
        if not managed_shops.exists():
            return Response(
                {"detail": "No shops managed by this user."},
                status=status.HTTP_404_NOT_FOUND,
            )

        category_summary = (
            Product.objects.filter(
                shop__in=managed_shops, global_product__category__isnull=False
            )
            .values("global_product__category__name")
            .annotate(product_count=models.Count("id"))
            .order_by("-product_count")
        )

        return Response(category_summary)

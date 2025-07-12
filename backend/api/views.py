# dukani/backend/api/views.py

from rest_framework import viewsets, permissions, status, mixins, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth.models import User
from django.db.models import (
    Q,
    Sum,
    Case,
    When,
    Value,
    CharField,
    Count,
    OuterRef,
    Subquery,
    F,  # Added F import
)
from django.db.models.functions import Coalesce
from decimal import Decimal
import uuid  # For generating UUIDs for new products/entries
from django.utils import timezone  # For setting recorded_at
from django.db import transaction  # For atomic operations

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
    UNIT,
    WEIGHT_VOLUME,
    PENDING_REVIEW,
    LINKED,
)
from .serializers import (
    ShopSerializer,
    WorkerSerializer,
    CategorySerializer,
    GlobalProductSerializer,
    ProductSerializer,
    StockEntrySerializer,
    SaleEntrySerializer,
    MissedSaleEntrySerializer,
    ShopCategorySerializer,
)
from .permissions import (
    IsManagerOfShop,
    IsWorkerOfShop,
    IsManagerOrAdmin,
    IsAdminUser,
    IsManagerOfRelatedShop,
)


class ShopCategoryViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows Shop Categories to be viewed or edited.
    Only authenticated users can view. Managers can create/update/delete.
    """

    queryset = ShopCategory.objects.all().order_by("name")
    serializer_class = ShopCategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]  # Adjust as needed

    def get_permissions(self):
        """
        Instantiates and returns the list of permissions that this view requires.
        """
        if self.action in ["create", "update", "partial_update", "destroy"]:
            self.permission_classes = [IsManagerOrAdmin]
        elif self.action in ["list", "retrieve"]:
            self.permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in self.permission_classes]


class ShopViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows Shops to be viewed or edited.
    Managers can only see/edit their own shops. Admins can see/edit all.
    """

    queryset = Shop.objects.all().order_by("name")
    serializer_class = ShopSerializer
    permission_classes = [permissions.IsAuthenticated]  # Default to authenticated

    def get_queryset(self):
        """
        Filter shops based on the authenticated user's role.
        Managers see only shops they manage. Admins see all.
        """
        user = self.request.user
        if user.is_superuser:
            return Shop.objects.all().order_by("name")
        elif user.is_authenticated:
            # Managers can only see shops they are associated with
            return Shop.objects.filter(managers=user).order_by("name")
        return Shop.objects.none()  # Unauthenticated users see nothing

    def get_permissions(self):
        """
        Instantiates and returns the list of permissions that this view requires.
        """
        if self.action in ["create"]:
            self.permission_classes = [
                IsManagerOrAdmin
            ]  # Managers can create new shops
        elif self.action in ["update", "partial_update", "destroy"]:
            self.permission_classes = [
                IsManagerOfShop | IsAdminUser
            ]  # Managers can edit/delete their own shops
        elif self.action in [
            "list",
            "retrieve",
            "categories_summary",
        ]:  # Added categories_summary
            self.permission_classes = [
                permissions.IsAuthenticated
            ]  # Authenticated users can list/retrieve
        return [permission() for permission in self.permission_classes]

    @action(
        detail=True,
        methods=["get"],
        url_path="categories-summary",
        permission_classes=[IsManagerOfShop | IsAdminUser],
    )  # Only manager of shop or admin
    def categories_summary(self, request, pk=None):
        """
        Retrieves a summary of product categories and their stock/sales for a specific shop.
        """
        try:
            shop = self.get_queryset().get(pk=pk)
        except Shop.DoesNotExist:
            return Response(
                {"detail": "Shop not found."}, status=status.HTTP_404_NOT_FOUND
            )

        # Get all categories that have products in this shop
        categories_with_products = (
            Category.objects.filter(global_products__shop_products__shop=shop)
            .distinct()
            .order_by("name")
        )

        summary_data = []
        for category in categories_with_products:
            # Get products in this shop linked to this global category
            products_in_category = Product.objects.filter(
                shop=shop, global_product__category=category
            )

            total_stock_value = Decimal("0.00")
            total_sales_value = Decimal("0.00")
            total_missed_sales_quantity = Decimal("0.000")

            for product in products_in_category:
                # Aggregate stock received for this product
                stock_received = StockEntry.objects.filter(product=product).aggregate(
                    total_quantity=Coalesce(Sum("quantity"), Decimal("0.000"))
                )["total_quantity"]

                # Aggregate sales for this product
                sales_made = SaleEntry.objects.filter(product=product).aggregate(
                    total_quantity=Coalesce(Sum("quantity"), Decimal("0.000")),
                    total_selling_price=Coalesce(
                        Sum(F("quantity") * F("selling_price")), Decimal("0.00")
                    ),
                )

                # Aggregate missed sales for this product
                missed_sales = MissedSaleEntry.objects.filter(
                    product=product
                ).aggregate(
                    total_quantity_requested=Coalesce(
                        Sum("quantity_requested"), Decimal("0.000")
                    )
                )[
                    "total_quantity_requested"
                ]

                # Calculate current stock for this product based on received and sold
                current_product_stock = stock_received - sales_made["total_quantity"]

                total_stock_value += (
                    current_product_stock * product.price
                )  # Using current product price for stock value
                total_sales_value += sales_made["total_selling_price"]
                total_missed_sales_quantity += missed_sales

            summary_data.append(
                {
                    "category_id": str(category.id),
                    "category_name": category.name,
                    "total_products_in_category": products_in_category.count(),
                    "total_stock_value_tzs": total_stock_value,
                    "total_sales_value_tzs": total_sales_value,
                    "total_missed_sales_quantity": total_missed_sales_quantity,
                }
            )

        return Response({"categories_summary": summary_data}, status=status.HTTP_200_OK)


class WorkerViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows Workers to be viewed or edited.
    Managers can only see/edit workers in their own shops. Admins can see/edit all.
    """

    queryset = Worker.objects.all().order_by("first_name")
    serializer_class = WorkerSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return Worker.objects.all().order_by("first_name")
        elif user.is_authenticated:
            # Managers can only see workers in shops they manage
            managed_shops = Shop.objects.filter(managers=user)
            return Worker.objects.filter(shop__in=managed_shops).order_by("first_name")
        return Worker.objects.none()

    def get_permissions(self):
        """
        Instantiates and returns the list of permissions that this view requires.
        """
        if self.action in ["create"]:
            # Managers can create workers in their shops, Admins can create anywhere
            self.permission_classes = [
                permissions.IsAuthenticated,
                IsManagerOfShop | IsAdminUser,
            ]
        elif self.action in ["update", "partial_update", "destroy"]:
            # Managers can edit/delete workers in their shops, Admins can edit/delete anywhere
            self.permission_classes = [
                permissions.IsAuthenticated,
                IsManagerOfShop | IsAdminUser,
            ]
        elif self.action in ["list", "retrieve"]:
            # Authenticated users can list/retrieve workers they have access to via get_queryset
            self.permission_classes = [permissions.IsAuthenticated]
        else:
            # Default for other actions, if any, or fall through
            self.permission_classes = [permissions.IsAuthenticated]

        return [permission() for permission in self.permission_classes]


class CategoryViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows Product Categories to be viewed or edited.
    Admins can create/update/delete. All authenticated users can view.
    """

    queryset = Category.objects.all().order_by("name")
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            self.permission_classes = [IsAdminUser]
        elif self.action in ["list", "retrieve"]:
            self.permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in self.permission_classes]


class GlobalProductViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows Global Products to be viewed or edited.
    Only Admins can create/update/delete. All authenticated users can view.
    """

    queryset = GlobalProduct.objects.all().order_by("name")
    serializer_class = GlobalProductSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            self.permission_classes = [IsAdminUser]
        elif self.action in ["list", "retrieve", "search"]:  # Added 'search'
            self.permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in self.permission_classes]

    @action(detail=False, methods=["get"])
    def search(self, request):
        """
        Search global products by name or barcode.
        Query parameter: 'q'
        """
        query = request.query_params.get("q", "")
        if not query:
            return Response(
                {"detail": "Please provide a search query (q)."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Search by name (case-insensitive contains) or barcode (exact match)
        results = (
            self.get_queryset()
            .filter(Q(name__icontains=query) | Q(barcode__iexact=query))
            .distinct()
        )

        serializer = self.get_serializer(results, many=True)
        return Response(serializer.data)


class ProductViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows Shop-specific Products to be viewed or edited.
    Managers can only see/edit products in their own shops. Admins can see/edit all.
    """

    queryset = Product.objects.all().order_by("name")
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return Product.objects.all().order_by("name")
        elif user.is_authenticated:
            # Managers can only see products in shops they manage
            managed_shops = Shop.objects.filter(managers=user)
            return Product.objects.filter(shop__in=managed_shops).order_by("name")
        return Product.objects.none()

    def get_permissions(self):
        if self.action in ["create"]:
            self.permission_classes = [
                IsManagerOfShop | IsAdminUser
            ]  # Managers can create products in their shops
        elif self.action in ["update", "partial_update", "destroy"]:
            self.permission_classes = [
                IsManagerOfRelatedShop | IsAdminUser
            ]  # Managers can edit/delete products in their shops
        elif self.action in ["list", "retrieve", "search"]:  # Added 'search'
            self.permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in self.permission_classes]

    @action(detail=False, methods=["get"])
    def search(self, request):
        """
        Search products in the user's managed shops by name or barcode.
        Query parameter: 'q'
        """
        query = request.query_params.get("q", "")
        if not query:
            return Response(
                {"detail": "Please provide a search query (q)."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Filter products by the user's managed shops first
        queryset = self.get_queryset()

        # Search by name (case-insensitive contains) or barcode (exact match)
        results = queryset.filter(
            Q(name__icontains=query) | Q(barcode__iexact=query)
        ).distinct()

        serializer = self.get_serializer(results, many=True)
        return Response(serializer.data)


class StockEntryViewSet(
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.ListModelMixin,
    viewsets.GenericViewSet,
):
    """
    API endpoint that allows Stock Entries to be created, retrieved, or listed.
    Workers can create/list/retrieve for their shop. Managers can list/retrieve for their shops.
    """

    queryset = StockEntry.objects.all().order_by("-recorded_at")
    serializer_class = StockEntrySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return StockEntry.objects.all().order_by("-recorded_at")
        elif user.is_authenticated:
            # Workers can see their own stock entries and stock entries in their shop
            if hasattr(user, "worker"):
                return StockEntry.objects.filter(shop=user.worker.shop).order_by(
                    "-recorded_at"
                )
            # Managers can see stock entries in shops they manage
            managed_shops = Shop.objects.filter(managers=user)
            return StockEntry.objects.filter(shop__in=managed_shops).order_by(
                "-recorded_at"
            )
        return StockEntry.objects.none()

    def get_permissions(self):
        if self.action == "create":
            # Only workers can create stock entries
            self.permission_classes = [IsWorkerOfShop]
        elif self.action in ["list", "retrieve"]:
            # Workers can list/retrieve for their shop. Managers can list/retrieve for their shops.
            self.permission_classes = [IsWorkerOfShop | IsManagerOfShop]
        return [permission() for permission in self.permission_classes]


class SaleEntryViewSet(
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.ListModelMixin,
    viewsets.GenericViewSet,
):
    """
    API endpoint that allows Sale Entries to be created, retrieved, or listed.
    Workers can create/list/retrieve for their shop. Managers can list/retrieve for their shops.
    """

    queryset = SaleEntry.objects.all().order_by("-recorded_at")
    serializer_class = SaleEntrySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return SaleEntry.objects.all().order_by("-recorded_at")
        elif user.is_authenticated:
            # Workers can see their own sales entries and sales entries in their shop
            if hasattr(user, "worker"):
                return SaleEntry.objects.filter(shop=user.worker.shop).order_by(
                    "-recorded_at"
                )
            # Managers can see sales entries in shops they manage
            managed_shops = Shop.objects.filter(managers=user)
            return SaleEntry.objects.filter(shop__in=managed_shops).order_by(
                "-recorded_at"
            )
        return SaleEntry.objects.none()

    def get_permissions(self):
        if self.action == "create":
            # Only workers can create sale entries
            self.permission_classes = [IsWorkerOfShop]
        elif self.action in ["list", "retrieve"]:
            # Workers can list/retrieve for their shop. Managers can list/retrieve for their shops.
            self.permission_classes = [IsWorkerOfShop | IsManagerOfShop]
        return [permission() for permission in self.permission_classes]


class MissedSaleEntryViewSet(
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.ListModelMixin,
    viewsets.GenericViewSet,
):
    """
    API endpoint that allows Missed Sale Entries to be created, retrieved, or listed.
    Workers can create/list/retrieve for their shop. Managers can list/retrieve for their shops.
    """

    queryset = MissedSaleEntry.objects.all().order_by("-recorded_at")
    serializer_class = MissedSaleEntrySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return MissedSaleEntry.objects.all().order_by("-recorded_at")
        elif user.is_authenticated:
            # Workers can see their own missed sales entries and missed sales entries in their shop
            if hasattr(user, "worker"):
                return MissedSaleEntry.objects.filter(shop=user.worker.shop).order_by(
                    "-recorded_at"
                )
            # Managers can see missed sales entries in shops they manage
            managed_shops = Shop.objects.filter(managers=user)
            return MissedSaleEntry.objects.filter(shop__in=managed_shops).order_by(
                "-recorded_at"
            )
        return MissedSaleEntry.objects.none()

    def get_permissions(self):
        if self.action == "create":
            # Only workers can create missed sale entries
            self.permission_classes = [IsWorkerOfShop]
        elif self.action in ["list", "retrieve"]:
            # Workers can list/retrieve for their shop. Managers can list/retrieve for their shops.
            self.permission_classes = [IsWorkerOfShop | IsManagerOfShop]
        return [permission() for permission in self.permission_classes]

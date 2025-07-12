# dukani/backend/api/permissions.py

from rest_framework import permissions
from django.core.exceptions import PermissionDenied
from api.models import Shop, Worker # Import necessary models

class IsManagerOfShop(permissions.BasePermission):
    """
    Custom permission to only allow managers of a shop to access/modify
    objects related to that shop.
    - For list/retrieve (has_permission): Allows if user is authenticated and manages the shop (or is superuser).
    - For create (has_permission): Checks if the 'shop' ID in request.data is managed by the user (or is superuser).
    - For update/delete/retrieve (has_object_permission): Checks if the object's associated shop is managed by the user (or is superuser).
    """

    def has_permission(self, request, view):
        user = request.user

        # Superusers always have full permission
        if user.is_superuser:
            return True

        # Deny unauthenticated users for all actions by default, unless explicitly allowed by other permissions
        if not user.is_authenticated:
            return False

        # For SAFE_METHODS (GET, HEAD, OPTIONS), allow if authenticated, object-level will refine
        if request.method in permissions.SAFE_METHODS:
            return True

        # For write operations (POST, PUT, PATCH, DELETE)
        if view.action == 'create':
            shop_id = request.data.get('shop')
            if not shop_id:
                # If shop ID is missing, let serializer validation handle it as a Bad Request.
                # For permission, we cannot grant if we don't know the shop.
                return False 
            try:
                shop = Shop.objects.get(id=shop_id)
                # Check if the requesting user manages this shop
                if not shop.managers.filter(id=user.id).exists():
                    # Explicitly raise PermissionDenied if user does not manage the shop for create action
                    raise PermissionDenied("You do not have permission to add workers to this shop.")
                return True # User manages the shop, grant permission for create
            except Shop.DoesNotExist:
                # If shop does not exist, this is a validation error.
                # For permission, we deny access as the target shop is invalid.
                return False 
        
        # For other write actions (update, destroy), has_object_permission will be called.
        return True # Defer to has_object_permission for object-level checks

    def has_object_permission(self, request, view, obj):
        user = request.user

        # Superusers always have full permission
        if user.is_superuser:
            return True

        # Check if the object has a 'shop' attribute
        if hasattr(obj, 'shop'):
            # Check if the requesting user manages the shop associated with the object
            return user.managed_shops.filter(id=obj.shop.id).exists()
        
        # If the object does not have a 'shop' attribute, this permission might not apply
        # or it might indicate an attempt to access an unrelated object.
        return False

class IsWorkerOfShop(permissions.BasePermission):
    """
    Custom permission to only allow workers of a specific shop to create/access entries
    related to their shop.
    Assumes the request data or URL kwargs will contain 'shop_id' or 'worker_id'.
    """
    def has_permission(self, request, view):
        # Allow GET, HEAD, OPTIONS for authenticated users generally
        if request.method in permissions.SAFE_METHODS:
            return request.user and request.user.is_authenticated

        # For POST (create), check if the requesting user is a worker and belongs to the specified shop
        if request.method == 'POST':
            if not request.user or not request.user.is_authenticated:
                return False

            # Check if the user has a linked Worker profile
            if not hasattr(request.user, 'worker'):
                return False

            # Check if the shop ID in the request data matches the worker's shop
            requested_shop_id = request.data.get('shop')
            if not requested_shop_id:
                # If shop ID is not provided in data, it's an invalid request for this permission
                return False

            return str(request.user.worker.shop.id) == requested_shop_id
        return False # Deny other methods by default

    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed for workers of the same shop
        if request.method in permissions.SAFE_METHODS:
            if request.user.is_superuser:
                return True
            return hasattr(request.user, 'worker') and request.user.worker.shop == obj.shop

        # Write permissions are typically not allowed for workers on entries they didn't create
        # or for modifying existing entries. This permission is primarily for creation.
        return False


class IsAdminOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow administrators to edit it.
    Authenticated users can view.
    """
    def has_permission(self, request, view):
        # Read permissions are allowed to any authenticated request.
        if request.method in permissions.SAFE_METHODS:
            return request.user and request.user.is_authenticated

        # Write permissions are only allowed to admin users.
        return request.user and request.user.is_superuser

class IsManagerOrAdmin(permissions.BasePermission):
    """
    Custom permission to allow managers OR administrators to perform write actions.
    """
    def has_permission(self, request, view):
        if request.user and request.user.is_authenticated:
            if request.user.is_superuser:
                return True
            # Check if the user is a manager of *any* shop.
            # This is a broad check for creating new shops/workers.
            # For object-level permissions, more specific checks are needed.
            return request.user.managed_shops.exists()
        return False

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser:
            return True
        if hasattr(obj, 'shop') and request.user in obj.shop.managers.all():
            return True
        return False


class IsAdminUser(permissions.BasePermission):
    """
    Custom permission to only allow admin users to access.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_superuser

    def has_object_permission(self, request, view, obj):
        return request.user and request.user.is_superuser


class IsWorkerOfRelatedShop(permissions.BasePermission):
    """
    Custom permission to allow a worker to access an object if it belongs to their shop.
    Used for objects like Product, StockEntry, SaleEntry, MissedSaleEntry.
    """
    def has_permission(self, request, view):
        # This permission is for object-level checks, so has_permission usually returns True
        # if the user is authenticated. The actual check happens in has_object_permission.
        return request.user and request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser:
            return True
        if hasattr(request.user, 'worker') and hasattr(obj, 'shop'):
            return request.user.worker.shop == obj.shop
        return False


class IsManagerOfRelatedShop(permissions.BasePermission):
    """
    Custom permission to allow a manager to access an object if it belongs to a shop they manage.
    Used for objects like Product, Worker.
    """
    def has_permission(self, request, view):
        # This permission is for object-level checks, so has_permission usually returns True
        # if the user is authenticated. The actual check happens in has_object_permission.
        return request.user and request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser:
            return True
        if hasattr(obj, 'shop') and request.user in obj.shop.managers.all():
            return True
        return False


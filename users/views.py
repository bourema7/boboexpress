from django.contrib.auth.models import User
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response



from .models import Address, UserProfile
from .serializers import (
    AddressSerializer,
    RegisterSerializer,
    UserListSerializer,
    UserProfileSerializer,
)





class RegisterView(generics.CreateAPIView):
    """POST /api/auth/register/ — Inscription d'un nouvel utilisateur."""
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response({
            'detail': 'Compte créé avec succès.',
            'username': user.username,
            'email': user.email,
        }, status=status.HTTP_201_CREATED)


class MyProfileView(generics.RetrieveUpdateAPIView):
    """GET/PATCH /api/users/me/ — Profil de l'utilisateur connecté."""
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        user = self.request.user
        profile, _ = UserProfile.objects.get_or_create(
            user=user,
            defaults={
                'role': 'admin' if user.is_staff or user.is_superuser else 'customer',
                'is_verified': user.is_staff or user.is_superuser,
                'accepted_terms': True,
            },
        )
        if (user.is_staff or user.is_superuser) and (profile.role != 'admin' or not profile.is_verified):
            profile.role = 'admin'
            profile.is_verified = True
            profile.save(update_fields=['role', 'is_verified'])
        return profile


class AddressViewSet(viewsets.ModelViewSet):
    """CRUD /api/users/addresses/ — Adresses de livraison."""
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Address.objects.filter(user=self.request.user).order_by('-is_primary', '-created_at')

    @action(detail=True, methods=['post'])
    def set_primary(self, request, pk=None):
        """Définir une adresse comme principale."""
        address = self.get_object()
        Address.objects.filter(user=request.user).update(is_primary=False)
        address.is_primary = True
        address.save()
        return Response({'detail': 'Adresse définie comme principale.'})


from rest_framework.permissions import BasePermission

class IsAdminRole(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_staff:
            return True
        profile = getattr(request.user, 'profile', None)
        return profile and profile.role == 'admin'

class UserAdminViewSet(viewsets.ModelViewSet):
    """Admin: liste et gestion des utilisateurs."""
    queryset = UserProfile.objects.select_related('user').all().order_by('-created_at')
    serializer_class = UserListSerializer
    permission_classes = [IsAdminRole]

    def get_queryset(self):
        qs = super().get_queryset()
        role = self.request.query_params.get('role')
        if role:
            qs = qs.filter(role=role)
        search = self.request.query_params.get('search')
        if search:
            qs = qs.filter(user__username__icontains=search) | qs.filter(user__email__icontains=search)
        return qs

    def perform_update(self, serializer):
        # Les administrateurs peuvent mettre à jour les rôles
        role = self.request.data.get('role')
        if role:
            serializer.save(role=role)
        else:
            serializer.save()

    @action(detail=True, methods=['post'])
    def block(self, request, pk=None):
        """Bloquer un utilisateur."""
        profile = self.get_object()
        profile.is_blocked = True
        profile.user.is_active = False
        profile.user.save()
        profile.save()
        return Response({'detail': f'Utilisateur {profile.user.username} bloqué.'})

    @action(detail=True, methods=['post'])
    def unblock(self, request, pk=None):
        """Débloquer un utilisateur."""
        profile = self.get_object()
        profile.is_blocked = False
        profile.user.is_active = True
        profile.user.save()
        profile.save()
        return Response({'detail': f'Utilisateur {profile.user.username} débloqué.'})

    @action(detail=True, methods=['post'])
    def verify(self, request, pk=None):
        """Vérifier (approuver) un commerçant ou livreur."""
        profile = self.get_object()
        profile.is_verified = True
        profile.save()
        return Response({'detail': f'Utilisateur {profile.user.username} vérifié.'})

    @action(detail=True, methods=['post'])
    def update_location(self, request, pk=None):
        """Livreur: mise à jour position GPS."""
        profile = self.get_object()
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        if lat is None or lng is None:
            return Response({'detail': 'latitude et longitude requis.'}, status=status.HTTP_400_BAD_REQUEST)
        profile.current_lat = lat
        profile.current_lng = lng
        profile.save(update_fields=['current_lat', 'current_lng'])
        return Response({'detail': 'Position mise à jour.'})


class DriverLocationUpdateView(generics.UpdateAPIView):
    """PATCH /api/users/driver/location/ — Livreur met à jour sa position GPS."""
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        profile = getattr(request.user, 'profile', None)
        if not profile or profile.role != 'delivery':
            return Response({'detail': 'Réservé aux livreurs.'}, status=status.HTTP_403_FORBIDDEN)
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        available = request.data.get('is_available')
        try:
            if lat is not None:
                profile.current_lat = lat
            if lng is not None:
                profile.current_lng = lng
            if available is not None:
                profile.is_available = available
            profile.save(update_fields=['current_lat', 'current_lng', 'is_available'])
            return Response({'detail': 'Position mise à jour.', 'latitude': str(profile.current_lat), 'longitude': str(profile.current_lng)})
        except Exception as e:
            raise e

class AvailableDriversView(generics.ListAPIView):
    """GET /api/users/available-drivers/ — Liste des livreurs disponibles."""
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # On affiche tous les livreurs non bloqués pour le moment pour faciliter les tests
        return UserProfile.objects.filter(
            role='delivery', 
            is_blocked=False
        ).order_by('-created_at')


class ChangePasswordView(generics.UpdateAPIView):
    """PATCH /api/users/change-password/ — Changer son mot de passe."""
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        user = request.user
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')
        if not old_password or not new_password:
            return Response({'detail': 'Ancien et nouveau mot de passe requis.'}, status=status.HTTP_400_BAD_REQUEST)
        if not user.check_password(old_password):
            return Response({'detail': 'Ancien mot de passe incorrect.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            from django.contrib.auth.password_validation import validate_password
            validate_password(new_password, user)
        except Exception as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        user.set_password(new_password)
        user.save()
        return Response({'detail': 'Mot de passe modifié avec succès.'})

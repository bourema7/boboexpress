import uuid

from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.utils.text import slugify
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework import serializers

from .models import Address, UserProfile


class RegisterSerializer(serializers.ModelSerializer):
    """Inscription d'un nouvel utilisateur avec création du profil."""
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True, label='Confirmer le mot de passe')
    role = serializers.ChoiceField(choices=UserProfile.ROLE_CHOICES, default='customer')
    phone = serializers.CharField(max_length=30, required=False, allow_blank=True)
    city = serializers.CharField(max_length=120, required=False, allow_blank=True)
    company_name = serializers.CharField(max_length=200, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'first_name', 'last_name', 'password', 'password2', 'role', 'phone', 'city', 'company_name']

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({'password': 'Les mots de passe ne correspondent pas.'})
        if User.objects.filter(email=attrs['email']).exists():
            raise serializers.ValidationError({'email': 'Cet email est déjà utilisé.'})
        
        # Sécurité : Interdire le rôle admin via l'inscription publique
        if attrs.get('role') == 'admin':
            raise serializers.ValidationError({'role': 'Action non autorisée.'})
            
        return attrs

    def create(self, validated_data):
        role = validated_data.pop('role', 'customer')
        phone = validated_data.pop('phone', '')
        city = validated_data.pop('city', '')
        company_name = validated_data.pop('company_name', '')
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        profile = UserProfile.objects.create(
            user=user,
            role=role,
            phone=phone,
            city=city,
            company_name=company_name,
            accepted_terms=True,
        )
        if role == 'seller':
            from stores.models import Store

            store_name = company_name or f'Boutique {user.username}'
            Store.objects.create(
                owner=profile,
                name=store_name,
                slug=f'{slugify(store_name) or "boutique"}-{uuid.uuid4().hex[:6]}',
                city=city or 'Bobo-Dioulasso',
                phone=phone,
                is_active=True,
                is_approved=True,
            )
        return user


class EmailOrUsernameTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Allow login with either username or email."""

    def validate(self, attrs):
        username = attrs.get(self.username_field, '').strip()
        if '@' in username:
            user = User.objects.filter(email__iexact=username).first()
            if user:
                attrs[self.username_field] = user.get_username()
        return super().validate(attrs)


class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email')
    first_name = serializers.CharField(source='user.first_name', required=False, allow_blank=True)
    last_name = serializers.CharField(source='user.last_name', required=False, allow_blank=True)
    is_staff = serializers.BooleanField(source='user.is_staff', read_only=True)
    is_superuser = serializers.BooleanField(source='user.is_superuser', read_only=True)

    class Meta:
        model = UserProfile
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'is_staff', 'is_superuser',
            'role', 'phone', 'city', 'company_name',
            'wallet_balance', 'is_verified', 'is_blocked',
            'rating', 'total_deliveries', 'is_available',
            'profile_image', 'created_at',
        ]
        read_only_fields = ['id', 'wallet_balance', 'is_verified', 'is_blocked', 'role', 'rating', 'total_deliveries', 'created_at']

    def update(self, instance, validated_data):
        user_data = validated_data.pop('user', {})
        if 'email' in user_data:
            new_email = user_data['email']
            if User.objects.filter(email=new_email).exclude(pk=instance.user.pk).exists():
                raise serializers.ValidationError({'email': 'Cet email est déjà utilisé par un autre compte.'})
            instance.user.email = new_email
        if 'first_name' in user_data:
            instance.user.first_name = user_data['first_name']
        if 'last_name' in user_data:
            instance.user.last_name = user_data['last_name']
        instance.user.save()
        return super().update(instance, validated_data)


class UserListSerializer(serializers.ModelSerializer):
    """Sérialiseur léger pour listes (admin)."""
    username = serializers.CharField(source='user.username')
    email = serializers.CharField(source='user.email')
    full_name = serializers.SerializerMethodField()
    is_active = serializers.BooleanField(source='user.is_active')

    class Meta:
        model = UserProfile
        fields = ['id', 'username', 'email', 'full_name', 'role', 'phone', 'city', 'is_verified', 'is_blocked', 'is_active', 'created_at']

    def get_full_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username

    def update(self, instance, validated_data, **kwargs):
        try:
            # On fusionne kwargs (comme le rôle) dans validated_data
            validated_data.update(kwargs)
            
            # Récupération sécurisée des données utilisateur
            user_data = validated_data.pop('user', {})
            user = instance.user
            
            # Mise à jour email et username directement sur l'objet User
            # On vérifie dans validated_data ET user_data pour être sûr
            new_username = user_data.get('username') or validated_data.pop('username', None)
            if new_username:
                user.username = new_username
                
            new_email = user_data.get('email') or validated_data.pop('email', None)
            if new_email:
                user.email = new_email
                
            new_is_active = user_data.get('is_active') or validated_data.pop('is_active', None)
            if new_is_active is not None:
                user.is_active = new_is_active
                
            # Sauvegarde du modèle User
            user.save()
            
            # Sauvegarde du modèle UserProfile (role, phone, etc.) via le parent
            return super().update(instance, validated_data)
            
        except Exception as e:
            error_msg = str(e)
            if "UNIQUE constraint failed" in error_msg or "Duplicate entry" in error_msg:
                error_msg = "Cet email ou nom d'utilisateur est déjà utilisé."
            raise serializers.ValidationError({'detail': f"Erreur interne : {error_msg}"})

class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = ['id', 'label', 'type', 'street', 'city', 'landmark', 'latitude', 'longitude', 'is_primary', 'created_at']
        read_only_fields = ['id', 'created_at']

    def create(self, validated_data):
        user = self.context['request'].user
        # Si is_primary, désactiver les autres
        if validated_data.get('is_primary', False):
            Address.objects.filter(user=user).update(is_primary=False)
        return Address.objects.create(user=user, **validated_data)

    def update(self, instance, validated_data):
        if validated_data.get('is_primary', False):
            Address.objects.filter(user=instance.user).exclude(pk=instance.pk).update(is_primary=False)
        return super().update(instance, validated_data)

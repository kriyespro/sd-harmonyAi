from rest_framework import serializers
from users.models import User, Profile
from relationships.models import Relationship, Event, ConflictEntry
from moods.models import MoodEntry, ConnectionScore


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'date_joined']
        read_only_fields = ['id', 'date_joined']


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ['email', 'first_name', 'last_name', 'password']

    def create(self, validated_data):
        from users.services import create_user
        return create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            last_name=validated_data.get('last_name', ''),
        )


class ProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Profile
        fields = ['user', 'timezone', 'bio', 'is_premium', 'avatar']
        read_only_fields = ['is_premium']


class RelationshipSerializer(serializers.ModelSerializer):
    creator = UserSerializer(read_only=True)
    partner = UserSerializer(read_only=True)
    invite_link = serializers.SerializerMethodField()

    class Meta:
        model = Relationship
        fields = [
            'id', 'creator', 'partner', 'relationship_type',
            'status', 'invite_token', 'invite_link', 'created_at',
        ]
        read_only_fields = ['id', 'creator', 'partner', 'status', 'invite_token', 'created_at']

    def get_invite_link(self, obj):
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(f'/relationships/accept/{obj.invite_token}/')
        return f'/relationships/accept/{obj.invite_token}/'


class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ['id', 'relationship', 'event_type', 'title', 'date', 'notes', 'is_recurring', 'created_at']
        read_only_fields = ['id', 'relationship', 'created_at']


class ConflictSerializer(serializers.ModelSerializer):
    class Meta:
        model = ConflictEntry
        fields = [
            'id', 'relationship', 'category', 'description',
            'severity', 'resolved', 'resolution_note', 'created_at',
        ]
        read_only_fields = ['id', 'relationship', 'created_at']


class MoodEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = MoodEntry
        fields = ['id', 'relationship', 'mood', 'note', 'date', 'created_at']
        read_only_fields = ['id', 'relationship', 'date', 'created_at']


class ConnectionScoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = ConnectionScore
        fields = ['id', 'relationship', 'score', 'date', 'created_at']
        read_only_fields = ['id', 'relationship', 'date', 'created_at']


class HealthScoreSerializer(serializers.Serializer):
    overall = serializers.IntegerField()
    mood_score = serializers.IntegerField()
    connection_score = serializers.IntegerField()
    conflict_score = serializers.IntegerField()
    label = serializers.CharField()
    color = serializers.CharField()

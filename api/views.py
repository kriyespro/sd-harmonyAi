from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.db.models import Q
from django.shortcuts import get_object_or_404

from users.models import User, Profile
from relationships.models import Relationship, Event, ConflictEntry
from relationships import services as rel_services
from moods import services as mood_services
from moods.models import MoodEntry, ConnectionScore
from billing import services as billing_services
from .serializers import (
    UserSerializer, RegisterSerializer, ProfileSerializer,
    RelationshipSerializer, EventSerializer, ConflictSerializer,
    MoodEntrySerializer, ConnectionScoreSerializer, HealthScoreSerializer,
)


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'user': UserSerializer(user).data,
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        from rest_framework_simplejwt.tokens import RefreshToken
        from django.contrib.auth import authenticate
        email = request.data.get('email', '')
        password = request.data.get('password', '')
        user = authenticate(request, username=email, password=password)
        if user is None:
            return Response({'detail': 'Invalid credentials'}, status=400)
        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UserSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        })


class ProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ProfileSerializer

    def get_object(self):
        profile, _ = Profile.objects.get_or_create(user=self.request.user)
        return profile


class RelationshipListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = RelationshipSerializer

    def get_queryset(self):
        return rel_services.get_user_relationships(self.request.user)

    def create(self, request, *args, **kwargs):
        rel = rel_services.create_relationship(
            user=request.user,
            relationship_type=request.data.get('relationship_type', 'couple'),
        )
        serializer = self.get_serializer(rel, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class RelationshipDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = RelationshipSerializer

    def get_queryset(self):
        user = self.request.user
        return Relationship.objects.filter(Q(creator=user) | Q(partner=user))


class AcceptInviteAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, token):
        rel = get_object_or_404(Relationship, invite_token=token, status=Relationship.STATUS_PENDING)
        if rel.creator == request.user:
            return Response({'error': 'Cannot accept your own invite'}, status=400)
        rel_services.accept_invite(rel, request.user)
        return Response(RelationshipSerializer(rel, context={'request': request}).data)


class HealthScoreView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        rel = get_object_or_404(Relationship, pk=pk)
        if rel.creator != request.user and rel.partner != request.user:
            return Response({'error': 'Not authorized'}, status=403)
        score = rel_services.calculate_health_score(rel)
        return Response(score)


class EventListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = EventSerializer

    def get_queryset(self):
        return Event.objects.filter(relationship__pk=self.kwargs['rel_pk'])

    def perform_create(self, serializer):
        rel = get_object_or_404(Relationship, pk=self.kwargs['rel_pk'])
        serializer.save(relationship=rel, created_by=self.request.user)


class ConflictListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ConflictSerializer

    def get_queryset(self):
        return ConflictEntry.objects.filter(relationship__pk=self.kwargs['rel_pk'])

    def perform_create(self, serializer):
        rel = get_object_or_404(Relationship, pk=self.kwargs['rel_pk'])
        serializer.save(relationship=rel, logged_by=self.request.user)


class MoodCheckInView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, rel_pk):
        rel = get_object_or_404(Relationship, pk=rel_pk)
        mood = request.data.get('mood')
        note = request.data.get('note', '')
        if not mood:
            return Response({'error': 'mood required'}, status=400)
        entry, created = mood_services.log_mood(request.user, rel, mood, note)
        return Response(MoodEntrySerializer(entry).data, status=201 if created else 200)


class ConnectionScoreView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, rel_pk):
        rel = get_object_or_404(Relationship, pk=rel_pk)
        score = request.data.get('score')
        if not score:
            return Response({'error': 'score required'}, status=400)
        entry, created = mood_services.log_connection_score(request.user, rel, score)
        return Response(ConnectionScoreSerializer(entry).data, status=201 if created else 200)


class MoodHistoryView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = MoodEntrySerializer

    def get_queryset(self):
        return MoodEntry.objects.filter(
            user=self.request.user,
            relationship__pk=self.kwargs['rel_pk'],
        ).order_by('-date')[:30]


def _limit_error(feature, used, limit):
    return Response({
        'error': 'limit_reached',
        'feature': feature,
        'used': used,
        'limit': limit,
        'message': f'Free plan: {limit} {feature} analyses/month. Upgrade to Premium for unlimited.',
    }, status=402)


class AIConflictAnalyzeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, rel_pk):
        allowed, used, limit = billing_services.check_ai_limit(request.user, 'analyze')
        if not allowed:
            return _limit_error('analyze', used, limit)

        from ai_engine import services as ai_services
        from ai_engine.models import AIInsight
        import json as _json

        rel = get_object_or_404(
            Relationship,
            Q(creator=request.user) | Q(partner=request.user),
            pk=rel_pk,
        )
        conflict_id = request.data.get('conflict_id')
        conflict = get_object_or_404(ConflictEntry, pk=conflict_id, relationship=rel)

        result = ai_services.analyze_conflict(conflict)
        AIInsight.objects.create(
            relationship=rel,
            requested_by=request.user,
            insight_type=AIInsight.TYPE_CONFLICT,
            input_summary=f'{conflict.category}: {conflict.description[:200]}',
            content=_json.dumps(result),
        )
        billing_services.increment_usage(request.user, 'analyze')
        return Response(result)


class AIPatternDetectView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, rel_pk):
        allowed, used, limit = billing_services.check_ai_limit(request.user, 'pattern')
        if not allowed:
            return _limit_error('pattern', used, limit)

        from ai_engine import services as ai_services
        from ai_engine.models import AIInsight
        import json as _json

        rel = get_object_or_404(
            Relationship,
            Q(creator=request.user) | Q(partner=request.user),
            pk=rel_pk,
        )
        result = ai_services.detect_patterns(rel, request.user)
        AIInsight.objects.create(
            relationship=rel,
            requested_by=request.user,
            insight_type=AIInsight.TYPE_PATTERN,
            content=_json.dumps(result),
        )
        billing_services.increment_usage(request.user, 'pattern')
        return Response(result)


class AIWeeklyReportView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, rel_pk):
        from ai_engine.models import AIInsight
        import json as _json

        rel = get_object_or_404(
            Relationship,
            Q(creator=request.user) | Q(partner=request.user),
            pk=rel_pk,
        )
        last = AIInsight.objects.filter(relationship=rel, insight_type=AIInsight.TYPE_WEEKLY).first()
        if last:
            return Response({'report': _json.loads(last.content), 'generated_at': last.created_at})
        return Response({'report': None}, status=404)

    def post(self, request, rel_pk):
        allowed, used, limit = billing_services.check_ai_limit(request.user, 'report')
        if not allowed:
            return _limit_error('report', used, limit)

        from ai_engine import services as ai_services
        from ai_engine.models import AIInsight
        import json as _json

        rel = get_object_or_404(
            Relationship,
            Q(creator=request.user) | Q(partner=request.user),
            pk=rel_pk,
        )
        result = ai_services.generate_weekly_report(rel, request.user)
        AIInsight.objects.create(
            relationship=rel,
            requested_by=request.user,
            insight_type=AIInsight.TYPE_WEEKLY,
            content=_json.dumps(result),
        )
        billing_services.increment_usage(request.user, 'report')
        return Response(result)


class AICoachChatView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, rel_pk):
        from ai_engine.models import ChatMessage

        rel = get_object_or_404(
            Relationship,
            Q(creator=request.user) | Q(partner=request.user),
            pk=rel_pk,
        )
        history = ChatMessage.objects.filter(relationship=rel, user=request.user).order_by('created_at')
        return Response([{'role': m.role, 'content': m.content, 'created_at': m.created_at} for m in history])

    def post(self, request, rel_pk):
        allowed, used, limit = billing_services.check_ai_limit(request.user, 'coach')
        if not allowed:
            return _limit_error('coach', used, limit)

        from ai_engine import services as ai_services
        from ai_engine.models import ChatMessage

        rel = get_object_or_404(
            Relationship,
            Q(creator=request.user) | Q(partner=request.user),
            pk=rel_pk,
        )
        message = request.data.get('message', '').strip()
        if not message:
            return Response({'error': 'message required'}, status=400)

        ChatMessage.objects.create(relationship=rel, user=request.user, role=ChatMessage.ROLE_USER, content=message)

        history_qs = ChatMessage.objects.filter(relationship=rel, user=request.user).order_by('-created_at')[:16]
        history = [{'role': m.role, 'content': m.content} for m in reversed(list(history_qs))]

        reply = ai_services.chat_with_coach(rel, request.user, message, history=history[:-1])
        ChatMessage.objects.create(relationship=rel, user=request.user, role=ChatMessage.ROLE_ASSISTANT, content=reply)

        billing_services.increment_usage(request.user, 'coach')
        return Response({'reply': reply})

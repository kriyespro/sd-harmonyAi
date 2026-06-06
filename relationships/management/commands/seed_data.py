"""
python3 manage.py seed_data

Seeds rich demo data for HarmonyAI:
- 2 users (test + test2)
- 1 active couple relationship
- 14 days of mood + connection scores
- 4 conflict entries (mix resolved/open)
- 6 upcoming events
"""
from datetime import date, timedelta
import random
from django.core.management.base import BaseCommand
from django.utils import timezone

from users.models import User, Profile
from relationships.models import Relationship, Event, ConflictEntry
from moods.models import MoodEntry, ConnectionScore


MOODS = ['happy', 'neutral', 'sad', 'angry', 'stressed']
MOOD_WEIGHTS = [0.45, 0.25, 0.12, 0.08, 0.10]


class Command(BaseCommand):
    help = 'Seed rich demo data for HarmonyAI'

    def add_arguments(self, parser):
        parser.add_argument('--reset', action='store_true', help='Delete existing data first')

    def handle(self, *args, **options):
        if options['reset']:
            self.stdout.write('Resetting data...')
            MoodEntry.objects.all().delete()
            ConnectionScore.objects.all().delete()
            ConflictEntry.objects.all().delete()
            Event.objects.all().delete()
            Relationship.objects.all().delete()

        # ── Users ──────────────────────────────────────────────────────────
        user1, _ = User.objects.get_or_create(
            email='test@harmonyai.com',
            defaults={'first_name': 'Sunil', 'last_name': 'Verma', 'is_active': True},
        )
        user1.set_password('test1234')
        user1.save()
        Profile.objects.get_or_create(user=user1, defaults={'timezone': 'Asia/Kolkata', 'bio': 'HarmonyAI test user'})

        user2, _ = User.objects.get_or_create(
            email='priya@harmonyai.com',
            defaults={'first_name': 'Priya', 'last_name': 'Sharma', 'is_active': True},
        )
        user2.set_password('test1234')
        user2.save()
        Profile.objects.get_or_create(user=user2, defaults={'timezone': 'Asia/Kolkata', 'bio': 'Priya — partner'})

        user3, _ = User.objects.get_or_create(
            email='ravi@harmonyai.com',
            defaults={'first_name': 'Ravi', 'last_name': 'Verma', 'is_active': True},
        )
        user3.set_password('test1234')
        user3.save()
        Profile.objects.get_or_create(user=user3, defaults={'timezone': 'Asia/Kolkata', 'bio': 'Ravi — brother'})

        self.stdout.write(self.style.SUCCESS('✓ Users created'))

        # ── Relationships ──────────────────────────────────────────────────
        couple, _ = Relationship.objects.get_or_create(
            creator=user1,
            partner=user2,
            defaults={'relationship_type': 'couple', 'status': 'active'},
        )

        family, _ = Relationship.objects.get_or_create(
            creator=user1,
            partner=user3,
            defaults={'relationship_type': 'parent_child', 'status': 'active'},
        )

        self.stdout.write(self.style.SUCCESS('✓ Relationships created'))

        # ── Mood + Connection scores (last 14 days) ─────────────────────────
        today = date.today()
        # Clear old mood data so we can seed fresh (avoids unique constraint)
        MoodEntry.objects.filter(user__in=[user1, user2], relationship=couple).delete()
        ConnectionScore.objects.filter(user__in=[user1, user2], relationship=couple).delete()

        random.seed(42)
        now_str = timezone.now().strftime('%Y-%m-%d %H:%M:%S')

        from django.db import connection as db_conn
        with db_conn.cursor() as cursor:
            for delta in range(14, 0, -1):
                day = (today - timedelta(days=delta)).strftime('%Y-%m-%d')
                for usr in [user1, user2]:
                    mood = random.choices(MOODS, MOOD_WEIGHTS)[0]
                    notes = {
                        'happy': 'Had a great day together!',
                        'neutral': 'Normal day, nothing special.',
                        'sad': 'Feeling a bit distant today.',
                        'angry': 'We had a small argument.',
                        'stressed': 'Work stress carrying over.',
                    }.get(mood, '')
                    score = random.randint(6, 10) if mood in ['happy', 'neutral'] else random.randint(3, 7)
                    cursor.execute(
                        'INSERT INTO moods_moodentry (user_id, relationship_id, date, mood, note, created_at) VALUES (%s,%s,%s,%s,%s,%s)',
                        [usr.id, couple.id, day, mood, notes, now_str],
                    )
                    cursor.execute(
                        'INSERT INTO moods_connectionscore (user_id, relationship_id, date, score, created_at) VALUES (%s,%s,%s,%s,%s)',
                        [usr.id, couple.id, day, score, now_str],
                    )
            # Today entry for user1
            cursor.execute(
                'INSERT INTO moods_moodentry (user_id, relationship_id, date, mood, note, created_at) VALUES (%s,%s,%s,%s,%s,%s)',
                [user1.id, couple.id, today.strftime('%Y-%m-%d'), 'happy', 'Really good day, feeling connected.', now_str],
            )
            cursor.execute(
                'INSERT INTO moods_connectionscore (user_id, relationship_id, date, score, created_at) VALUES (%s,%s,%s,%s,%s)',
                [user1.id, couple.id, today.strftime('%Y-%m-%d'), 8, now_str],
            )

        self.stdout.write(self.style.SUCCESS('✓ Mood + connection data seeded'))

        # ── Events ─────────────────────────────────────────────────────────
        events = [
            (couple, user1, 'birthday', "Priya's Birthday 🎂", today + timedelta(days=4), False),
            (couple, user1, 'anniversary', "Our 2nd Anniversary 💍", today + timedelta(days=18), True),
            (couple, user1, 'promise', "Trip to Goa ✈️ Promise", today + timedelta(days=35), False),
            (couple, user1, 'vacation', "Coorg Getaway", today + timedelta(days=52), False),
            (family, user1, 'birthday', "Ravi's Birthday 🎂", today + timedelta(days=12), True),
            (family, user1, 'family', "Family Reunion Dinner", today + timedelta(days=8), False),
        ]
        for rel, by, etype, title, edate, recurring in events:
            Event.objects.get_or_create(
                relationship=rel,
                title=title,
                defaults={'created_by': by, 'event_type': etype, 'date': edate, 'is_recurring': recurring},
            )

        self.stdout.write(self.style.SUCCESS('✓ Events seeded'))

        # ── Conflicts ──────────────────────────────────────────────────────
        conflicts = [
            (couple, user1, 'communication', "Didn't respond to messages for a few hours, felt ignored.", 2, True,
             "Talked it out. We agreed to respond within 1 hour during work hours."),
            (couple, user2, 'time', "Date night cancelled again due to work. Third time this month.", 3, True,
             "Set a recurring date every Sunday. Work stops at 7pm."),
            (couple, user1, 'money', "Disagreement over vacation budget. I wanted to splurge, she wanted to save.", 3, False, ''),
            (couple, user1, 'trust', "Got upset about late-night work calls with colleague.", 4, False, ''),
        ]
        for rel, by, cat, desc, severity, resolved, note in conflicts:
            ConflictEntry.objects.get_or_create(
                relationship=rel,
                description=desc[:50],
                defaults={
                    'logged_by': by, 'category': cat,
                    'description': desc, 'severity': severity,
                    'resolved': resolved, 'resolution_note': note,
                },
            )

        self.stdout.write(self.style.SUCCESS('✓ Conflicts seeded'))

        self.stdout.write(self.style.SUCCESS(
            '\n🎉 Seed complete!\n'
            '  test@harmonyai.com / test1234\n'
            '  priya@harmonyai.com / test1234\n'
            '  ravi@harmonyai.com  / test1234\n'
        ))

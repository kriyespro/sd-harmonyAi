# HarmonyAI — Project Goal & Development Plan

## Project Summary

**HarmonyAI** is an AI-powered relationship intelligence platform.  
Not a chatbot. Not a therapist. A **conflict prevention system**.

Core insight: relationships fail from many small unresolved events, not one big event.  
HarmonyAI detects behavioral signals early and recommends small actions before trust erodes.

**Positioning:** _"Prevent relationship problems before they become relationship crises."_

**Stack:** Django 5 · PostgreSQL · Redis · Celery · Tailwind CSS · Alpine.js · Claude API

---

## Phase 1 — MVP (Couples)

### Milestone 1: Foundation
- [ ] Django project setup (auth, user model, PostgreSQL)
- [ ] User registration / login / password reset
- [ ] Profile model (name, avatar, timezone)

### Milestone 2: Relationship Space
- [ ] `Relationship` model (type: couple / parent-child / friends)
- [ ] Invite partner via email + shareable link
- [ ] Accept/decline invite flow
- [ ] Relationship dashboard (both users linked)

### Milestone 3: Daily Data Collection
- [ ] Mood check-in model (5 moods + optional note + timestamp)
- [ ] Relationship connection score (1–10 daily)
- [ ] Event tracker (birthday, anniversary, promise, travel — tap to log)
- [ ] Conflict journal (category + description + severity + resolution status)

### Milestone 4: AI Engine (Claude API)
- [ ] Conflict analyzer: user submits conflict → AI returns root causes + suggested actions
- [ ] Pattern detector: scan last 30 days of mood/conflict/check-in data → flag trends
- [ ] AI relationship coach: chat interface for advice
- [ ] Safety rule: AI outputs observations only, never accusations

### Milestone 5: Scoring & Reports
- [ ] Relationship Health Score (communication + mood + conflict + trust + consistency)
- [ ] Weekly AI report (% changes in communication, mood stability, conflict frequency)
- [ ] Reminder system: upcoming events (birthday in 5 days, etc.)

### Milestone 6: Notifications
- [ ] Email reminders (Celery + SMTP)
- [ ] WhatsApp link notifications
- [ ] Push notifications (PWA)

---

## Phase 2 — Growth Features

- [ ] Shared calendar (events + reminders + tasks)
- [ ] Couple goals (date night, savings, travel, fitness)
- [ ] Gratitude log (daily appreciation entries)
- [ ] Memory vault (photos + milestones, AI references positive memories)
- [ ] AI mediation (both users submit their side → AI generates shared understanding + action plan)
- [ ] Expand relationship types: family, friends, co-founders, teams

---

## Phase 3 — Revenue & Scale

- [ ] Freemium gate (mood tracking + basic reminders = free)
- [ ] Premium subscription ₹199/month (AI analysis + coach + weekly reports)
- [ ] Couples counseling referral links (commission)
- [ ] Gift marketplace affiliate (flowers, cakes, gifts)
- [ ] Date booking affiliate (restaurants, travel, events)

---

## Data Models (Core)

```
User
  └── Profile

Relationship
  ├── creator (FK User)
  ├── partner (FK User, nullable until accepted)
  ├── type (couple | parent_child | friends | business)
  └── status (pending | active)

MoodEntry
  ├── user (FK)
  ├── relationship (FK)
  ├── mood (happy | neutral | sad | angry | stressed)
  ├── note (optional)
  └── created_at

ConnectionScore
  ├── user (FK)
  ├── relationship (FK)
  ├── score (1–10)
  └── date

Event
  ├── relationship (FK)
  ├── type (birthday | anniversary | promise | travel | other)
  ├── title
  └── date

ConflictEntry
  ├── relationship (FK)
  ├── logged_by (FK User)
  ├── category (money | time | work | family | trust | communication | other)
  ├── description
  ├── severity (1–5)
  └── resolved (bool)

HealthScore
  ├── relationship (FK)
  ├── communication_score
  ├── mood_score
  ├── conflict_score
  ├── overall_score
  └── week_of
```

---

## AI Rules (Non-Negotiable)

| Banned | Allowed |
|--------|---------|
| "She is losing interest." | "Communication frequency has decreased." |
| "He doesn't love you." | "You may benefit from discussing recent changes." |
| Strong claims | Observations + probabilities only |

---

## Revenue Potential

| Users | Monthly | Annual |
|-------|---------|--------|
| 1,000 | ₹1.99L | ₹24L |
| 10,000 | ₹19.9L | ₹2.4Cr |
| 1,00,000 | ₹1.99Cr | ₹24Cr |

---

## Key Risk

**Trust.** Wrong AI prediction can cause the very conflict it tries to prevent.  
Mitigation: always frame output as observation, never diagnosis. Add "AI can be wrong" disclaimer on all suggestions.

---

## Validation Score

| Factor | Score |
|--------|-------|
| Market Size | 9/10 |
| Emotional Need | 10/10 |
| Recurring Usage | 9/10 |
| Subscription Potential | 8/10 |
| Viral Potential | 8/10 |
| Technical Complexity | 7/10 |
| **Overall** | **8.5/10** |

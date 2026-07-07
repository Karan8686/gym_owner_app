# GOAL.md — FitTrack Owner App

## What this app is
A Flutter mobile app for a single gym owner to manage members, memberships, UPI payment verification, and workout plans — replacing an existing Google Sheet that's outgrown itself. This is the **owner-side** app only. A separate `gym_member_app` exists for members and talks to the same Supabase backend.

## Who uses it
One gym owner (single admin user for v1 — no multi-staff roles yet). Currently manages ~2200 total / ~1000 active members via a Google Sheet.

## Primary objective
Let the owner, from their phone, in under a minute:
1. See who's expiring soon and who's already expired — without manually scanning a sheet.
2. Register a new member or renew an existing one.
3. Confirm a UPI payment a member claims to have made.
4. Assign or edit a member's weekly workout plan.

## Success criteria for v1
- Owner can fully stop using the Google Sheet for day-to-day member/payment tracking.
- No manual "who expired" checking — the dashboard surfaces it automatically.
- Payment confirmation takes one tap once the owner has checked their bank/UPI app.
- Existing ~2200-row sheet data is migrated in, not re-entered by hand.

## Tech stack
- **Frontend:** Flutter, Riverpod for state management
- **Backend:** Supabase (Postgres + Auth + Storage), free tier
- **Notifications:** Firebase Cloud Messaging (push only — DB stays on Supabase)
- **Scheduled jobs:** Supabase Edge Function + pg_cron for daily expiry checks
- **Payments:** No gateway. Direct UPI deep link/QR to the owner's own VPA. Manual confirmation flow — no webhook, no commission.

## Core data model (Supabase / Postgres)
```
plan_prices     : id, plan_type ('weight' | 'cardio_weight'), duration_months (1/3/6/12), price
members         : id, sr_no, name, phone_no, photo_url, auth_user_id, created_at
memberships     : id, member_id, plan_type, duration_months, price_charged,
                  start_date, due_date, payment_date, status ('active'|'expired'|'pending_renewal')
payments        : id, member_id, membership_id, amount, utr_number, screenshot_url,
                  status ('pending'|'confirmed'|'rejected'), paid_at, confirmed_at, confirmed_by
workout_templates : id, name, created_by, created_at
workout_exercises : id, template_id (nullable if member-specific), member_id (nullable if template),
                    day_of_week, exercise_name, sets, reps, rest_seconds, notes, sort_order
notifications_log : id, member_id, type ('renewal_due'|'expired'), sent_at
```
Row Level Security: owner's `auth_user_id` has full read/write on all tables. Members (via the separate member app) can only read their own rows — enforced at the DB level, not just in app logic.

## Screens in scope for v1 (15 — see Stitch design spec for visual detail)
1. Login
2. Dashboard / Home (active / expiring / expired counts, renewals-due list)
3. Member List & Search (filter by status)
4. Member Detail (membership + payment history + workout link)
5. Add New Member
6. Edit Member
7. Quick Renew Membership
8. Pending Payments list
9. Payment Verification detail
10. Plan & Pricing Settings (edit the 8 price points)
11. Workout Template Library
12. Workout Template Editor
13. Assign Workout to Member
14. Revenue & Analytics
15. Settings + Notifications/Activity Log

## Business rules that must be encoded correctly
- Renewing a membership extends `due_date` by the selected duration **from the current `due_date`** if not yet expired, or **from today** if already expired — never silently overwrites without this check.
- A payment stays `pending` until the owner explicitly confirms it. Confirming a payment is what triggers extending `due_date`, not the member submitting a UTR.
- `plan_prices` changes only affect future renewals; existing `memberships.price_charged` values are historical and immutable.
- The daily expiry-check job (Edge Function + pg_cron) is the single source of truth for flipping `status` to `expired` and firing the renewal-reminder notification — the app UI should never compute this client-side, to avoid drift between the owner's dashboard and the member's countdown.

## Out of scope for v1 (don't build unless asked)
- Multi-staff / multi-branch support
- Automatic UPI payment verification via webhook (Setu/Decentro) — manual confirmation only for now
- In-app chat between owner and member (use the existing WhatsApp/phone contact flow instead)
- Attendance/check-in tracking

## Migration note
Existing data lives in a Google Sheet (columns: Sr_No, Name, Phone_No, 4 Weight_ price tiers, 4 Cardio_Weight_ price tiers, Start_Date, Months, Due_Date, Payment_Date, Image). A one-time import script splits this into `plan_prices`, `members`, and `memberships` — see prior migration discussion for the exact mapping. Known data quality issues to handle: some `Phone_No` values are `0` (missing), some phone numbers repeat across family members sharing one number — so phone is never used as a unique login key, only as a contact field.

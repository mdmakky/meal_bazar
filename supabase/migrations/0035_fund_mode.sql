-- 0035_fund_mode: does this mess keep a fund (members deposit first, costs are
-- paid from it)? On: a negative fund is flagged and the app asks, when a cost
-- would overdraw it, whether someone paid from their own pocket (which credits
-- that member's account). Off: no fund is shown (settled at month end).
-- Presentation only: no money maths changes.
alter table public.messes add column fund_mode boolean not null default true;

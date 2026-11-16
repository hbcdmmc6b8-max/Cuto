-- Cuto 20.6 feedback backend. Run in Supabase SQL Editor.
-- Replace the placeholder UUID below with your real Supabase Auth user ID.
create table if not exists public.cuto_feedback (
 id uuid primary key default gen_random_uuid(),
 author_id uuid not null references auth.users(id) on delete cascade,
 category text not null check(category in ('Idea','Bug report','UI feedback')),
 title text not null check(char_length(title) between 5 and 80),
 body text not null check(char_length(body) between 15 and 1000),
 status text not null default 'new' check(status in ('new','planned','in_progress','added','declined')),
 created_at timestamptz not null default now()
);
create index if not exists cuto_feedback_author_time on public.cuto_feedback(author_id,created_at desc);
create table if not exists public.cuto_feedback_owners (
 user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.cuto_feedback enable row level security;
alter table public.cuto_feedback_owners enable row level security;
revoke all on public.cuto_feedback from anon,authenticated;
grant select,update on public.cuto_feedback to authenticated;
revoke all on public.cuto_feedback_owners from anon,authenticated;
create or replace function public.cuto_is_feedback_owner() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.cuto_feedback_owners where user_id = (select auth.uid()));
$$;
revoke all on function public.cuto_is_feedback_owner() from public;
grant execute on function public.cuto_is_feedback_owner() to authenticated;
drop policy if exists cuto_feedback_owner_read on public.cuto_feedback;
create policy cuto_feedback_owner_read on public.cuto_feedback for select to authenticated using ((select public.cuto_is_feedback_owner()));
drop policy if exists cuto_feedback_owner_update on public.cuto_feedback;
create policy cuto_feedback_owner_update on public.cuto_feedback for update to authenticated using ((select public.cuto_is_feedback_owner())) with check ((select public.cuto_is_feedback_owner()));
create or replace function public.submit_cuto_feedback(p_category text,p_title text,p_body text) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_id uuid;
begin
 if v_uid is null then raise exception 'Sign in required'; end if;
 if p_category not in ('Idea','Bug report','UI feedback') or char_length(trim(p_title)) not between 5 and 80 or char_length(trim(p_body)) not between 15 and 1000 then raise exception 'Invalid feedback'; end if;
 -- Per-account 1 minute cooldown, 10 per day. Enforced server-side.
 perform pg_advisory_xact_lock(hashtextextended(v_uid::text,0));
 if (select count(*) from public.cuto_feedback where author_id=v_uid and created_at > now()-interval '1 minute')>0 then raise exception 'Please wait before submitting again'; end if;
 if (select count(*) from public.cuto_feedback where author_id=v_uid and created_at > now()-interval '1 day')>=10 then raise exception 'Daily feedback limit reached'; end if;
 insert into public.cuto_feedback(author_id,category,title,body) values(v_uid,p_category,trim(p_title),trim(p_body)) returning id into v_id;
 return v_id;
end $$;
revoke all on function public.submit_cuto_feedback(text,text,text) from public;
grant execute on function public.submit_cuto_feedback(text,text,text) to authenticated;
-- REQUIRED OWNER SETUP, AFTER CREATING A PASSWORD ACCOUNT:
-- insert into public.cuto_feedback_owners(user_id) values ('YOUR-OWNER-AUTH-USER-UUID');
-- Keep service_role credentials private. Never put them in the frontend.

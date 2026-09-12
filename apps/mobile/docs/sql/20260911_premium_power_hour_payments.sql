-- ORA Phase 2: ₦100 one-hour Premium Power Hour
-- This migration is intentionally not applied automatically.

create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null default 'paystack',
  reference text not null unique,
  provider_transaction_id bigint,
  amount_kobo integer not null check (amount_kobo > 0),
  currency text not null default 'NGN' check (currency = 'NGN'),
  product_code text not null default 'power_hour',
  status text not null default 'pending' check (status in ('pending','success','failed','abandoned')),
  paid_at timestamptz,
  provider_payload jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payment_transactions_user_created_idx
  on public.payment_transactions(user_id, created_at desc);

create index if not exists payment_transactions_status_idx
  on public.payment_transactions(status);

create table if not exists public.premium_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  starts_at timestamptz not null,
  expires_at timestamptz not null,
  source_payment_id uuid unique references public.payment_transactions(id) on delete set null,
  product_code text not null default 'power_hour',
  created_at timestamptz not null default now(),
  check (expires_at > starts_at)
);

create index if not exists premium_entitlements_user_expiry_idx
  on public.premium_entitlements(user_id, expires_at desc);

alter table public.payment_transactions enable row level security;
alter table public.premium_entitlements enable row level security;

drop policy if exists "Users can view their own payment transactions" on public.payment_transactions;
create policy "Users can view their own payment transactions"
  on public.payment_transactions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can view their own premium entitlements" on public.premium_entitlements;
create policy "Users can view their own premium entitlements"
  on public.premium_entitlements
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- The client must not be able to create or modify payment records or entitlements.
revoke insert, update, delete on public.payment_transactions from anon, authenticated;
revoke insert, update, delete on public.premium_entitlements from anon, authenticated;

create or replace function public.set_payment_transaction_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists payment_transactions_updated_at on public.payment_transactions;
create trigger payment_transactions_updated_at
before update on public.payment_transactions
for each row execute function public.set_payment_transaction_updated_at();

revoke execute on function public.set_payment_transaction_updated_at() from public, anon, authenticated;

-- Supabase's default grants on the public schema (applied after migrations).
grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;
grant execute on all functions in schema public to anon, authenticated;
-- Supabase applies its default grants when an object is created, so these
-- migration revokes (0017) win there; re-apply them after the blanket grants.
revoke all on public.platform_secrets from anon, authenticated;
revoke execute on function public.get_platform_secrets() from public, anon, authenticated;
revoke execute on function public.setup_branding_storage() from public, anon, authenticated;
revoke execute on function public.delete_my_account_0007() from public, anon, authenticated;
grant usage on schema public to service_role;
grant execute on function public.get_platform_secrets() to service_role;

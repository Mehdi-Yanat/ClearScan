insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'user-documents',
  'user-documents',
  false,
  52428800,
  array['application/pdf', 'image/jpeg', 'image/png']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can read their own document backups"
  on storage.objects;
create policy "Users can read their own document backups"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'user-documents'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can upload their own document backups"
  on storage.objects;
create policy "Users can upload their own document backups"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'user-documents'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can delete their own document backups"
  on storage.objects;
create policy "Users can delete their own document backups"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'user-documents'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

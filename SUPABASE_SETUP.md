# Supabase account authentication

ClearScan uses Supabase Auth for email/password account creation, sign-in, saved
sessions, and sign-out. Supabase Auth manages the user records; the account name
is stored in the user's `full_name` metadata. Google sign-in opens the native
Android account picker, then exchanges Google's ID token with Supabase Auth.

1. Create a Supabase project and enable **Email** under **Authentication >
   Sign In / Providers**. Enable **Google** and add your OAuth client IDs there.
2. In Google Cloud Console, configure an Android OAuth client with this exact
   package and the SHA-1 fingerprint for local debug builds:

   ```text
   Package name: com.opensource.clearscan
   SHA-1: 90:3C:B3:F6:10:80:E8:3A:31:DA:74:83:7A:A0:BF:9B:24:5D:29:34
   ```

   This SHA-1 is for the local debug signing key only. Register the SHA-1 for
   your release signing key separately before distributing a release. To check
   signing fingerprints, run `cd android; .\gradlew signingReport` from
   PowerShell in the project root.
3. Create a Google OAuth **Web application** client ID for the server ID token
   audience. Put this ID in `.env` as `google_ID_client`; the launcher passes
   it to the native Google Sign-In SDK as `serverClientId`. In the Supabase
   Google provider's **Client IDs** field, include the Web client ID first and
   the Android client ID as well, separated by commas:

   ```text
   google_ID_client=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
   ```

   Native ID-token sign-in does not use the browser OAuth redirect URL or put
   a Google client secret in the app.
4. Copy [`.env.example`](./.env.example) to `.env`, then set your project URL
   and publishable key as `supabase_project_url` and
   `supabase_publishable_key`.
5. Launch or build ClearScan through the helper script, which reads the client
   settings from `.env` and passes them as compile-time configuration:

   ```powershell
   .\tool\flutter_with_supabase.ps1 run
   .\tool\flutter_with_supabase.ps1 build apk --release
   ```

The `supabase_database_url` value is deliberately not used by the app. Database
connection strings, Google client secrets, `service_role` keys, and other
secret keys must stay on trusted servers and must never be embedded in a mobile
app or `.env`. The Google Web client ID and Supabase publishable key are client
identifiers, not secrets. Protect user data with Supabase Row-Level Security.
If `google_ID_client` is missing, Google sign-in stays disabled while email
authentication remains available.

## Private document backups

Cloud backup is manual: users explicitly select local PDFs or images to upload.
The profile's **Cloud storage** card shows the signed-in user's current backup
usage. Cloud backups can be restored to the app's local Documents list on a
device signed into the same account. **Copy link** uploads the selected file and
copies a private signed URL to the clipboard; anyone with the link can access
that file for 24 hours, after which the link expires.

Before using the feature, open the Supabase SQL Editor and run
[`supabase/storage_setup.sql`](./supabase/storage_setup.sql). It creates the
private `user-documents` bucket (50 MiB maximum per file) and policies that
allow authenticated users to list, upload, download, and delete objects only
inside their own user-ID folder. Re-run this SQL if the bucket was already
configured before cloud deletion was added, so the delete policy is installed.
Do not make this bucket public or remove these policies. Storage is limited by
your Supabase project's plan and bucket limits; the app reports actual usage
and does not show an invented per-user quota.

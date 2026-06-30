# INR Clinic Tracker — setup guide

This app runs as an independent website (not dependent on Claude.ai), using two free services:

- **Supabase** — database that stores patients, reviews, and your dosing rules, plus the login system that restricts who can access the app.
- **GitHub + Vercel** — holds and hosts the code as a static site (no server functions needed anymore).

Total cost: $0 on free tiers.

---

## 1. Create the Supabase project and database

1. Go to supabase.com, sign up free, and create a new project (any name/region; save the DB password somewhere safe, you won't need it day-to-day).
2. Open **SQL Editor** → "New query", paste in the entire contents of `supabase-schema.sql` from this folder, and click **Run**. This creates the patients, visits, and dosing_rules tables with default thresholds and access policies that require a signed-in user.
3. Go to **Project Settings → API** and copy:
   - **Project URL**
   - **anon public key**

## 2. Add your keys to the app

Open `config.js` and replace the placeholders:

```js
window.APP_CONFIG = {
  SUPABASE_URL: "https://abcdefgh.supabase.co",
  SUPABASE_ANON_KEY: "eyJ..."
};
```

## 3. Restrict access — invite the people who should use it

This app has no public sign-up page on purpose, so only people you add can log in.

1. In Supabase, go to **Authentication → Providers** and make sure **Email** is enabled (it is by default).
2. Go to **Authentication → Settings** and turn **off** "Allow new users to sign up" (so nobody can self-register).
3. Go to **Authentication → Users → Add user**, enter each colleague's email and a temporary password. Tell them this password (they aren't forced to change it automatically — if you want that, you can additionally send a password-reset invite from the same screen).
4. To remove someone's access later, delete or disable their user here — no code changes needed.

## 4. Push the code to GitHub

```
git init
git add .
git commit -m "Initial INR clinic tracker"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

## 5. Deploy on Vercel

1. Go to vercel.com, sign in with GitHub, **Add New → Project**, import the repository.
2. Leave build settings as default (plain static site) and click **Deploy**.
3. You'll get a live URL like `your-app.vercel.app` that works on any device.

Future edits: push to GitHub again and Vercel redeploys automatically.

## 6. Using it

- Open the site → you'll land on a sign-in screen. Log in with the email/password your administrator created for you in Supabase.
- **Patients tab**: add patients, log reviews, see history and automatic TTR (Rosendaal method), with a banner and red badge whenever a patient's TTR drops below 60%.
- **Dosing rules tab**: edit the JSON thresholds that drive the instant suggestion shown the moment you enter an INR value during a review (e.g. "if INR is 0.3–0.5 below target, increase TWD by 10%"). No AI, no external calls, no cost — pure local logic against rules you control.
- **Sign out** is in the bottom-left of the sidebar.

## Notes

- Data is private to your signed-in users only; nobody outside the accounts you create in Supabase can read or write it.
- If someone forgets their password, use **Authentication → Users → (select user) → Send password recovery** in Supabase.
- The rule-based suggestion is decision support based on thresholds you define — review and adjust the JSON in the Dosing rules tab to match your clinic's actual protocol.

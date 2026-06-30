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

## 6. If you already deployed this app before

Re-run `supabase-schema.sql` in the Supabase SQL editor — it's safe to run again, and will add the new columns (factor notes, load dose, sub-action fields) to your existing `visits` table without losing data. It will *not* overwrite dosing rules you've already saved; if you want to reset to the latest built-in defaults (based on the HQE2 protocol), run `delete from dosing_rules where id = 1;` first, then re-run the schema file — or simply edit the tiers directly in the Dosing rules tab.

## 7. Using it

- Open the site → you'll land on a sign-in screen. Log in with the email/password your administrator created for you in Supabase.
- **Patients tab**: add patients one by one, or click **Import CSV** in the sidebar to bulk-upload a patient registry. Click **Template** first to download a CSV with the expected columns (`name, mrn, phone, indication, target_low, target_high, duration`) and an example row — fill it in (e.g. from Excel, save as CSV) and import it. Rows missing a name or MRN are skipped and you'll see a summary of how many were imported.
- Reviews, history, and automatic TTR (Rosendaal method) work the same as before, with a banner and red badge whenever a patient's TTR drops below 60%.
- **Factors**: pick "No significant factor detected" when nothing relevant applies, or any combination of the listed factors. Each checked factor reveals its own small notes box so you can record specifics (e.g. "missed 2 doses while traveling") per factor, not just one shared free-text field.
- **Plan**: choose Continue dose, Load dose, Withhold dose, or Refer MOPD.
  - *Load dose*: enter the load dose in mg and how many days, then choose what happens after — continue dose, or increase TWD by a %.
  - *Withhold dose*: enter how many days to withhold, then choose what happens after — continue dose, or reduce TWD by a %.
- **Dosing rules tab**: set up your dose-adjustment thresholds without touching code. There are two tables — "If INR is below target range" and "If INR is above target range." Each row (tier) says: up to how far the INR deviates, what % to change the total weekly dose by, and (for high INR) how many days to withhold first. Click **+ Add tier** to add a row, **Remove** to delete one, and **Save rules** when done. Tiers are automatically sorted from mildest to most severe deviation, and the first tier wide enough to cover the actual deviation is the one used. The app also applies a ±1mg/day maximum daily-dose-change cap automatically and shows a suggested new TWD figure in mg, not just a percentage. These thresholds immediately drive the suggestion shown the moment you type an INR value on the review screen — no AI, no external calls, no cost.
- **Export data / Import data** (sidebar): **Export data** downloads a single JSON file containing every patient, every review, and your current dosing rules — a full backup. **Import data** lets you pick a previously exported JSON file and restores it back into the database (adds new records, updates existing ones by ID, so re-importing the same file is safe). Use this to move data between two separate Supabase projects, or to keep periodic backups.
- **Sign out** is in the bottom-left of the sidebar.

## Notes

- Data is private to your signed-in users only; nobody outside the accounts you create in Supabase can read or write it.
- If someone forgets their password, use **Authentication → Users → (select user) → Send password recovery** in Supabase.
- The rule-based suggestion is decision support based on thresholds you define — review and adjust the JSON in the Dosing rules tab to match your clinic's actual protocol.

# x-recap

A tiny single-user service that pulls your **X (Twitter) bookmarks**, summarizes them with an LLM, and emails you a monthly digest.

- **No web tier.** No Sidekiq. No Rails proper.
- Just Ruby + ActiveRecord + Postgres + Faraday + ruby_llm + Mailgun.
- Designed to be invoked as one-shot scripts (`bin/sync`, `bin/digest`) by a Railway cron service.

## How it works

1. **`bin/sync`** — calls the X API, pulls your latest bookmarks, dedupes by `tweet_id`, optionally pushes new ones to Raindrop.io.
2. **`bin/digest`** — syncs first, then asks OpenAI to summarize this month's bookmarks into a scannable HTML briefing, and emails it to you via Mailgun.

You run `bin/sync` daily and `bin/digest` monthly.

## Setup

### 1. Local dev

```bash
asdf install            # picks up .tool-versions
bundle install
cp .env.example .env    # then fill in real values
createdb x_recap_development
bundle exec rake db:migrate
```

### 2. X OAuth tokens (one-time)

Follow the manual flow described in [docs/X_OAUTH_SETUP.md](docs/X_OAUTH_SETUP.md) to get an access token + refresh token. Then:

```bash
bin/setup-tokens you@example.com <x_access_token> <x_refresh_token>
```

The refresh token rotates on every API call from then on — no manual steps again.

### 3. Try it locally

```bash
bin/sync          # pull bookmarks
bin/digest        # send a digest email for the current month
```

## Deploy to Railway

This service has two pieces on Railway:

1. **Postgres plugin** — attach the standard Railway Postgres. It sets `DATABASE_URL` automatically.
2. **One service per cron schedule** — Railway's "Cron" service type runs a one-shot container on a schedule.

### Service: x-recap-sync (daily)

- **Source:** this GitHub repo
- **Service type:** Cron
- **Schedule:** `0 16 * * *` (or whatever cadence you want — daily is plenty)
- **Start command:** `bundle exec rake db:migrate && bundle exec ruby bin/sync`
- **Env vars:** see below

### Service: x-recap-digest (monthly)

- **Source:** this GitHub repo
- **Service type:** Cron
- **Schedule:** `0 16 1 * *` (16:00 UTC on the 1st of each month)
- **Start command:** `bundle exec rake db:migrate && bundle exec ruby bin/digest`
- **Env vars:** see below

> Why migrate in the start command? Railway-recommended pattern: it runs inside Railway's private network where `postgres.railway.internal` resolves, and `db:migrate` is idempotent (a no-op when there are no pending migrations) so the cost on each cron tick is negligible. Avoids needing `railway run` or `DATABASE_PUBLIC_URL` for routine schema changes.

### Required env vars (both services)

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Auto-set by the Postgres plugin. |
| `USER_EMAIL` | The single user this app runs for. The digest is sent here. |
| `X_CLIENT_ID` | From [developer.x.com](https://developer.x.com). |
| `X_CLIENT_SECRET` | From [developer.x.com](https://developer.x.com). |
| `OPENAI_API_KEY` | Used by `AiBookmarkSummarizer` (via `ruby_llm`). |
| `MAILGUN_API_KEY` | Mailgun account API key. |
| `SMTP_DOMAIN` | The Mailgun sending domain (e.g. `mg.example.com`). |
| `FROM_EMAIL` | What appears in the `From:` header. e.g. `X Recap <no-reply@mg.example.com>` |

### One-time: seed your X tokens

`bin/setup-tokens` is the only thing that needs a manual one-time run. The migration runs itself on the next cron tick (see start command above).

`railway run` injects the *internal* `DATABASE_URL`, which doesn't resolve from your laptop — so for one-shot commands like this, override with the public URL:

```bash
DATABASE_URL=$(railway variables --json | jq -r '.DATABASE_PUBLIC_URL') \
  bin/setup-tokens you@example.com <x_access_token> <x_refresh_token>
```

(Get `DATABASE_PUBLIC_URL` from the Postgres service's Variables tab if you don't have the Railway CLI handy — it ends in `.proxy.rlwy.net`.)

## Cost note

Railway is per-second usage-billed; cron services only consume resources during the brief execution window, so this workload is rounding-error-level for a typical Hobby ($5/mo credit) or Pro ($20/mo credit) plan.

## License

MIT — see [LICENSE](LICENSE).

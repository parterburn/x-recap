# X Bookmarks Setup

One-time manual flow to generate OAuth 2.0 **user** tokens in the X Developer Console, then save them to your user record. The app auto-refreshes after that — you never need to do this again.

## Prerequisites

In your `.env` (from [developer.x.com](https://developer.x.com) → your app → Keys and Tokens):

```bash
X_CLIENT_ID=your_client_id
X_CLIENT_SECRET=your_client_secret
```

Make sure your app has the required user scopes:

```
users.read tweet.read bookmark.read offline.access
```

---

## Step 1: Generate user tokens

In the X Developer Console, open your app settings and generate an OAuth 2.0 access token for your own user. The token panel should show both:

- `access_token`
- `refresh_token`

The access token is short-lived, but the refresh token is valid for months and lets the app keep refreshing automatically.

## Step 2: Save tokens to your user record

```bash
bin/setup-tokens you@email.com ACCESS_TOKEN REFRESH_TOKEN
```

## Step 3: Fetch bookmarks

```bash
bin/sync
```

Done. The refresh token rotates automatically on each use — no manual steps needed again.

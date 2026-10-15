# Phone to laptop: Tailscale and USB

The stack runs on the laptop behind nginx on `:8080`. The phone reaches it over HTTPS through
Tailscale (works from anywhere, real certificate), or over USB with `adb reverse` (offline demos).
Only devices on your tailnet can reach the Tailscale URL.

## 1. Install Tailscale

- **CachyOS (Arch-based):** `sudo pacman -S tailscale`, then `sudo systemctl enable --now tailscaled`
  and `sudo tailscale up`. Log in with the browser link it prints.
- **Phone:** install the Tailscale app from Google Play and log in with the same account.
  Leave it connected while you sync (offline-first, so only needed at sync time).

## 2. Admin console (https://login.tailscale.com/admin/dns)

1. Turn on **MagicDNS**.
2. Under **HTTPS Certificates**, click **Enable HTTPS**.

Your laptop is now reachable as `<laptop>.<tailnet>.ts.net` (the developer's is
`aleksa-laptop.taila87519.ts.net`). Get the full name with
`tailscale status --json | grep -m1 DNSName` and drop the trailing dot.

`tailscale status` may warn that systemd-resolved and NetworkManager are wired together incorrectly.
That only affects name resolution on the laptop; the phone and `tailscale serve` still work.
See https://tailscale.com/s/resolved-nm if you want the laptop to resolve `ts.net` names too.

## 3. Publish nginx over HTTPS

```bash
sudo tailscale serve --bg --https=443 http://localhost:8080
tailscale serve status        # shows https://<laptop>.<tailnet>.ts.net -> http://localhost:8080
```

VERIFY: the flag syntax changed between releases. The ticket's older form
`tailscale serve --bg https / http://localhost:8080` was replaced in Tailscale 1.52+ by
`tailscale serve --bg [--https=443] <target>`. Check `tailscale serve --help` for your version.
Verified on the developer's laptop with `sudo tailscale serve --bg --https=443 http://localhost:8080`
(the phone reached `/api/v1/health/` and the admin login over mobile data).
Stop publishing with `sudo tailscale serve reset`.

## 4. Configure the stack

In `.env` (never commit it), set the real name:

```
ALLOWED_HOSTS=localhost,127.0.0.1,<laptop>.<tailnet>.ts.net
CSRF_TRUSTED_ORIGINS=https://<laptop>.<tailnet>.ts.net
```

Then `$DC up -d` to recreate django. Django trusts `X-Forwarded-Proto` and `X-Forwarded-Host`
(`SECURE_PROXY_SSL_HEADER`, `USE_X_FORWARDED_HOST`), and nginx passes both through. If Tailscale
serve does not send `X-Forwarded-Host`, nginx falls back to the `Host` it received.

Check from any device on the tailnet:

- `https://<laptop>.<tailnet>.ts.net/api/v1/health/` returns JSON.
- `https://<laptop>.<tailnet>.ts.net/admin/` login works (no CSRF or "invalid host" error).

## 5. USB fallback (no network)

Phone connected over USB with debugging on:

```bash
adb reverse tcp:8080 tcp:8080
```

In the app, set the server URL to `http://localhost:8080`. This is cleartext HTTP, so the debug
build must allow it for `localhost` only (below).

## 6. Android cleartext config (mobile, done by the developer)

Debug builds only, so release builds keep the default (HTTPS only).

`mobile/android/app/src/debug/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">localhost</domain>
    </domain-config>
</network-security-config>
```

And in `mobile/android/app/src/debug/AndroidManifest.xml`, add this inside `<manifest>`:

```xml
<application android:networkSecurityConfig="@xml/network_security_config" />
```

Docker commands in this repo are written for bash (`$DC`). In fish, use
`set DC docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml`.

## 7. Check on the phone

Turn Wi-Fi off (mobile data only), open the app's server settings, enter
`https://<laptop>.<tailnet>.ts.net` and press **Test connection**. It should succeed.

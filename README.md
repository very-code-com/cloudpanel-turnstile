# Cloudflare Turnstile for CloudPanel

> **Disclaimer:** This software is provided "as is", without warranty of any kind. Use at your own risk. The author assumes no responsibility for any damage, data loss, security issues, or compatibility problems arising from the use of this plugin. See the [License](#license) section for full terms.

Cloudflare Turnstile CAPTCHA protection for the [CloudPanel](https://www.cloudpanel.io) admin login page.

Replaces the login template with a version that includes the Turnstile widget and adds a server-side token verification endpoint. No changes to CloudPanel's PHP/Symfony code — only one Twig template and one PHP file.

## Requirements

- CloudPanel v2.x (Ubuntu 22.04 / 24.04)
- Cloudflare account with a Turnstile site: https://dash.cloudflare.com → Turnstile

## Installation

### From release archive

Download the latest release from the [Releases](https://github.com/very-code-com/cloudpanel-turnstile/releases) page:

```bash
tar xzf cloudpanel-turnstile-v*.tar.gz
cd cloudpanel-turnstile

TURNSTILE_SITE_KEY="your-site-key" TURNSTILE_SECRET="your-secret-key" sudo ./scripts/install.sh
```

### From source

```bash
git clone https://github.com/very-code-com/cloudpanel-turnstile.git
cd cloudpanel-turnstile

TURNSTILE_SITE_KEY="your-site-key" TURNSTILE_SECRET="your-secret-key" sudo ./scripts/install.sh
```

If you run `install.sh` without environment variables, it will prompt for the keys interactively. Leave blank to use Cloudflare test keys (development only).

## Test keys

Cloudflare provides test keys that always pass verification:

| Key | Value |
|-----|-------|
| Site Key | `1x00000000000000000000AA` |
| Secret Key | `1x0000000000000000000000000000000AA` |

Test keys display a red "For testing only" banner in the widget.

## File structure

```
cloudpanel-turnstile/
├── src/
│   ├── login.html.twig    # Patched login template with Turnstile widget
│   └── ts-verify.php      # Server-side token verification endpoint
├── scripts/
│   └── install.sh         # Installer (also used to re-apply after updates)
└── README.md
```

## After CloudPanel updates

CloudPanel updates overwrite `login.html.twig`. Re-apply Turnstile by running the installer again:

```bash
TURNSTILE_SITE_KEY="your-site-key" TURNSTILE_SECRET="your-secret" sudo ./scripts/install.sh
```

`ts-verify.php` is placed in `public/` as a new file and is not affected by CloudPanel updates.

## How it works

1. User visits `/login` — Turnstile widget loads and verifies automatically (or presents a challenge)
2. On success, the token is sent to `/ts-verify.php` via `fetch()` in the background
3. `ts-verify.php` validates the token against Cloudflare's API server-side
4. If valid, the login form is allowed to submit; otherwise it is blocked with an error

The plugin uses a **fail-open** strategy: if `ts-verify.php` is unreachable (e.g. network issue), login is allowed through so that Cloudflare downtime never locks you out of the panel.

## Security

- Token verification is **server-side** — the secret key never leaves the server
- Recommended to combine with CloudPanel's built-in IP whitelist (Admin Area → Security) for defense in depth

## Disclaimer

THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF DATA, SECURITY BREACHES, OR SERVICE INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This plugin modifies CloudPanel login page files. While a re-install is straightforward, always ensure you have backups of your server before installation. Compatibility with future CloudPanel versions is not guaranteed.

## License

Copyright 2026 Emilian Scibisz. Licensed under the [Apache License, Version 2.0](LICENSE).

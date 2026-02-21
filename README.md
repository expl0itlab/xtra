# XTRA v2.0 — Web Reconnaissance Tool

![Version](https://img.shields.io/badge/Version-2.0-blue)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Termux%20%7C%20macOS-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Shell](https://img.shields.io/badge/Shell-Bash-lightgrey)
![Year](https://img.shields.io/badge/Year-2026-brightgreen)

XTRA is a multi-page web reconnaissance tool written in pure Bash. It crawls entire sites not just one page, and extracts emails, phone numbers, social profiles, links, metadata, HTTP headers, HTML comments, and technology stack information. Results are saved in organized output files with optional JSON and CSV export.

---

## What's New in v2.0

| Feature | v1.0 | v2.0 |
|---|---|---|
| Pages scanned | 1 | Up to 500+ (configurable) |
| Phone accuracy | High false-positive rate | `tel:` href priority + international format |
| Social profiles | ✗ | ✓ 12 platforms |
| Technology detection | ✗ | ✓ 40+ signatures |
| HTTP header analysis | ✗ | ✓ Raw + security gap report |
| HTML comment extraction | ✗ | ✓ |
| robots.txt / sitemap.xml | ✗ | ✓ Auto-fetched, URLs queued |
| JSON export | ✗ | ✓ |
| CSV export | ✗ | ✓ |
| Internal vs external links | ✗ | ✓ Split automatically |
| Quiet / verbose modes | ✗ | ✓ |
| Crawl rate limiting | ✗ | ✓ Configurable delay |

---

## Features

### Crawler
- Recursive multi-page crawl with configurable depth and page limit
- Visited-URL tracking to prevent loops
- Domain scoping — stays on the target site, does not wander to third parties
- Polite request delay between pages (configurable)
- robots.txt parsed for disallowed paths; sitemap.xml URLs fed directly into the crawl queue

### Extraction
- **Emails** — deduplicated, filters out placeholder addresses like `example@test.com`
- **Phone numbers** — extracted from `tel:` href attributes first (high confidence), then international and US formats
- **Social profiles** — Twitter/X, LinkedIn (personal + company), GitHub, Instagram, Facebook, YouTube, TikTok, Telegram, Reddit
- **Links** — all discovered URLs, automatically split into internal and external files
- **HTML comments** — all `<!-- ... -->` blocks, often containing internal paths, credentials, or developer notes
- **Page metadata** — title, description, keywords, charset per crawled page

### Intelligence
- **Technology detection** — 40+ signatures covering CMS (WordPress, Drupal, Shopify, Joomla), JS frameworks (React, Vue, Angular, Next.js), analytics (GA4, GTM, Hotjar, Mixpanel), CDNs (Cloudflare, Fastly, CloudFront), server software (Nginx, Apache, Varnish), e-commerce platforms, and more
- **HTTP header analysis** — raw headers saved per page; a separate security report flags missing `X-Frame-Options`, `Content-Security-Policy`, `Strict-Transport-Security`, and `X-XSS-Protection`

### Output
- Clean, timestamped output folder
- Optional JSON export (structured, jq-compatible)
- Optional CSV export (flat type/value format for spreadsheets)
- Quiet mode for scripting; verbose mode for debugging
- Summary table printed at end of every scan

---

## Installation

**Standard (Linux / macOS / WSL)**
```bash
git clone https://github.com/expl0itlab/xtra.git
cd xtra
chmod +x xtra.sh
```

**One-line**
```bash
curl -sL https://raw.githubusercontent.com/expl0itlab/xtra/main/xtra.sh -o xtra.sh && chmod +x xtra.sh
```

**Termux (Android)**
```bash
pkg install git curl -y
git clone https://github.com/expl0itlab/xtra.git
cd xtra
chmod +x xtra.sh
```

**Dependencies** — `curl`, `grep`, `sed`, `awk`, `sort` (all standard on Linux/macOS). `python3` is optional and enables full JSON export; a basic fallback is used if it is not present.

---

## Usage

### Interactive mode
```bash
./xtra.sh
```
Prompts for URL, scan mode, crawl settings, and output options.

### CLI mode
```bash
./xtra.sh -u <URL> [options]
```

### Options

| Option | Short | Description | Default |
|---|---|---|---|
| `--url URL` | `-u` | Target URL (required) | — |
| `--fast` | `-f` | Full crawl, extract everything | ✓ default |
| `--single` | `-s` | Single page scan only | — |
| `--meta` | `-m` | Metadata + headers + tech detection only | — |
| `--depth N` | `-d` | Maximum crawl depth | 3 |
| `--pages N` | `-p` | Maximum pages to crawl | 50 |
| `--delay N` | `-w` | Seconds between requests | 1 |
| `--output DIR` | `-o` | Output directory | auto-timestamped |
| `--json` | | Export results as JSON | off |
| `--csv` | | Export results as CSV | off |
| `--quiet` | `-q` | Suppress all output except errors and summary | off |
| `--verbose` | `-v` | Show every request and match | off |
| `--help` | `-h` | Show help | — |

---

## Examples

```bash
# Full site crawl — up to 100 pages, export JSON, save to ./results
./xtra.sh -u https://example.com -f -p 100 --json -o ./results

# Quick single-page scan
./xtra.sh -u https://example.com -s

# Metadata and tech detection only, quiet output
./xtra.sh -u https://example.com -m -q

# Deep crawl with a polite 2-second delay between requests
./xtra.sh -u https://example.com -f -d 5 -p 200 -w 2

# Full crawl with both JSON and CSV export
./xtra.sh -u https://example.com -f --json --csv

# Verbose mode for debugging
./xtra.sh -u https://example.com -s -v
```

---

## Output Structure

```
xtra_results_20250615_142301/
├── emails.txt              Extracted email addresses (deduplicated)
├── phones.txt              Phone numbers
├── socials.txt             Social media profile URLs
├── links.txt               All discovered URLs
├── links_internal.txt      URLs on the same domain
├── links_external.txt      URLs on external domains
├── metadata.txt            Per-page title, description, keywords, charset
├── html_comments.txt       All HTML source comments
├── technologies.txt        Detected tech stack
├── headers.txt             Raw HTTP response headers per page
├── security_headers.txt    Missing security headers flagged per page
├── robots.txt              Target's robots.txt (if present)
├── results.json            Full structured export (with --json)
├── results.csv             Flat type/value export (with --csv)
└── report.txt              Scan summary report
```

### JSON structure
```json
{
  "meta": {
    "tool": "XTRA",
    "version": "2.0",
    "timestamp": "2025-06-15T14:23:01Z",
    "target": "https://example.com",
    "base_domain": "example.com",
    "scan_mode": "crawl",
    "pages_crawled": 42
  },
  "emails": ["contact@example.com"],
  "phones": ["+1 800 555 0100"],
  "socials": ["https://github.com/example"],
  "links": ["https://example.com/about"],
  "links_internal": ["https://example.com/about"],
  "links_external": ["https://cdn.example.net"],
  "technologies": ["WordPress", "Cloudflare", "jQuery"],
  "security_missing_headers": ["Content-Security-Policy", "X-Frame-Options"]
}
```

---

## Detected Technologies

XTRA fingerprints 40+ technologies across the following categories:

**CMS** — WordPress, Joomla, Drupal, Magento, Shopify, Wix, Squarespace, Ghost

**Frameworks / Languages** — Laravel, Django, Ruby on Rails, ASP.NET, PHP

**JavaScript** — React, Vue.js, Angular, Next.js, Nuxt.js, jQuery

**UI / CSS** — Bootstrap, Tailwind CSS, Bulma

**Analytics** — Google Analytics 4, Google Tag Manager, Hotjar, Matomo, Mixpanel

**CDN / Infrastructure** — Cloudflare, Fastly, AWS CloudFront, Nginx, Apache, Varnish

**E-commerce** — WooCommerce, PrestaShop, OpenCart

**Support / Chat** — Intercom, Zendesk, Algolia

**Security** — reCAPTCHA, hCaptcha

---

## Security Header Analysis

For every page crawled, XTRA checks for the presence of the following headers and flags any that are missing in `security_headers.txt`:

- `X-Frame-Options` — clickjacking protection
- `Content-Security-Policy` — XSS and injection mitigation
- `Strict-Transport-Security` — HTTPS enforcement
- `X-XSS-Protection` — legacy XSS filter
- `Access-Control-Allow-Origin` — CORS policy

---

## Troubleshooting

**Permission denied**
```bash
chmod +x xtra.sh
```

**Missing dependencies (manual install)**
```bash
# Debian / Ubuntu
sudo apt-get install curl grep sed gawk

# Arch
sudo pacman -S curl grep sed gawk

# Termux
pkg install curl grep sed gawk
```

**No results on a page you know has emails**
Run with `-v` (verbose) to see each request. The site may be JavaScript-rendered — XTRA works on server-rendered HTML only and does not execute JavaScript. For JS-heavy sites, combine XTRA with a tool like `wget --mirror` or Playwright to pre-render pages.

**Getting blocked quickly**
Increase the delay between requests: `-w 3` or higher. Some sites also block the default user-agent — the full Chrome UA used in v2.0 helps, but aggressive WAFs may still block automated requests.

**JSON export fails**
Ensure `python3` is installed. A basic JSON fallback (emails only) is used when python3 is not available.

---

## Ethical & Legal Use

XTRA is built for:
- Security assessments on systems you own or have **written permission** to test
- Bug bounty programs — only against in-scope targets
- Educational use and learning about web technologies
- Authorized penetration testing engagements

**Do not use XTRA to scan systems without authorization.** Unauthorized scanning may violate the Computer Fraud and Abuse Act (USA), the Computer Misuse Act (UK), and equivalent laws in other jurisdictions. You are solely responsible for how you use this tool.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

Bug reports and technology signature contributions are especially welcome.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Developed by Exploit Lab | Tremor — XTRA v2.0 | 2026*

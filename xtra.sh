#!/bin/bash

# XTRA v2.0 - Advanced Web Scraper & Reconnaissance Tool
# Exploit Lab | Tremor

# ANSI Color Codes
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
PURPLE='\033[1;95m'
CYAN='\033[1;96m'
WHITE='\033[1;97m'
GRAY='\033[0;37m'
NC='\033[0m'

VERSION="2.0"
TOOL_NAME="XTRA"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
TIMEOUT=10
SCAN_MODE="fast"
TARGET_URL=""
OUTPUT_DIR=""
CRAWL_DELAY=1
MAX_PAGES=50
MAX_DEPTH=3
VERBOSITY=1          # 0=quiet, 1=normal, 2=verbose
OUTPUT_JSON=false
OUTPUT_CSV=false
VISITED_URLS=()
CRAWL_QUEUE=()
BASE_DOMAIN=""
PAGES_CRAWLED=0

log_info()    { [[ $VERBOSITY -ge 1 ]] && echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}$*${NC}"; }
log_success() { [[ $VERBOSITY -ge 1 ]] && echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}$*${NC}"; }
log_error()   { echo -e "${WHITE}[${RED}!${WHITE}] ${RED}$*${NC}"; }
log_verbose() { [[ $VERBOSITY -ge 2 ]] && echo -e "${GRAY}[~] $*${NC}"; }
log_section() { [[ $VERBOSITY -ge 1 ]] && echo -e "\n${CYAN}=== $* ===${NC}"; }

display_banner() {
    clear
    echo -e "${CYAN}"
    echo "██╗  ██╗████████╗██████╗  █████╗"
    echo "╚██╗██╔╝╚══██╔══╝██╔══██╗██╔══██╗"
    echo " ╚███╔╝    ██║   ██████╔╝███████║"
    echo " ██╔██╗    ██║   ██╔══██╗██╔══██║"
    echo "██╔╝ ██╗   ██║   ██║  ██║██║  ██║"
    echo "╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${YELLOW} XTRA Web Scraper v${VERSION}${NC}"
    echo -e "${BLUE} Exploit Lab | Tremor${NC}"
    echo -e "${GRAY} Multi-page crawler | Tech detection | Social extraction${NC}\n"
}

# DEPENDENCY CHECK
check_dependencies() {
    log_info "Checking dependencies..."

    local packages=("curl" "grep" "sed" "awk" "sort")
    local missing=()

    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    # Optional but recommended
    if command -v python3 &>/dev/null; then
        log_verbose "python3 available — JSON export enabled"
    else
        log_verbose "python3 not found — JSON export will be basic"
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing: ${missing[*]}"

        if [ -d "/data/data/com.termux/files/usr" ]; then
            log_info "Installing for Termux..."
            pkg update -y && pkg install -y "${missing[@]}" || { log_error "Installation failed"; return 1; }
        elif command -v apt-get &>/dev/null; then
            log_info "Installing for Debian/Ubuntu..."
            sudo apt-get update && sudo apt-get install -y "${missing[@]}" || { log_error "Installation failed"; return 1; }
        elif command -v yum &>/dev/null; then
            log_info "Installing for RHEL/CentOS..."
            sudo yum install -y "${missing[@]}" || { log_error "Installation failed"; return 1; }
        elif command -v pacman &>/dev/null; then
            log_info "Installing for Arch..."
            sudo pacman -Sy --noconfirm "${missing[@]}" || { log_error "Installation failed"; return 1; }
        else
            log_error "Please install manually: ${missing[*]}"
            return 1
        fi
    fi

    log_success "Dependencies OK"
    return 0
}

# INTERNET CHECK
check_internet() {
    log_info "Checking internet connectivity..."
    if curl -s --connect-timeout 3 --max-time 5 https://google.com >/dev/null 2>&1; then
        log_success "Internet connection OK"
        return 0
    else
        log_error "No internet connection"
        return 1
    fi
}

# URL UTILITIES
validate_url() {
    local url="$1"
    [[ ! "$url" =~ ^https?:// ]] && url="http://$url"
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(:[0-9]+)?(/.*)?$ ]]; then
        echo "$url"
        return 0
    fi
    return 1
}

extract_domain() {
    local url="$1"
    echo "$url" | grep -oE '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | head -1
}

# Normalize a relative URL against the base
resolve_url() {
    local base="$1"
    local href="$2"

    # Already absolute
    if [[ "$href" =~ ^https?:// ]]; then
        echo "$href"
        return
    fi

    # Skip fragments, mailto, javascript, data URIs
    if [[ "$href" =~ ^(#|mailto:|javascript:|data:|tel:) ]] || [ -z "$href" ]; then
        return
    fi

    local scheme
    scheme=$(echo "$base" | grep -oE '^https?')
    local domain
    domain=$(echo "$base" | grep -oE '^https?://[^/]+')

    if [[ "$href" == //* ]]; then
        echo "${scheme}:${href}"
    elif [[ "$href" == /* ]]; then
        echo "${domain}${href}"
    else
        local base_path
        base_path=$(echo "$base" | sed 's|/[^/]*$|/|')
        echo "${base_path}${href}"
    fi
}

# Check if a URL belongs to the target domain
is_same_domain() {
    local url="$1"
    local domain
    domain=$(extract_domain "$url")
    [[ "$domain" == *"$BASE_DOMAIN"* ]] || [[ "$BASE_DOMAIN" == *"$domain"* ]]
}

# Check if URL was already visited
is_visited() {
    local url="$1"
    for v in "${VISITED_URLS[@]}"; do
        [[ "$v" == "$url" ]] && return 0
    done
    return 1
}

# PAGE FETCH
fetch_page() {
    local url="$1"
    local html_out="$2"
    local headers_out="$3"

    log_verbose "Fetching: $url"

    local http_code
    http_code=$(curl -s -L -A "$USER_AGENT" \
        --connect-timeout "$TIMEOUT" \
        --max-time $((TIMEOUT * 2)) \
        -D "$headers_out" \
        -o "$html_out" \
        -w "%{http_code}" \
        "$url" 2>/dev/null)

    if [ -s "$html_out" ] && [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        return 0
    else
        rm -f "$html_out" "$headers_out"
        log_verbose "HTTP $http_code for $url"
        return 1
    fi
}

# ROBOTS.TXT & SITEMAP
fetch_robots() {
    local base_url="$1"
    local output="${OUTPUT_DIR}/robots.txt"

    log_info "Fetching robots.txt..."

    local robots_url="${base_url%/}/robots.txt"
    local http_code
    http_code=$(curl -s -A "$USER_AGENT" --connect-timeout "$TIMEOUT" \
        -o "$output" -w "%{http_code}" "$robots_url" 2>/dev/null)

    if [[ "$http_code" == "200" ]] && [ -s "$output" ]; then
        log_success "robots.txt found"

        # Extract sitemap URLs from robots.txt and queue them for sitemap fetch
        local sitemaps
        sitemaps=$(grep -i '^Sitemap:' "$output" | awk '{print $2}')
        while IFS= read -r sitemap_url; do
            [ -n "$sitemap_url" ] && fetch_sitemap "$sitemap_url"
        done <<< "$sitemaps"

        # Log disallowed paths
        local disallowed
        disallowed=$(grep -i '^Disallow:' "$output" | awk '{print $2}' | grep -v '^$')
        if [ -n "$disallowed" ]; then
            log_verbose "Disallowed paths found in robots.txt"
            echo "$disallowed" >> "${OUTPUT_DIR}/disallowed_paths.txt" 2>/dev/null
        fi
    else
        log_verbose "robots.txt not found or empty (HTTP $http_code)"
        rm -f "$output"
    fi
}

fetch_sitemap() {
    local sitemap_url="$1"
    local tmp_sitemap=".xtra_sitemap_$$.xml"

    log_info "Fetching sitemap: $sitemap_url"

    local http_code
    http_code=$(curl -s -A "$USER_AGENT" --connect-timeout "$TIMEOUT" \
        -o "$tmp_sitemap" -w "%{http_code}" "$sitemap_url" 2>/dev/null)

    if [[ "$http_code" == "200" ]] && [ -s "$tmp_sitemap" ]; then
        # Extract URLs from sitemap and add to crawl queue
        local urls
        urls=$(grep -oE 'https?://[^<"]+' "$tmp_sitemap" | grep -v '\.xml$' | sort -u)
        local count=0
        while IFS= read -r url; do
            if [ -n "$url" ] && is_same_domain "$url" && ! is_visited "$url"; then
                CRAWL_QUEUE+=("$url")
                ((count++))
            fi
        done <<< "$urls"
        log_success "Sitemap: queued $count URLs"

        # Handle sitemap index (sitemaps of sitemaps)
        local child_sitemaps
        child_sitemaps=$(grep -oE 'https?://[^<"]+\.xml' "$tmp_sitemap")
        while IFS= read -r child; do
            [ -n "$child" ] && fetch_sitemap "$child"
        done <<< "$child_sitemaps"
    fi

    rm -f "$tmp_sitemap"
}

# CRAWLER
crawl_site() {
    local start_url="$1"
    local depth="$2"

    # Guard conditions
    [ "$PAGES_CRAWLED" -ge "$MAX_PAGES" ] && return
    [ "$depth" -gt "$MAX_DEPTH" ] && return
    is_visited "$start_url" && return

    VISITED_URLS+=("$start_url")
    ((PAGES_CRAWLED++))

    [[ $VERBOSITY -ge 1 ]] && echo -e "${GRAY}  [${PAGES_CRAWLED}/${MAX_PAGES}] Crawling (depth ${depth}): $start_url${NC}"

    local html_file=".xtra_temp_${RANDOM}_$$.html"
    local headers_file=".xtra_headers_${RANDOM}_$$.txt"
    local text_file=".xtra_text_${RANDOM}_$$.txt"

    if ! fetch_page "$start_url" "$html_file" "$headers_file"; then
        return
    fi

    # Strip HTML tags for text extraction
    sed 's/<[^>]*>//g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&nbsp;/ /g; s/&[^;]*;//g' \
        "$html_file" > "$text_file" 2>/dev/null

    # --- Run all extractions and append to master output files ---
    append_emails   "$text_file"
    append_phones   "$html_file"
    append_links    "$html_file" "$start_url"
    append_socials  "$html_file"
    append_comments "$html_file"
    append_metadata "$html_file" "$start_url"
    append_headers  "$headers_file" "$start_url"
    detect_technologies "$html_file" "$headers_file"

    # --- Discover child links on this page for recursive crawl ---
    if [ "$depth" -lt "$MAX_DEPTH" ] && [ "$PAGES_CRAWLED" -lt "$MAX_PAGES" ]; then
        local hrefs
        hrefs=$(grep -oiE 'href="[^"#?]+"' "$html_file" | sed 's/href="//i; s/"//')
        while IFS= read -r href; do
            local resolved
            resolved=$(resolve_url "$start_url" "$href")
            if [ -n "$resolved" ] && is_same_domain "$resolved" && ! is_visited "$resolved"; then
                CRAWL_QUEUE+=("$resolved")
            fi
        done <<< "$hrefs"
    fi

    rm -f "$html_file" "$text_file" "$headers_file"

    # Polite delay between requests
    [ "$PAGES_CRAWLED" -lt "$MAX_PAGES" ] && sleep "$CRAWL_DELAY"

    # Drain queue at depth + 1
    local next_url="${CRAWL_QUEUE[0]}"
    if [ -n "$next_url" ]; then
        CRAWL_QUEUE=("${CRAWL_QUEUE[@]:1}")
        crawl_site "$next_url" $((depth + 1))
    fi
}

# EXTRACTION — APPEND MODE (called per page during crawl)
append_emails() {
    local input="$1"
    grep -E -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$input" 2>/dev/null \
        >> "${OUTPUT_DIR}/.emails_raw.txt"
}

append_phones() {
    local input="$1"

    # High-confidence: from tel: href attributes
    grep -oiE 'href="tel:[+0-9()[ .-]{7,20}"' "$input" 2>/dev/null \
        | grep -oE '[+0-9()[ .-]{7,20}' >> "${OUTPUT_DIR}/.phones_raw.txt"

    # International format with country code
    grep -E -o '\+[1-9][0-9]{0,3}[ .-]?(\([0-9]{1,4}\)[ .-]?)?[0-9]{6,14}' "$input" 2>/dev/null \
        >> "${OUTPUT_DIR}/.phones_raw.txt"

    # US format: (xxx) xxx-xxxx or xxx-xxx-xxxx
    grep -E -o '\([0-9]{3}\)[ .-]?[0-9]{3}[ .-]?[0-9]{4}' "$input" 2>/dev/null \
        >> "${OUTPUT_DIR}/.phones_raw.txt"
}

append_links() {
    local input="$1"
    local base="$2"
    grep -E -o 'https?://[^"'"'"'<>()\s]+' "$input" 2>/dev/null \
        >> "${OUTPUT_DIR}/.links_raw.txt"
}

append_socials() {
    local input="$1"

    local platforms=(
        "twitter\.com/[a-zA-Z0-9_]{1,50}"
        "x\.com/[a-zA-Z0-9_]{1,50}"
        "linkedin\.com/in/[a-zA-Z0-9_-]+"
        "linkedin\.com/company/[a-zA-Z0-9_-]+"
        "github\.com/[a-zA-Z0-9_-]+"
        "instagram\.com/[a-zA-Z0-9_.]+"
        "facebook\.com/[a-zA-Z0-9.]+"
        "youtube\.com/[@a-zA-Z0-9_-]+"
        "tiktok\.com/@[a-zA-Z0-9_.]+"
        "t\.me/[a-zA-Z0-9_]+"
        "reddit\.com/u/[a-zA-Z0-9_-]+"
        "reddit\.com/r/[a-zA-Z0-9_-]+"
    )

    for pattern in "${platforms[@]}"; do
        grep -E -o "https?://${pattern}" "$input" 2>/dev/null \
            >> "${OUTPUT_DIR}/.socials_raw.txt"
    done
}

append_comments() {
    local input="$1"
    # Extract HTML comments, skip empty or whitespace-only ones
    grep -oE '<!--(.|\n)*?-->' "$input" 2>/dev/null \
        | grep -vE '^<!--\s*-->$' \
        >> "${OUTPUT_DIR}/.comments_raw.txt"
}

append_metadata() {
    local input="$1"
    local url="$2"

    {
        echo ""
        echo "### $url"
        echo -n "Title: "
        grep -i '<title>' "$input" 2>/dev/null | head -1 \
            | sed -e 's/<[^>]*>//g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
        echo -n "Description: "
        grep -i 'meta.*name=.description' "$input" 2>/dev/null | head -1 \
            | grep -oiE 'content="[^"]+"' | sed 's/content="//i; s/"//'
        echo -n "Keywords: "
        grep -i 'meta.*name=.keywords' "$input" 2>/dev/null | head -1 \
            | grep -oiE 'content="[^"]+"' | sed 's/content="//i; s/"//'
        echo -n "Charset: "
        grep -i 'meta.*charset' "$input" 2>/dev/null | head -1 \
            | grep -oiE 'charset=[a-zA-Z0-9_-]+' | sed 's/charset=//i'
    } >> "${OUTPUT_DIR}/metadata.txt" 2>/dev/null
}

append_headers() {
    local headers_file="$1"
    local url="$2"

    [ ! -s "$headers_file" ] && return

    {
        echo ""
        echo "### $url"
        cat "$headers_file"
    } >> "${OUTPUT_DIR}/headers.txt" 2>/dev/null

    # Parse security-relevant headers
    {
        local server
        server=$(grep -i '^Server:' "$headers_file" | head -1 | sed 's/Server: //i')
        local powered
        powered=$(grep -i '^X-Powered-By:' "$headers_file" | head -1 | sed 's/X-Powered-By: //i')
        local xframe
        xframe=$(grep -i '^X-Frame-Options:' "$headers_file")
        local csp
        csp=$(grep -i '^Content-Security-Policy:' "$headers_file")
        local hsts
        hsts=$(grep -i '^Strict-Transport-Security:' "$headers_file")
        local xss
        xss=$(grep -i '^X-XSS-Protection:' "$headers_file")
        local cors
        cors=$(grep -i '^Access-Control-Allow-Origin:' "$headers_file")

        echo ""
        echo "### $url"
        [ -n "$server"  ] && echo "Server: $server"
        [ -n "$powered" ] && echo "X-Powered-By: $powered"
        [ -z "$xframe"  ] && echo "MISSING: X-Frame-Options"
        [ -z "$csp"     ] && echo "MISSING: Content-Security-Policy"
        [ -z "$hsts"    ] && echo "MISSING: Strict-Transport-Security"
        [ -z "$xss"     ] && echo "MISSING: X-XSS-Protection"
        [ -n "$cors"    ] && echo "CORS: $cors"
    } >> "${OUTPUT_DIR}/security_headers.txt" 2>/dev/null
}

# TECHNOLOGY DETECTION
detect_technologies() {
    local html="$1"
    local headers="$2"
    local combined=".xtra_combined_$$.txt"

    cat "$html" "$headers" 2>/dev/null > "$combined"

    declare -A signatures=(
        # CMS
        ["WordPress"]="wp-content|wp-includes|wordpress"
        ["Joomla"]="joomla|/components/com_"
        ["Drupal"]="drupal|sites/default/files"
        ["Magento"]="Mage\.|mage/cookies|magento"
        ["Shopify"]="shopify\.com|Shopify\.theme|cdn\.shopify"
        ["Wix"]="wix\.com|wixsite\.com"
        ["Squarespace"]="squarespace\.com|static\.squarespace"
        ["Ghost"]="ghost\.io|content/images"
        # Frameworks / Languages
        ["Laravel"]="laravel_session|Laravel"
        ["Django"]="csrfmiddlewaretoken|django"
        ["Rails"]="rails|ruby-on-rails|csrf-token"
        ["ASP.NET"]="__VIEWSTATE|asp\.net|\.aspx"
        ["PHP"]="\.php|X-Powered-By: PHP"
        # JS Frameworks
        ["React"]="react\.development|__reactFiber|_reactRoot|react-root"
        ["Vue.js"]="vue\.js|__vue__|vue-router"
        ["Angular"]="ng-version|angular\.js|ng-app"
        ["Next.js"]="__NEXT_DATA__|/_next/static"
        ["Nuxt.js"]="__nuxt__|/_nuxt/"
        ["jQuery"]="jquery\.min\.js|jquery-[0-9]"
        # UI / CSS
        ["Bootstrap"]="bootstrap\.min\.css|bootstrap\.bundle"
        ["Tailwind"]="tailwindcss|tw-"
        ["Bulma"]="bulma\.css|bulma\.min"
        # Analytics / Marketing
        ["Google Analytics"]="google-analytics\.com|gtag\('config"
        ["Google Tag Manager"]="googletagmanager\.com/gtm"
        ["Hotjar"]="hotjar\.com|hjid"
        ["Matomo"]="matomo\.js|piwik\.js"
        ["Mixpanel"]="mixpanel\.com|mixpanel\.track"
        # Infrastructure / CDN
        ["Cloudflare"]="cloudflare|cf-ray|__cfduid"
        ["Fastly"]="fastly|x-served-by.*cache"
        ["AWS CloudFront"]="cloudfront\.net|x-amz-cf"
        ["Nginx"]="nginx"
        ["Apache"]="Apache"
        ["Varnish"]="X-Varnish|Via:.*varnish"
        # E-commerce
        ["WooCommerce"]="woocommerce|wc-ajax"
        ["PrestaShop"]="prestashop|presta_shop"
        ["OpenCart"]="opencart|route=common"
        # Search / Chat
        ["Algolia"]="algolia\.com|algoliaSearch"
        ["Intercom"]="intercom\.com|intercomSettings"
        ["Zendesk"]="zendesk\.com|zdassets"
        # Security
        ["reCAPTCHA"]="recaptcha\.net|google\.com/recaptcha"
        ["hCaptcha"]="hcaptcha\.com"
    )

    for tech in "${!signatures[@]}"; do
        if grep -qiE "${signatures[$tech]}" "$combined" 2>/dev/null; then
            echo "$tech" >> "${OUTPUT_DIR}/.technologies_raw.txt"
        fi
    done

    rm -f "$combined"
}

# FINALIZE — DEDUPLICATE ALL RAW FILES INTO CLEAN OUTPUTS
finalize_results() {
    log_info "Finalizing and deduplicating results..."

    # Emails
    if [ -f "${OUTPUT_DIR}/.emails_raw.txt" ]; then
        sort -u "${OUTPUT_DIR}/.emails_raw.txt" \
            | grep -vE '@(example|test|domain|email|mail)\.' \
            > "${OUTPUT_DIR}/emails.txt" 2>/dev/null
    fi

    # Phones
    if [ -f "${OUTPUT_DIR}/.phones_raw.txt" ]; then
        sed 's/[()]//g; s/^[ \t]*//; s/[ \t]*$//' "${OUTPUT_DIR}/.phones_raw.txt" 2>/dev/null \
            | sort -u > "${OUTPUT_DIR}/phones.txt"
    fi

    # Links (internal vs external split)
    if [ -f "${OUTPUT_DIR}/.links_raw.txt" ]; then
        sort -u "${OUTPUT_DIR}/.links_raw.txt" > "${OUTPUT_DIR}/links.txt" 2>/dev/null
        grep "$BASE_DOMAIN" "${OUTPUT_DIR}/links.txt" > "${OUTPUT_DIR}/links_internal.txt" 2>/dev/null
        grep -v "$BASE_DOMAIN" "${OUTPUT_DIR}/links.txt" > "${OUTPUT_DIR}/links_external.txt" 2>/dev/null
    fi

    # Socials
    if [ -f "${OUTPUT_DIR}/.socials_raw.txt" ]; then
        sort -u "${OUTPUT_DIR}/.socials_raw.txt" > "${OUTPUT_DIR}/socials.txt" 2>/dev/null
    fi

    # HTML Comments
    if [ -f "${OUTPUT_DIR}/.comments_raw.txt" ]; then
        sort -u "${OUTPUT_DIR}/.comments_raw.txt" > "${OUTPUT_DIR}/html_comments.txt" 2>/dev/null
    fi

    # Technologies
    if [ -f "${OUTPUT_DIR}/.technologies_raw.txt" ]; then
        sort -u "${OUTPUT_DIR}/.technologies_raw.txt" > "${OUTPUT_DIR}/technologies.txt" 2>/dev/null
    fi

    # Clean up raw temp files
    rm -f "${OUTPUT_DIR}"/.*.txt 2>/dev/null

    log_success "Results finalized"
}

# COUNT HELPERS
count_file() {
    local f="${OUTPUT_DIR}/$1"
    [ -f "$f" ] && [ -s "$f" ] && wc -l < "$f" | awk '{print $1}' || echo 0
}

# REPORT GENERATION
write_report() {
    local report="${OUTPUT_DIR}/report.txt"

    cat > "$report" << EOF
================================================================================
XTRA v${VERSION} — Scan Report
================================================================================
Date        : $(date)
Target      : $TARGET_URL
Base Domain : $BASE_DOMAIN
Scan Mode   : $SCAN_MODE
Pages Crawled: $PAGES_CRAWLED / $MAX_PAGES (depth limit: $MAX_DEPTH)

--------------------------------------------------------------------------------
FINDINGS SUMMARY
--------------------------------------------------------------------------------
Emails           : $(count_file emails.txt)
Phone Numbers    : $(count_file phones.txt)
Social Profiles  : $(count_file socials.txt)
Links (total)    : $(count_file links.txt)
  └─ Internal    : $(count_file links_internal.txt)
  └─ External    : $(count_file links_external.txt)
HTML Comments    : $(count_file html_comments.txt)
Technologies     : $(count_file technologies.txt)

--------------------------------------------------------------------------------
TECHNOLOGIES DETECTED
--------------------------------------------------------------------------------
$(cat "${OUTPUT_DIR}/technologies.txt" 2>/dev/null | sed 's/^/  - /' || echo "  None detected")

--------------------------------------------------------------------------------
SECURITY HEADER ANALYSIS
--------------------------------------------------------------------------------
$(grep 'MISSING:' "${OUTPUT_DIR}/security_headers.txt" 2>/dev/null | sort -u | sed 's/^/  /' || echo "  No issues found")

--------------------------------------------------------------------------------
Files Saved
--------------------------------------------------------------------------------
  emails.txt            Extracted email addresses
  phones.txt            Phone numbers
  socials.txt           Social media profiles
  links.txt             All discovered URLs
  links_internal.txt    Internal links only
  links_external.txt    External links only
  metadata.txt          Per-page metadata
  html_comments.txt     HTML source comments
  technologies.txt      Detected tech stack
  headers.txt           Raw HTTP response headers
  security_headers.txt  Header security analysis
  robots.txt            Target's robots.txt (if found)
  report.txt            This report
$([ "$OUTPUT_JSON" == "true" ] && echo "  results.json          Full JSON export")
$([ "$OUTPUT_CSV"  == "true" ] && echo "  results.csv           CSV export")

--------------------------------------------------------------------------------
Generated by XTRA v${VERSION} | Exploit Lab
Use only on systems you own or have explicit permission to test.
================================================================================
EOF

    log_success "Report saved: $report"
}

# JSON EXPORT
export_json() {
    local outfile="${OUTPUT_DIR}/results.json"

    if command -v python3 &>/dev/null; then
        python3 - << PYEOF
import json, os

def read_lines(fname):
    path = os.path.join("${OUTPUT_DIR}", fname)
    try:
        with open(path) as f:
            return [l.strip() for l in f if l.strip()]
    except:
        return []

data = {
    "meta": {
        "tool": "XTRA",
        "version": "${VERSION}",
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "target": "${TARGET_URL}",
        "base_domain": "${BASE_DOMAIN}",
        "scan_mode": "${SCAN_MODE}",
        "pages_crawled": ${PAGES_CRAWLED}
    },
    "emails":        read_lines("emails.txt"),
    "phones":        read_lines("phones.txt"),
    "socials":       read_lines("socials.txt"),
    "links":         read_lines("links.txt"),
    "links_internal": read_lines("links_internal.txt"),
    "links_external": read_lines("links_external.txt"),
    "technologies":  read_lines("technologies.txt"),
    "html_comments": read_lines("html_comments.txt"),
    "security_missing_headers": sorted(set(
        line.replace("MISSING: ", "").strip()
        for line in read_lines("security_headers.txt")
        if "MISSING:" in line
    ))
}
with open("${outfile}", "w") as f:
    json.dump(data, f, indent=2)
print("ok")
PYEOF
        [ $? -eq 0 ] && log_success "JSON exported: $outfile" || log_error "JSON export failed"
    else
        # Fallback: basic JSON without python3
        {
            echo "{"
            echo "  \"target\": \"${TARGET_URL}\","
            echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
            echo "  \"emails\": ["
            if [ -f "${OUTPUT_DIR}/emails.txt" ]; then
                awk '{print "    \""$0"\"," }' "${OUTPUT_DIR}/emails.txt" | sed '$ s/,$//'
            fi
            echo "  ]"
            echo "}"
        } > "$outfile"
        log_success "Basic JSON exported: $outfile"
    fi
}

# CSV EXPORT
export_csv() {
    local outfile="${OUTPUT_DIR}/results.csv"

    {
        echo "type,value"
        [ -f "${OUTPUT_DIR}/emails.txt" ]  && awk '{print "email,"$0}'   "${OUTPUT_DIR}/emails.txt"
        [ -f "${OUTPUT_DIR}/phones.txt" ]  && awk '{print "phone,"$0}'   "${OUTPUT_DIR}/phones.txt"
        [ -f "${OUTPUT_DIR}/socials.txt" ] && awk '{print "social,"$0}'  "${OUTPUT_DIR}/socials.txt"
        [ -f "${OUTPUT_DIR}/technologies.txt" ] && awk '{print "technology,"$0}' "${OUTPUT_DIR}/technologies.txt"
    } > "$outfile"

    log_success "CSV exported: $outfile"
}

# SUMMARY DISPLAY
show_summary() {
    local emails phones socials links_t links_i links_e comments techs

    emails=$(count_file emails.txt)
    phones=$(count_file phones.txt)
    socials=$(count_file socials.txt)
    links_t=$(count_file links.txt)
    links_i=$(count_file links_internal.txt)
    links_e=$(count_file links_external.txt)
    comments=$(count_file html_comments.txt)
    techs=$(count_file technologies.txt)

    echo -e "\n${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         XTRA SCAN COMPLETE           ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════╣${NC}"
    printf "${CYAN}║${NC} %-20s ${GREEN}%-15s${CYAN}║${NC}\n" "Pages crawled:"   "$PAGES_CRAWLED"
    printf "${CYAN}║${NC} %-20s ${GREEN}%-15s${CYAN}║${NC}\n" "Emails:"          "$emails"
    printf "${CYAN}║${NC} %-20s ${GREEN}%-15s${CYAN}║${NC}\n" "Phone numbers:"   "$phones"
    printf "${CYAN}║${NC} %-20s ${GREEN}%-15s${CYAN}║${NC}\n" "Social profiles:" "$socials"
    printf "${CYAN}║${NC} %-20s ${GREEN}%-15s${CYAN}║${NC}\n" "Links (total):"   "$links_t"
    printf "${CYAN}║${NC}   %-18s ${GRAY}%-15s${CYAN}║${NC}\n" "Internal:"        "$links_i"
    printf "${CYAN}║${NC}   %-18s ${GRAY}%-15s${CYAN}║${NC}\n" "External:"        "$links_e"
    printf "${CYAN}║${NC} %-20s ${GREEN}%-15s${CYAN}║${NC}\n" "HTML comments:"   "$comments"
    printf "${CYAN}║${NC} %-20s ${GREEN}%-15s${CYAN}║${NC}\n" "Technologies:"    "$techs"
    echo -e "${CYAN}╠══════════════════════════════════════╣${NC}"
    printf "${CYAN}║${NC} %-20s ${YELLOW}%-15s${CYAN}║${NC}\n" "Output folder:"   "$OUTPUT_DIR"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"

    # Preview top results
    if [ "$emails" -gt 0 ]; then
        echo -e "\n${CYAN}--- Sample Emails ---${NC}"
        head -5 "${OUTPUT_DIR}/emails.txt"
        [ "$emails" -gt 5 ] && echo "  ... and $((emails - 5)) more"
    fi

    if [ "$techs" -gt 0 ]; then
        echo -e "\n${CYAN}--- Technologies ---${NC}"
        cat "${OUTPUT_DIR}/technologies.txt" | sed 's/^/  /'
    fi

    if grep -q 'MISSING:' "${OUTPUT_DIR}/security_headers.txt" 2>/dev/null; then
        echo -e "\n${YELLOW}--- Missing Security Headers ---${NC}"
        grep 'MISSING:' "${OUTPUT_DIR}/security_headers.txt" \
            | sort -u | sed 's/MISSING: /  ⚠  /'
    fi
}

# MAIN SCAN ORCHESTRATOR
run_scan() {
    mkdir -p "$OUTPUT_DIR" || {
        log_error "Failed to create output directory: $OUTPUT_DIR"
        exit 1
    }

    log_success "Output directory: $OUTPUT_DIR"
    log_info "Target: $TARGET_URL"
    log_info "Mode: $SCAN_MODE | Depth: $MAX_DEPTH | Max pages: $MAX_PAGES | Delay: ${CRAWL_DELAY}s"

    # Always fetch robots.txt + sitemap first
    fetch_robots "$TARGET_URL"

    case "$SCAN_MODE" in
        "fast"|"crawl")
            log_section "CRAWLING SITE"
            CRAWL_QUEUE=("$TARGET_URL")
            crawl_site "$TARGET_URL" 1
            ;;
        "single")
            log_section "SINGLE PAGE SCAN"
            MAX_DEPTH=1
            MAX_PAGES=1
            crawl_site "$TARGET_URL" 1
            ;;
        "meta")
            log_section "METADATA SCAN"
            local html_file=".xtra_temp_$$.html"
            local headers_file=".xtra_headers_$$.txt"
            fetch_page "$TARGET_URL" "$html_file" "$headers_file"
            append_metadata "$html_file" "$TARGET_URL"
            append_headers  "$headers_file" "$TARGET_URL"
            detect_technologies "$html_file" "$headers_file"
            rm -f "$html_file" "$headers_file"
            ;;
        "custom")
            log_section "CUSTOM SCAN"
            # Custom mode crawls but lets user pick what to extract
            # Handled via interactive prompts before reaching here
            crawl_site "$TARGET_URL" 1
            ;;
    esac

    finalize_results
    write_report

    [ "$OUTPUT_JSON" == "true" ] && export_json
    [ "$OUTPUT_CSV"  == "true" ] && export_csv

    show_summary

    echo -e "\n${GREEN}✅ Scan completed! Results in: ${OUTPUT_DIR}${NC}"
}

interactive_mode() {
    display_banner
    check_dependencies || exit 1
    check_internet || log_info "Continuing with limited connectivity..."

    log_section "TARGET"
    read -p "$(echo -e "${WHITE}Enter target URL: ${NC}")" url_input
    TARGET_URL=$(validate_url "$url_input")
    if [ $? -ne 0 ]; then
        log_error "Invalid URL. Example: example.com or https://example.com"
        exit 1
    fi
    BASE_DOMAIN=$(extract_domain "$TARGET_URL")

    log_section "SCAN MODE"
    echo -e "${WHITE}1. ${GREEN}Full Crawl${WHITE}       — crawl entire site, extract everything"
    echo -e "${WHITE}2. ${YELLOW}Single Page${WHITE}      — scan one page only"
    echo -e "${WHITE}3. ${PURPLE}Metadata Only${WHITE}    — titles, headers, tech detection"
    echo -e "${WHITE}4. ${RED}Exit${NC}"
    read -p "$(echo -e "\n${WHITE}Select (1-4): ${NC}")" mode_choice

    case $mode_choice in
        1) SCAN_MODE="crawl"  ;;
        2) SCAN_MODE="single" ;;
        3) SCAN_MODE="meta"   ;;
        4) echo -e "${YELLOW}Exiting...${NC}"; exit 0 ;;
        *) log_error "Invalid choice"; exit 1 ;;
    esac

    log_section "CRAWL SETTINGS"
    read -p "$(echo -e "${WHITE}Max pages [${MAX_PAGES}]: ${NC}")" input_pages
    [ -n "$input_pages" ] && MAX_PAGES="$input_pages"
    read -p "$(echo -e "${WHITE}Max depth [${MAX_DEPTH}]: ${NC}")" input_depth
    [ -n "$input_depth" ] && MAX_DEPTH="$input_depth"
    read -p "$(echo -e "${WHITE}Delay between requests in seconds [${CRAWL_DELAY}]: ${NC}")" input_delay
    [ -n "$input_delay" ] && CRAWL_DELAY="$input_delay"

    log_section "OUTPUT"
    read -p "$(echo -e "${WHITE}Output folder [auto]: ${NC}")" folder_name
    OUTPUT_DIR="${folder_name:-xtra_results_$(date '+%Y%m%d_%H%M%S')}"

    read -p "$(echo -e "${WHITE}Export JSON? (y/n) [n]: ${NC}")" -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && OUTPUT_JSON=true

    read -p "$(echo -e "${WHITE}Export CSV? (y/n) [n]: ${NC}")" -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && OUTPUT_CSV=true

    run_scan
}

show_help() {
    display_banner
    cat << EOF
${YELLOW}Usage:${NC}
  $0 [options]

${YELLOW}Scan Modes:${NC}
  -f, --fast            Full crawl, extract everything [default]
  -s, --single          Single page only
  -m, --meta            Metadata + headers + tech detection only

${YELLOW}Target:${NC}
  -u, --url URL         Target URL (required)

${YELLOW}Crawl Control:${NC}
  -d, --depth N         Max crawl depth         [default: 3]
  -p, --pages N         Max pages to crawl      [default: 50]
  -w, --delay N         Seconds between requests [default: 1]

${YELLOW}Output:${NC}
  -o, --output DIR      Output directory (default: auto-timestamped)
  --json                Export results as JSON
  --csv                 Export results as CSV
  -q, --quiet           Suppress output except errors and summary
  -v, --verbose         Show all requests and matches

${YELLOW}Other:${NC}
  -h, --help            Show this help

${YELLOW}Examples:${NC}
  # Full site crawl, up to 100 pages, save JSON
  $0 -u https://example.com -f -p 100 --json -o ./results

  # Quick single-page scan
  $0 -u https://example.com -s

  # Metadata + tech detection only, quiet mode
  $0 -u https://example.com -m -q

  # Deep crawl with polite delay
  $0 -u https://example.com -f -d 5 -p 200 -w 2

  # Interactive mode (no args)
  $0

${RED}Exploit Lab | XTRA v${VERSION} | 2025${NC}
${GRAY}Always obtain proper authorization before scanning.${NC}
EOF
}

cli_mode() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                [ -z "$2" ] && { log_error "URL argument missing"; exit 1; }
                TARGET_URL=$(validate_url "$2")
                [ $? -ne 0 ] && { log_error "Invalid URL: $2"; exit 1; }
                shift 2 ;;
            -f|--fast)    SCAN_MODE="crawl";  shift ;;
            -s|--single)  SCAN_MODE="single"; shift ;;
            -m|--meta)    SCAN_MODE="meta";   shift ;;
            -d|--depth)
                [ -z "$2" ] && { log_error "Depth argument missing"; exit 1; }
                MAX_DEPTH="$2"; shift 2 ;;
            -p|--pages)
                [ -z "$2" ] && { log_error "Pages argument missing"; exit 1; }
                MAX_PAGES="$2"; shift 2 ;;
            -w|--delay)
                [ -z "$2" ] && { log_error "Delay argument missing"; exit 1; }
                CRAWL_DELAY="$2"; shift 2 ;;
            -o|--output)
                [ -z "$2" ] && { log_error "Output dir argument missing"; exit 1; }
                OUTPUT_DIR="$2"; shift 2 ;;
            --json)       OUTPUT_JSON=true;   shift ;;
            --csv)        OUTPUT_CSV=true;    shift ;;
            -q|--quiet)   VERBOSITY=0;        shift ;;
            -v|--verbose) VERBOSITY=2;        shift ;;
            -h|--help)    show_help; exit 0   ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1 ;;
        esac
    done

    [ -z "$TARGET_URL" ] && {
        log_error "No target URL specified. Use -u URL"
        show_help
        exit 1
    }

    BASE_DOMAIN=$(extract_domain "$TARGET_URL")
    [ -z "$OUTPUT_DIR" ] && OUTPUT_DIR="xtra_results_$(date '+%Y%m%d_%H%M%S')"

    display_banner
    check_dependencies || exit 1
    check_internet || log_info "Continuing with limited connectivity..."

    run_scan
}

cleanup() {
    rm -f .xtra_temp_* .xtra_text_* .xtra_headers_* .xtra_sitemap_* .xtra_combined_* 2>/dev/null
}

trap cleanup EXIT INT TERM

if [[ $# -eq 0 ]]; then
    interactive_mode
else
    cli_mode "$@"
fi

exit 0

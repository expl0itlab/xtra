#!/bin/bash

RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
PURPLE='\033[1;95m'
CYAN='\033[1;96m'
WHITE='\033[1;97m'
NC='\033[0m'

VERSION="1.0"
TOOL_NAME="XTRA"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) XTRA-Scraper/1.0"
TIMEOUT=30
MAX_DEPTH=2

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
    echo -e "${YELLOW}↪ XTRA Web Scraper v${VERSION}${NC}"
    echo -e "${BLUE}↪ Exploit Lab | Tremor ${NC}\n"
}

check_dependencies() {
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Checking dependencies...${NC}"
    
    local missing=()
    local packages=("curl" "grep" "sed" "awk")
    
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            missing+=("$pkg")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Missing: ${missing[*]}${NC}"
        
        if [ -d "/data/data/com.termux/files/usr" ]; then
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Installing for Termux...${NC}"
            pkg update -y && pkg install ${missing[*]} -y
        elif command -v apt-get &> /dev/null; then
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Installing for Debian/Ubuntu...${NC}"
            sudo apt-get update && sudo apt-get install -y ${missing[*]}
        elif command -v yum &> /dev/null; then
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Installing for RHEL/CentOS...${NC}"
            sudo yum install -y ${missing[*]}
        elif command -v pacman &> /dev/null; then
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Installing for Arch...${NC}"
            sudo pacman -Sy --noconfirm ${missing[*]}
        else
            echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Please install manually: ${missing[*]}${NC}"
            exit 1
        fi
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Dependencies OK${NC}"
}

check_internet() {
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Checking internet...${NC}"
    
    if curl -s --connect-timeout 5 --max-time 10 http://google.com > /dev/null 2>&1; then
        echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Internet connection OK${NC}"
        return 0
    else
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}No internet connection${NC}"
        return 1
    fi
}

validate_url() {
    local url="$1"
    
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="http://$url"
    fi
    
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} ]]; then
        echo "$url"
        return 0
    else
        return 1
    fi
}

fetch_page() {
    local url="$1"
    local output="$2"
    
    if curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-time $((TIMEOUT * 2)) \
       -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
       "$url" > "$output" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

extract_emails() {
    local input="$1"
    local output="$2"
    
    grep -E -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$input" | sort -u > "$output"
    grep -E -o '[a-zA-Z0-9._%+-]+\s*\[at\]\s*[a-zA-Z0-9.-]+\s*\[dot\]\s*[a-zA-Z]{2,}' "$input" | \
        sed 's/\[at\]/@/g; s/\[dot\]/./g; s/\s//g' >> "$output" 2>/dev/null
    
    sort -u -o "$output" "$output"
    
    local count=$(wc -l < "$output" 2>/dev/null | tr -d ' ')
    echo "$count"
}

extract_phones() {
    local input="$1"
    local output="$2"
    
    grep -E -o '\+[0-9]{1,4}[-\s]?[0-9]{1,14}' "$input" >> "$output"
    grep -E -o '\([0-9]{3}\)[-\s]?[0-9]{3}[-\s]?[0-9]{4}' "$input" >> "$output"
    grep -E -o '[0-9]{3}[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4}' "$input" >> "$output"
    
    sed -i 's/[()]//g; s/\s/-/g; s/\./-/g' "$output"
    sort -u -o "$output" "$output"
    
    local count=$(wc -l < "$output" 2>/dev/null | tr -d ' ')
    echo "$count"
}

extract_links() {
    local input="$1"
    local output="$2"
    
    grep -E -o 'https?://[^"'\''<>()\s]+' "$input" | sort -u > "$output"

    > "${output}.social"
    > "${output}.api"
    > "${output}.files"
    > "${output}.internal"
    > "${output}.external"
    
    local domain=$(echo "$TARGET_URL" | sed -E 's|^https?://([^/]+).*|\1|')
    
    local social_patterns=(
        'facebook\.com'
        'twitter\.com'
        'linkedin\.com'
        'instagram\.com'
        'youtube\.com'
        'tiktok\.com'
        'reddit\.com'
        'pinterest\.com'
    )
    
    local api_patterns=(
        'api\.'
        'graphql'
        'rest'
        'json'
        'xml'
        'soap'
        'endpoint'
    )
    
    local file_patterns=(
        '\.pdf$'
        '\.docx?$'
        '\.xlsx?$'
        '\.pptx?$'
        '\.zip$'
        '\.rar$'
        '\.tar\.gz$'
        '\.csv$'
    )
    
    while IFS= read -r link; do
        for pattern in "${social_patterns[@]}"; do
            if [[ "$link" =~ $pattern ]]; then
                echo "$link" >> "${output}.social"
                break
            fi
        done
        
        for pattern in "${api_patterns[@]}"; do
            if [[ "$link" =~ $pattern ]]; then
                echo "$link" >> "${output}.api"
                break
            fi
        done
        
        for pattern in "${file_patterns[@]}"; do
            if [[ "$link" =~ $pattern ]]; then
                echo "$link" >> "${output}.files"
                break
            fi
        done
        
        if [[ "$link" =~ $domain ]]; then
            echo "$link" >> "${output}.internal"
        else
            echo "$link" >> "${output}.external"
        fi
    done < "$output"
    
    local count=$(wc -l < "$output" 2>/dev/null | tr -d ' ')
    echo "$count"
}

extract_metadata() {
    local input="$1"
    local output="$2"
    
    echo "=== PAGE METADATA ===" > "$output"
    
    echo -e "\n=== TITLE ===" >> "$output"
    grep -i -o '<title>[^<]*</title>' "$input" | sed 's/<[^>]*>//g' >> "$output"
    
    echo -e "\n=== META TAGS ===" >> "$output"
    grep -i '<meta' "$input" | head -20 >> "$output"
    

    echo -e "\n=== HEADINGS ===" >> "$output"
    for i in {1..6}; do
        grep -i "<h$i[^>]*>" "$input" | sed 's/<[^>]*>//g' | head -5 >> "$output"
    done
}

deep_scan() {
    local url="$1"
    local depth="${2:-1}"
    local output_file="$3"
    
    if [ "$depth" -gt $MAX_DEPTH ]; then
        return
    fi
    
    echo -e "${WHITE}[${BLUE}*${WHITE}] ${BLUE}Depth ${depth}: $url${NC}"
    
    local temp_file=".xtra_deep_${depth}_$$.html"
    
    if fetch_page "$url" "$temp_file"; then
    
        cat "$temp_file" >> "$output_file"
        
        if [ "$depth" -lt $MAX_DEPTH ]; then
            grep -E -o 'href="[^"]+"' "$temp_file" | \
            sed 's/href="//; s/"//' | \
            grep -E "^https?://" | \
            grep "$(echo "$url" | sed -E 's|^https?://([^/]+).*|\1|')" | \
            head -3 | while read -r next_url; do
                deep_scan "$next_url" $((depth + 1)) "$output_file"
            done
        fi
    fi
    
    rm -f "$temp_file" 2>/dev/null
}

save_results() {
    local folder_name="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    if [ -z "$folder_name" ]; then
        folder_name="xtra_results_${timestamp}"
    fi
    
    mkdir -p "$folder_name"
    
    for file in *.txt 2>/dev/null; do
        if [ -f "$file" ] && [[ ! "$file" =~ ^\. ]]; then
            mv "$file" "$folder_name/" 2>/dev/null
        fi
    done
    
    cat > "${folder_name}/report.txt" << EOF
XTRA Scan Report
================
Date: $(date)
Target: $TARGET_URL
Scan Mode: $SCAN_MODE

RESULTS SUMMARY:
===============
Emails: $(wc -l < "${folder_name}/emails.txt" 2>/dev/null || echo 0)
Phone Numbers: $(wc -l < "${folder_name}/phones.txt" 2>/dev/null || echo 0)
Total Links: $(wc -l < "${folder_name}/links.txt" 2>/dev/null || echo 0)
- Social Media: $(wc -l < "${folder_name}/links.txt.social" 2>/dev/null || echo 0)
- API Endpoints: $(wc -l < "${folder_name}/links.txt.api" 2>/dev/null || echo 0)
- File Resources: $(wc -l < "${folder_name}/links.txt.files" 2>/dev/null || echo 0)
- Internal Links: $(wc -l < "${folder_name}/links.txt.internal" 2>/dev/null || echo 0)
- External Links: $(wc -l < "${folder_name}/links.txt.external" 2>/dev/null || echo 0)

Scan Configuration:
==================
User Agent: $USER_AGENT
Timeout: ${TIMEOUT}s
Max Depth: $MAX_DEPTH

DISCLAIMER:
==========
This scan was performed for authorized purposes only.
Always ensure proper authorization before scanning websites.

Generated by XTRA v${VERSION}
EOF
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Results saved to: ${folder_name}${NC}"
}

show_summary() {
    echo -e "\n${CYAN}=== SCAN SUMMARY ===${NC}"
    
    if [ -f "emails.txt" ]; then
        local email_count=$(wc -l < "emails.txt" 2>/dev/null | tr -d ' ')
        echo -e "${WHITE}Emails: ${GREEN}${email_count}${NC}"
    fi
    
    if [ -f "phones.txt" ]; then
        local phone_count=$(wc -l < "phones.txt" 2>/dev/null | tr -d ' ')
        echo -e "${WHITE}Phone Numbers: ${GREEN}${phone_count}${NC}"
    fi
    
    if [ -f "links.txt" ]; then
        local link_count=$(wc -l < "links.txt" 2>/dev/null | tr -d ' ')
        echo -e "${WHITE}Total Links: ${GREEN}${link_count}${NC}"
        
        if [ -f "links.txt.social" ]; then
            local social_count=$(wc -l < "links.txt.social" 2>/dev/null | tr -d ' ')
            echo -e "${WHITE}  ↪ Social Media: ${YELLOW}${social_count}${NC}"
        fi
        
        if [ -f "links.txt.api" ]; then
            local api_count=$(wc -l < "links.txt.api" 2>/dev/null | tr -d ' ')
            echo -e "${WHITE}  ↪ API Endpoints: ${YELLOW}${api_count}${NC}"
        fi
    fi
}

perform_scan() {
    local mode="$1"
    local url="$2"
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Fetching target page...${NC}"
    
    local html_file=".xtra_page_$$.html"
    local text_file=".xtra_text_$$.txt"
    
    if ! fetch_page "$url" "$html_file"; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Failed to fetch page${NC}"
        rm -f "$html_file" 2>/dev/null
        return 1
    fi
    
    sed 's/<[^>]*>//g; s/&[^;]*;//g' "$html_file" > "$text_file"
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Page loaded successfully${NC}"
    
    case "$mode" in
        "fast")
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Performing fast scan...${NC}"
            extract_emails "$text_file" "emails.txt"
            extract_phones "$text_file" "phones.txt"
            extract_links "$text_file" "links.txt"
            extract_metadata "$html_file" "metadata.txt"
            ;;
        "deep")
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Performing deep scan...${NC}"
            deep_scan "$url" 1 "deep_scan.html"
            sed 's/<[^>]*>//g; s/&[^;]*;//g' "deep_scan.html" > "$text_file"
            extract_emails "$text_file" "emails.txt"
            extract_phones "$text_file" "phones.txt"
            extract_links "$text_file" "links.txt"
            extract_metadata "$html_file" "metadata.txt"
            ;;
        "meta")
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Extracting metadata...${NC}"
            extract_metadata "$html_file" "metadata.txt"
            ;;
        "api")
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Finding API endpoints...${NC}"
            extract_links "$text_file" "links.txt"
            if [ -f "links.txt.api" ]; then
                cp "links.txt.api" "api_endpoints.txt"
            fi
            ;;
        "custom")
            echo -e "${CYAN}=== SELECT DATA TYPES ===${NC}"
            read -p "$(echo -e "${WHITE}Extract emails? (y/n): ${NC}")" -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && extract_emails "$text_file" "emails.txt"
            
            read -p "$(echo -e "${WHITE}Extract phone numbers? (y/n): ${NC}")" -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && extract_phones "$text_file" "phones.txt"
            
            read -p "$(echo -e "${WHITE}Extract links? (y/n): ${NC}")" -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && extract_links "$text_file" "links.txt"
            
            read -p "$(echo -e "${WHITE}Extract metadata? (y/n): ${NC}")" -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && extract_metadata "$html_file" "metadata.txt"
            ;;
    esac
    
    rm -f "$html_file" "$text_file" "deep_scan.html" 2>/dev/null
    
    return 0
}

interactive_mode() {
    display_banner
    check_dependencies
    check_internet || exit 1
    
    echo -e "${CYAN}=== TARGET SELECTION ===${NC}"
    read -p "$(echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Enter target URL: ${NC}")" url_input
    
    TARGET_URL=$(validate_url "$url_input")
    if [ $? -ne 0 ]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Invalid URL${NC}"
        exit 1
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Target: ${TARGET_URL}${NC}"
    
    echo -e "\n${CYAN}=== SCAN MODES ===${NC}"
    echo -e "${WHITE}1. ${GREEN}Fast Scan${WHITE} - All data types"
    echo -e "${WHITE}2. ${YELLOW}Custom Scan${WHITE} - Choose data types"
    echo -e "${WHITE}3. ${BLUE}Deep Scan${WHITE} - Recursive (depth ${MAX_DEPTH})"
    echo -e "${WHITE}4. ${PURPLE}Metadata Only${WHITE}"
    echo -e "${WHITE}5. ${RED}API Scan${WHITE} - Find API endpoints"
    
    read -p "$(echo -e "\n${WHITE}[${YELLOW}?${WHITE}] ${YELLOW}Select mode (1-5): ${NC}")" mode_choice
    
    case $mode_choice in
        1) SCAN_MODE="fast"; perform_scan "fast" "$TARGET_URL" ;;
        2) SCAN_MODE="custom"; perform_scan "custom" "$TARGET_URL" ;;
        3) SCAN_MODE="deep"; perform_scan "deep" "$TARGET_URL" ;;
        4) SCAN_MODE="meta"; perform_scan "meta" "$TARGET_URL" ;;
        5) SCAN_MODE="api"; perform_scan "api" "$TARGET_URL" ;;
        *) echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Invalid choice${NC}"; exit 1 ;;
    esac
    
    if [ $? -eq 0 ]; then
        show_summary
        
        echo -e "\n${CYAN}=== SAVE RESULTS ===${NC}"
        read -p "$(echo -e "${WHITE}Save results to folder? (y/n): ${NC}")" -n 1 -r; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "$(echo -e "${WHITE}Folder name (enter for auto): ${NC}")" folder_name
            save_results "$folder_name"
        else
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Results are in current directory${NC}"
        fi
    fi
    
    echo -e "\n${GREEN}Scan completed!${NC}"
}

cli_mode() {
    display_banner
    check_dependencies
    check_internet || exit 1
    
    local mode="fast"
    local output_dir=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                TARGET_URL=$(validate_url "$2")
                if [ $? -ne 0 ]; then
                    echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Invalid URL: $2${NC}"
                    exit 1
                fi
                shift 2
                ;;
            -f|--fast)
                mode="fast"
                shift
                ;;
            -d|--deep)
                mode="deep"
                shift
                ;;
            -m|--meta)
                mode="meta"
                shift
                ;;
            -a|--api)
                mode="api"
                shift
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            *)
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [ -z "$TARGET_URL" ]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}No target URL specified${NC}"
        show_help
        exit 1
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Target: ${TARGET_URL}${NC}"
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Mode: ${mode}${NC}"
    
    SCAN_MODE="$mode"
    perform_scan "$mode" "$TARGET_URL"
    
    if [ $? -eq 0 ]; then
        show_summary
        
        if [ -n "$output_dir" ]; then
            save_results "$output_dir"
        else
            save_results ""
        fi
    fi
}

show_help() {
    display_banner
    cat << EOF

${YELLOW}Usage:${NC}
  $0 [options]

${YELLOW}Options:${NC}
  -u, --url URL      Target URL to scan (required)
  -f, --fast         Fast scan (all data types) [default]
  -d, --deep         Deep recursive scan
  -m, --meta         Metadata only
  -a, --api          API endpoint discovery
  -o, --output DIR   Output directory
  -h, --help         Show this help

${YELLOW}Examples:${NC}
  $0 -u https://example.com -f
  $0 --url example.com --deep --output ./results
  $0 -u https://site.com -a

${YELLOW}Interactive Mode:${NC}
  $0  (run without arguments)

${RED}Exploit Lab | XTRA v${VERSION} | 2025${NC}
EOF
}

if [[ $# -eq 0 ]]; then
    interactive_mode
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
else
    cli_mode "$@"
fi

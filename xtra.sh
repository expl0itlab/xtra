#!/bin/bash

RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
PURPLE='\033[1;95m'
CYAN='\033[1;96m'
WHITE='\033[1;97m'
NC='\033[0m'

# Configuration
VERSION="1.0"
TOOL_NAME="XTRA"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) XTRA-Scraper/1.0"
TIMEOUT=10
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
    echo -e "${YELLOW} XTRA Web Scraper v${VERSION}${NC}"
    echo -e "${BLUE} Exploit Lab | Tremor ${NC}\n"
}

check_dependencies() {
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Checking dependencies...${NC}"
    
    local packages=("curl" "grep")
    local missing=()
    
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
    
    if curl -s --connect-timeout 3 --max-time 5 https://httpbin.org/status/200 > /dev/null 2>&1; then
        echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Internet connection OK${NC}"
        return 0
    else
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}No internet connection${NC}"
        return 1
    fi
}

validate_url() {
    local url="$1"
    
    # Add http:// if no protocol
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="http://$url"
    fi
    
    # Simple URL validation
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
    
    echo -e "${WHITE}[${BLUE}*${WHITE}] ${BLUE}Fetching: $url${NC}"
    
    # Simple curl with timeout
    curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-time $((TIMEOUT * 2)) \
         "$url" 2>/dev/null > "$output"
    
    if [ -s "$output" ]; then
        return 0
    else
        return 1
    fi
}

extract_emails() {
    local input="$1"
    local output="$2"
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Extracting emails...${NC}"
    
    # Simple email pattern
    grep -E -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$input" | sort -u > "$output" 2>/dev/null
    
    local count=0
    if [ -f "$output" ]; then
        count=$(wc -l < "$output" 2>/dev/null | tr -d ' ')
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Found ${count} emails${NC}"
    
    if [ "$count" -gt 0 ] && [ "$count" -lt 10 ]; then
        echo -e "${CYAN}=== EMAILS ===${NC}"
        cat "$output"
    fi
}

extract_phones() {
    local input="$1"
    local output="$2"
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Extracting phone numbers...${NC}"
    
    # Create empty file first
    > "$output"
    
    # Try different phone patterns
    grep -E -o '\+[0-9]{1,4}[-\s]?[0-9]{1,14}' "$input" >> "$output" 2>/dev/null
    grep -E -o '\([0-9]{3}\)[-\s]?[0-9]{3}[-\s]?[0-9]{4}' "$input" >> "$output" 2>/dev/null
    grep -E -o '[0-9]{3}[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4}' "$input" >> "$output" 2>/dev/null
    
    # Clean up
    if [ -f "$output" ]; then
        sed -i 's/[()]//g; s/\s\+/ /g' "$output" 2>/dev/null
        sort -u -o "$output" "$output" 2>/dev/null
    fi
    
    local count=0
    if [ -f "$output" ]; then
        count=$(wc -l < "$output" 2>/dev/null | tr -d ' ')
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Found ${count} phone numbers${NC}"
    
    if [ "$count" -gt 0 ] && [ "$count" -lt 10 ]; then
        echo -e "${CYAN}=== PHONE NUMBERS ===${NC}"
        cat "$output"
    fi
}

extract_links() {
    local input="$1"
    local output="$2"
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Extracting links...${NC}"
    
    # Simple URL extraction
    grep -E -o 'https?://[^"'"'"'<>()\s]+' "$input" | sort -u > "$output" 2>/dev/null
    
    local count=0
    if [ -f "$output" ]; then
        count=$(wc -l < "$output" 2>/dev/null | tr -d ' ')
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Found ${count} links${NC}"
    
    # Show first few links
    if [ "$count" -gt 0 ] && [ "$count" -lt 5 ]; then
        echo -e "${CYAN}=== LINKS ===${NC}"
        head -5 "$output"
    elif [ "$count" -ge 5 ]; then
        echo -e "${CYAN}=== FIRST 5 LINKS ===${NC}"
        head -5 "$output"
        echo "..."
    fi
}

extract_metadata() {
    local input="$1"
    local output="$2"
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Extracting metadata...${NC}"
    
    echo "=== PAGE METADATA ===" > "$output"
    
    # Title
    echo -e "\n=== TITLE ===" >> "$output"
    grep -i '<title>' "$input" | head -1 | sed 's/<[^>]*>//g' >> "$output" 2>/dev/null
    
    # Meta description
    echo -e "\n=== META DESCRIPTION ===" >> "$output"
    grep -i 'meta.*description' "$input" | head -3 >> "$output" 2>/dev/null
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Metadata extracted${NC}"
}

perform_scan() {
    local mode="$1"
    local url="$2"
    
    # Create temp files
    local html_file=".xtra_temp_$$.html"
    local text_file=".xtra_text_$$.txt"
    
    # Fetch the page
    if ! fetch_page "$url" "$html_file"; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Failed to fetch page${NC}"
        rm -f "$html_file" "$text_file" 2>/dev/null
        return 1
    fi
    
    # Convert HTML to text (simplified)
    sed 's/<[^>]*>//g; s/&[^;]*;//g' "$html_file" > "$text_file" 2>/dev/null
    
    # Perform scan based on mode
    case "$mode" in
        "fast")
            echo -e "${WHITE}[${GREEN}*${WHITE}] ${GREEN}Running fast scan...${NC}"
            extract_emails "$text_file" "emails.txt"
            extract_phones "$text_file" "phones.txt"
            extract_links "$text_file" "links.txt"
            extract_metadata "$html_file" "metadata.txt"
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
        "meta")
            echo -e "${WHITE}[${GREEN}*${WHITE}] ${GREEN}Running metadata scan...${NC}"
            extract_metadata "$html_file" "metadata.txt"
            ;;
        *)
            echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Unknown scan mode${NC}"
            ;;
    esac
    
    # Cleanup temp files
    rm -f "$html_file" "$text_file" 2>/dev/null
    
    return 0
}

save_results() {
    local folder_name="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    if [ -z "$folder_name" ]; then
        folder_name="xtra_results_${timestamp}"
    fi
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Saving results to: ${folder_name}${NC}"
    
    mkdir -p "$folder_name" 2>/dev/null
    
    # Move result files
    for file in emails.txt phones.txt links.txt metadata.txt 2>/dev/null; do
        if [ -f "$file" ]; then
            mv "$file" "$folder_name/" 2>/dev/null
        fi
    done
    
    # Create simple report
    cat > "${folder_name}/report.txt" 2>/dev/null << EOF
XTRA Scan Report
================
Date: $(date)
Target: $TARGET_URL
Mode: $SCAN_MODE

Summary:
- Emails: $(wc -l < "${folder_name}/emails.txt" 2>/dev/null || echo 0)
- Phone Numbers: $(wc -l < "${folder_name}/phones.txt" 2>/dev/null || echo 0)
- Links: $(wc -l < "${folder_name}/links.txt" 2>/dev/null || echo 0)

Generated by XTRA v${VERSION}
EOF
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Results saved successfully${NC}"
}

show_summary() {
    echo -e "\n${CYAN}=== SCAN SUMMARY ===${NC}"
    
    local total=0
    
    if [ -f "emails.txt" ]; then
        local email_count=$(wc -l < "emails.txt" 2>/dev/null | tr -d ' ' || echo 0)
        echo -e "${WHITE}📧 Emails: ${GREEN}${email_count}${NC}"
        total=$((total + email_count))
    fi
    
    if [ -f "phones.txt" ]; then
        local phone_count=$(wc -l < "phones.txt" 2>/dev/null | tr -d ' ' || echo 0)
        echo -e "${WHITE} Phone Numbers: ${GREEN}${phone_count}${NC}"
        total=$((total + phone_count))
    fi
    
    if [ -f "links.txt" ]; then
        local link_count=$(wc -l < "links.txt" 2>/dev/null | tr -d ' ' || echo 0)
        echo -e "${WHITE} Links: ${GREEN}${link_count}${NC}"
        total=$((total + link_count))
    fi
    
    echo -e "${WHITE} Total data points: ${YELLOW}${total}${NC}"
}

interactive_mode() {
    display_banner
    check_dependencies
    check_internet || exit 1
    
    echo -e "${CYAN}=== TARGET SELECTION ===${NC}"
    read -p "$(echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Enter target URL: ${NC}")" url_input
    
    TARGET_URL=$(validate_url "$url_input")
    if [ $? -ne 0 ]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Invalid URL format${NC}"
        echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Example: example.com or https://example.com${NC}"
        exit 1
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Target: ${TARGET_URL}${NC}"
    
    echo -e "\n${CYAN}=== SCAN MODES ===${NC}"
    echo -e "${WHITE}1. ${GREEN}Fast Scan${WHITE} (Emails, Phones, Links, Metadata)"
    echo -e "${WHITE}2. ${YELLOW}Custom Scan${WHITE} (Choose what to extract)"
    echo -e "${WHITE}3. ${PURPLE}Metadata Only${WHITE}"
    echo -e "${WHITE}4. ${RED}Exit${NC}"
    
    read -p "$(echo -e "\n${WHITE}[${YELLOW}?${WHITE}] ${YELLOW}Select mode (1-4): ${NC}")" mode_choice
    
    case $mode_choice in
        1) 
            SCAN_MODE="fast"
            perform_scan "fast" "$TARGET_URL"
            ;;
        2) 
            SCAN_MODE="custom"
            perform_scan "custom" "$TARGET_URL"
            ;;
        3) 
            SCAN_MODE="meta"
            perform_scan "meta" "$TARGET_URL"
            ;;
        4) 
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Exiting...${NC}"
            exit 0
            ;;
        *) 
            echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Invalid choice${NC}"
            exit 1
            ;;
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
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Files: emails.txt, phones.txt, links.txt, metadata.txt${NC}"
        fi
    fi
    
    echo -e "\n${GREEN} Scan completed!${NC}"
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
            -c|--custom)
                mode="custom"
                shift
                ;;
            -m|--meta)
                mode="meta"
                shift
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [ -z "$TARGET_URL" ]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}No target URL specified. Use -u URL${NC}"
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
  -c, --custom       Custom scan (choose data types)
  -m, --meta         Metadata only
  -o, --output DIR   Output directory
  -h, --help         Show this help

${YELLOW}Examples:${NC}
  $0 -u https://example.com -f
  $0 --url example.com --fast --output ./results
  $0 -u https://site.com -m

${YELLOW}Interactive Mode:${NC}
  $0  (run without arguments)

${RED}Exploit Lab | XTRA v${VERSION} | 2025${NC}
EOF
}

# Cleanup function
cleanup() {
    rm -f .xtra_temp_* .xtra_text_* 2>/dev/null
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Main execution
if [[ $# -eq 0 ]]; then
    interactive_mode
else
    cli_mode "$@"
fi

exit 0

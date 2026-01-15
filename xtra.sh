#!/bin/bash

# ANSI Color Codes
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
SCAN_MODE=""
TARGET_URL=""

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
            pkg update -y && pkg install -y "${missing[@]}" || {
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Installation failed${NC}"
                return 1
            }
        elif command -v apt-get &> /dev/null; then
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Installing for Debian/Ubuntu...${NC}"
            sudo apt-get update && sudo apt-get install -y "${missing[@]}" || {
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Installation failed${NC}"
                return 1
            }
        elif command -v yum &> /dev/null; then
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Installing for RHEL/CentOS...${NC}"
            sudo yum install -y "${missing[@]}" || {
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Installation failed${NC}"
                return 1
            }
        elif command -v pacman &> /dev/null; then
            echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Installing for Arch...${NC}"
            sudo pacman -Sy --noconfirm "${missing[@]}" || {
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Installation failed${NC}"
                return 1
            }
        else
            echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Please install manually: ${missing[*]}${NC}"
            return 1
        fi
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Dependencies OK${NC}"
    return 0
}

check_internet() {
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Checking internet...${NC}"
    
    if curl -s --connect-timeout 3 --max-time 5 https://google.com > /dev/null 2>&1; then
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
    
    # More robust URL validation
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(:[0-9]+)?(/.*)?$ ]]; then
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
    
    # Use curl with proper error handling
    if curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-time $((TIMEOUT * 2)) \
         -w "%{http_code}" "$url" 2>/dev/null > "$output.tmp"; then
        
        # Extract HTTP status code (last line)
        local http_code=$(tail -n1 "$output.tmp")
        
        # Remove status code from output
        head -n -1 "$output.tmp" > "$output" 2>/dev/null
        
        if [ -s "$output" ] && [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            rm -f "$output.tmp" 2>/dev/null
            return 0
        else
            rm -f "$output" "$output.tmp" 2>/dev/null
            return 1
        fi
    else
        rm -f "$output" "$output.tmp" 2>/dev/null
        return 1
    fi
}

extract_emails() {
    local input="$1"
    local output="$2"
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Extracting emails...${NC}"
    
    # Create empty file first
    > "$output"
    
    # Better email pattern
    grep -E -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$input" 2>/dev/null | \
        sort -u > "$output"
    
    local count=0
    if [ -f "$output" ] && [ -s "$output" ]; then
        count=$(wc -l < "$output" 2>/dev/null | awk '{print $1}')
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Found ${count} emails${NC}"
    
    if [ "$count" -gt 0 ] && [ "$count" -lt 10 ]; then
        echo -e "${CYAN}=== EMAILS ===${NC}"
        cat "$output"
        echo ""
    elif [ "$count" -ge 10 ]; then
        echo -e "${CYAN}=== FIRST 5 EMAILS ===${NC}"
        head -5 "$output"
        echo "..."
        echo ""
    fi
}

extract_phones() {
    local input="$1"
    local output="$2"
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Extracting phone numbers...${NC}"
    
    # Create empty file first
    > "$output"
    
    # Try different phone patterns
    grep -E -o '\+[0-9]{1,4}[-\s]?[0-9]{1,14}' "$input" 2>/dev/null >> "$output"
    grep -E -o '\([0-9]{3}\)[-\s]?[0-9]{3}[-\s]?[0-9]{4}' "$input" 2>/dev/null >> "$output"
    grep -E -o '[0-9]{3}[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4}' "$input" 2>/dev/null >> "$output"
    
    # Clean up and deduplicate
    if [ -f "$output" ] && [ -s "$output" ]; then
        sed -i 's/[()]//g; s/\s\+/ /g; s/^[ \t]*//; s/[ \t]*$//' "$output" 2>/dev/null
        sort -u -o "$output" "$output" 2>/dev/null
    fi
    
    local count=0
    if [ -f "$output" ] && [ -s "$output" ]; then
        count=$(wc -l < "$output" 2>/dev/null | awk '{print $1}')
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Found ${count} phone numbers${NC}"
    
    if [ "$count" -gt 0 ] && [ "$count" -lt 10 ]; then
        echo -e "${CYAN}=== PHONE NUMBERS ===${NC}"
        cat "$output"
        echo ""
    elif [ "$count" -ge 10 ]; then
        echo -e "${CYAN}=== FIRST 5 PHONE NUMBERS ===${NC}"
        head -5 "$output"
        echo "..."
        echo ""
    fi
}

extract_links() {
    local input="$1"
    local output="$2"
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Extracting links...${NC}"
    
    # Simple URL extraction
    grep -E -o 'https?://[^"'"'"'<>()\s]+' "$input" 2>/dev/null | \
        sort -u > "$output"
    
    local count=0
    if [ -f "$output" ] && [ -s "$output" ]; then
        count=$(wc -l < "$output" 2>/dev/null | awk '{print $1}')
    fi
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Found ${count} links${NC}"
    
    # Show first few links
    if [ "$count" -gt 0 ] && [ "$count" -lt 5 ]; then
        echo -e "${CYAN}=== LINKS ===${NC}"
        head -5 "$output"
        echo ""
    elif [ "$count" -ge 5 ]; then
        echo -e "${CYAN}=== FIRST 5 LINKS ===${NC}"
        head -5 "$output"
        echo "..."
        echo ""
    fi
}

extract_metadata() {
    local input="$1"
    local output="$2"
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Extracting metadata...${NC}"
    
    # Initialize output file
    echo "=== PAGE METADATA ===" > "$output"
    
    # Title
    echo -e "\n=== TITLE ===" >> "$output"
    grep -i '<title>' "$input" 2>/dev/null | head -1 | sed -e 's/<[^>]*>//g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' >> "$output"
    
    # Meta description
    echo -e "\n=== META DESCRIPTION ===" >> "$output"
    grep -i 'meta.*name.*description' "$input" 2>/dev/null | head -3 | sed 's/^[[:space:]]*//' >> "$output"
    
    # Keywords
    echo -e "\n=== META KEYWORDS ===" >> "$output"
    grep -i 'meta.*name.*keywords' "$input" 2>/dev/null | head -2 | sed 's/^[[:space:]]*//' >> "$output"
    
    # Viewport
    echo -e "\n=== VIEWPORT ===" >> "$output"
    grep -i 'meta.*name.*viewport' "$input" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' >> "$output"
    
    # Charset
    echo -e "\n=== CHARSET ===" >> "$output"
    grep -i 'meta.*charset' "$input" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' >> "$output"
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Metadata extracted${NC}"
}

perform_scan() {
    local mode="$1"
    local url="$2"
    
    # Create temp files with random names to avoid collisions
    local html_file=".xtra_temp_${RANDOM}_$$.html"
    local text_file=".xtra_text_${RANDOM}_$$.txt"
    
    # Cleanup function for this scope
    cleanup_local() {
        rm -f "$html_file" "$text_file" 2>/dev/null
    }
    
    # Set trap for cleanup
    trap cleanup_local EXIT
    
    # Fetch the page
    if ! fetch_page "$url" "$html_file"; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Failed to fetch page${NC}"
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
            return 1
            ;;
    esac
    
    return 0
}

save_results() {
    local folder_name="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    if [ -z "$folder_name" ]; then
        folder_name="xtra_results_${timestamp}"
    fi
    
    echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Saving results to: ${folder_name}${NC}"
    
    mkdir -p "$folder_name" 2>/dev/null || {
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Failed to create directory${NC}"
        return 1
    }
    
    # Move result files if they exist
    for file in emails.txt phones.txt links.txt metadata.txt; do
        if [ -f "$file" ] && [ -s "$file" ]; then
            mv "$file" "$folder_name/" 2>/dev/null || cp "$file" "$folder_name/" 2>/dev/null
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
- Emails: $(wc -l < "${folder_name}/emails.txt" 2>/dev/null | awk '{print $1}' || echo 0)
- Phone Numbers: $(wc -l < "${folder_name}/phones.txt" 2>/dev/null | awk '{print $1}' || echo 0)
- Links: $(wc -l < "${folder_name}/links.txt" 2>/dev/null | awk '{print $1}' || echo 0)

Generated by XTRA v${VERSION}
EOF
    
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Results saved to: ${folder_name}${NC}"
}

show_summary() {
    echo -e "\n${CYAN}=== SCAN SUMMARY ===${NC}"
    
    local total=0
    
    if [ -f "emails.txt" ] && [ -s "emails.txt" ]; then
        local email_count=$(wc -l < "emails.txt" 2>/dev/null | awk '{print $1}' || echo 0)
        echo -e "${WHITE}📧 Emails: ${GREEN}${email_count}${NC}"
        total=$((total + email_count))
    else
        echo -e "${WHITE}📧 Emails: ${RED}0${NC}"
    fi
    
    if [ -f "phones.txt" ] && [ -s "phones.txt" ]; then
        local phone_count=$(wc -l < "phones.txt" 2>/dev/null | awk '{print $1}' || echo 0)
        echo -e "${WHITE}📞 Phone Numbers: ${GREEN}${phone_count}${NC}"
        total=$((total + phone_count))
    else
        echo -e "${WHITE}📞 Phone Numbers: ${RED}0${NC}"
    fi
    
    if [ -f "links.txt" ] && [ -s "links.txt" ]; then
        local link_count=$(wc -l < "links.txt" 2>/dev/null | awk '{print $1}' || echo 0)
        echo -e "${WHITE}🔗 Links: ${GREEN}${link_count}${NC}"
        total=$((total + link_count))
    else
        echo -e "${WHITE}🔗 Links: ${RED}0${NC}"
    fi
    
    echo -e "${WHITE}📊 Total data points: ${YELLOW}${total}${NC}"
}

interactive_mode() {
    display_banner
    
    if ! check_dependencies; then
        exit 1
    fi
    
    if ! check_internet; then
        echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Continuing offline...${NC}"
    fi
    
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
    else
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Scan failed${NC}"
        exit 1
    fi
    
    echo -e "\n${GREEN}✅ Scan completed!${NC}"
}

cli_mode() {
    local mode="fast"
    local output_dir=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                if [ -z "$2" ]; then
                    echo -e "${WHITE}[${RED}!${WHITE}] ${RED}URL argument missing${NC}"
                    exit 1
                fi
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
                if [ -z "$2" ]; then
                    echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Output directory argument missing${NC}"
                    exit 1
                fi
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
    
    display_banner
    
    if ! check_dependencies; then
        exit 1
    fi
    
    if ! check_internet; then
        echo -e "${WHITE}[${YELLOW}*${WHITE}] ${YELLOW}Continuing offline...${NC}"
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
    else
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Scan failed${NC}"
        exit 1
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

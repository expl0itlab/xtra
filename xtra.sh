#!/bin/bash

a1() { echo -e "\033[1;91m$1\033[0m"; }; a2() { echo -e "\033[1;92m$1\033[0m"; }; a3() { echo -e "\033[1;93m$1\033[0m"; }
a4() { echo -e "\033[1;94m$1\033[0m"; }; a5() { echo -e "\033[1;96m$1\033[0m"; }; a6() { echo -e "\033[1;97m$1\033[0m"; }
b1="XTRA"; b2="2.0"; b3="/tmp/.$$_xtra"; b4=".xtra_log"; b5="Mozilla/5.0"; b6=30; b7=3

[ ! -d "$b3" ] && mkdir -p "$b3"
trap "rm -rf $b3 2>/dev/null; rm -f .tmp_*.html 2>/dev/null" EXIT INT

c1() {
    local d1=$1; local d2=$2; local d3=$(date '+%H:%M:%S')
    echo -e "[$d3] [$d1] $d2" >> "$b4"
    case $d1 in
        "I") a6 "[+] $d2";; "W") a3 "[!] $d2";; "E") a1 "[X] $d2";; "D") a4 "[*] $d2";;
    esac
}

c2() {
    clear
    echo -e "\033[1;96m"
cat << "EOF"
██╗  ██╗ ████████╗ ██████╗       █████╗
╚██╗██╔╝╚══██╔══╝  ██╔══██╗    ██╔══██╗
 ╚███╔╝     ██║     ██████╔╝    ███████║
 ██╔██╗     ██║     ██╔══██╗    ██╔══██║
██╔╝ ██╗    ██║     ██║   ██║   ██║   ██║
╚═╝  ╚═╝    ╚═╝     ╚═╝   ╚═╝   ╚═╝   ╚═╝
                                             
EOF
    echo -e "\033[0m"
    a3 "↪ XTRA Web Scraper v$b2"
    a4 "↪ ExploitLab | By Tremor\n"
}

c3() {
    c1 "I" "Checking system..."
    local e1=("curl" "wget" "grep" "sed" "awk")
    local e2=()
    for e3 in "${e1[@]}"; do
        command -v "$e3" &>/dev/null || e2+=("$e3")
    done
    [ ${#e2[@]} -eq 0 ] && return 0
    c1 "W" "Missing: ${e2[*]}"
    if [ -d "/data/data/com.termux/files/usr" ]; then
        pkg update -y && for e3 in "${e2[@]}"; do pkg install "$e3" -y; done
    else
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y "${e2[@]}"
        elif command -v yum &>/dev/null; then
            sudo yum install -y "${e2[@]}"
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm "${e2[@]}"
        else
            c1 "E" "Install manually: ${e2[*]}"
            return 1
        fi
    fi
    c1 "I" "Dependencies installed"
    return 0
}

c4() {
    for i in {1..3}; do
        curl -s --connect-timeout 5 http://connectivitycheck.gstatic.com/generate_204 &>/dev/null && {
            c1 "I" "Connection OK"
            return 0
        }
        sleep 1
    done
    c1 "E" "No connection"
    return 1
}

c5() {
    local f1="$1"
    [[ ! "$f1" =~ ^https?:// ]] && f1="http://$f1"
    local f2='^https?://([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})(:[0-9]+)?(/.*)?$'
    [[ "$f1" =~ $f2 ]] && echo "$f1" && return 0
    return 1
}

c6() {
    local g1="$1"; local g2="$2"; local g3=0
    while [ $g3 -lt $b7 ]; do
        if curl -s -L -A "$b5" --connect-timeout $b6 --max-time $((b6 * 2)) \
           -H "Accept: text/html" -H "DNT: 1" "$g1" > "$g2"; then
            return 0
        fi
        g3=$((g3 + 1)); sleep 2
    done
    return 1
}

d1() {
    local h1="$1"; local h2="$2"; > "$h2"
    local h3=('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
    for h4 in "${h3[@]}"; do
        grep -i -E -o "$h4" "$h1" | sed 's/\[at\]/@/g; s/\[dot\]/./g' | sort -u >> "$h2"
    done
    sed -i '/^@/d; /\.@/d; /@\./d' "$h2"
    wc -l < "$h2" 2>/dev/null | tr -d ' '
}

d2() {
    local i1="$1"; local i2="$2"; > "$i2"
    local i3=('\+[0-9]{1,3}[-\s]?[0-9]{1,14}' '\([0-9]{3}\)[-\s]?[0-9]{3}[-\s]?[0-9]{4}')
    for i4 in "${i3[@]}"; do
        grep -E -o "$i4" "$i1" >> "$i2"
    done
    sed -i 's/[()]//g; s/\s/-/g' "$i2"
    sort -u -o "$i2" "$i2"
    wc -l < "$i2" 2>/dev/null | tr -d ' '
}

d3() {
    local j1="$1"; local j2="$2"
    grep -E -o 'https?://[^"'\''<>()\s]+' "$j1" | sort -u > "$j2"
    local j3=('facebook\.com' 'twitter\.com' 'linkedin\.com' 'instagram\.com' 'youtube\.com')
    > "${j2}.social"; > "${j2}.api"; > "${j2}.files"
    local j4=$(echo "$XTRA_URL" | sed -E 's|^https?://([^/]+).*|\1|')
    while IFS= read -r j5; do
        for j6 in "${j3[@]}"; do
            [[ "$j5" =~ $j6 ]] && { echo "$j5" >> "${j2}.social"; break; }
        done
        [[ "$j5" =~ \.pdf$ ]] && echo "$j5" >> "${j2}.files"
        [[ "$j5" =~ api\. ]] && echo "$j5" >> "${j2}.api"
        [[ "$j5" =~ $j4 ]] && echo "$j5" >> "${j2}.internal" || echo "$j5" >> "${j2}.external"
    done < "$j2"
    wc -l < "$j2" 2>/dev/null | tr -d ' '
}

d4() {
    local k1="$1"; local k2="$2"
    echo "=== METADATA ===" > "$k2"
    grep -i -o '<title>[^<]*</title>' "$k1" | sed 's/<[^>]*>//g' >> "$k2"
    grep -i '<meta' "$k1" | head -10 >> "$k2"
    echo -e "\n=== HEADINGS ===" >> "$k2"
    grep -E '<h[1-6][^>]*>' "$k1" | sed 's/<[^>]*>//g' | head -5 >> "$k2"
}

d5() {
    local l1="$1"; local l2="${2:-1}"
    [ "$l2" -gt 2 ] && return
    local l3="${b3}/depth_${l2}.html"
    c6 "$l1" "$l3" && {
        grep -E -o 'href="[^"]+"' "$l3" | sed 's/href="//; s/"//' | \
        grep -E "^https?://" | grep "$(echo "$l1" | sed -E 's|^https?://([^/]+).*|\1|')" | \
        head -2 | while read -r l4; do
            d5 "$l4" $((l2 + 1))
        done
    }
}

d6() {
    local m1="$1"; local m2=$(date '+%Y%m%d_%H%M%S')
    [ -z "$m1" ] && m1="xtra_results_${m2}"
    mkdir -p "$m1"
    for m3 in *.txt *.html 2>/dev/null; do
        [ -f "$m3" ] && [[ "$m3" != "$b4" ]] && mv "$m3" "$m1/" 2>/dev/null
    done
    cat > "${m1}/report.txt" << EOF
XTRA Report - $(date)
Target: $XTRA_URL
Entries: $(find "$m1" -name "*.txt" -exec cat {} \; | wc -l 2>/dev/null)
Generated by: $b1 v$b2
EOF
    c1 "I" "Saved to: $m1"
    echo -e "\n$(a5 '=== FILES ===')"
    find "$m1" -type f -name "*.txt" | while read -r m4; do
        local m5=$(wc -l < "$m4" 2>/dev/null | tr -d ' ')
        a6 "• $(a3 $(basename "$m4")) - $(a2 $m5) items"
    done
}

c7() {
    echo -e "\n$(a5 '=== MODES ===')"
    a6 "1. $(a2 'Fast') - All data"
    a6 "2. $(a3 'Pick') - Choose types"
    a6 "3. $(a4 'Deep') - Recursive"
    a6 "4. $(a5 'Meta') - Page info"
    a6 "5. $(a1 'API') - Endpoints"
    a6 "6. $(a6 'Exit')"
    read -p $'\n'"$(a6 '[?] Choose (1-6): ')" n1
    case $n1 in
        1) FAST_M=1;; 2) PICK_M=1;; 3) DEEP_M=1;; 4) META_M=1;; 5) API_M=1;; 6) exit;;
        *) c1 "E" "Bad choice"; c7;;
    esac
}

main_x() {
    c2
    [ "$EUID" -eq 0 ] && {
        read -p "$(a6 '[!] Root detected. Continue? (y/n): ')" -n 1 -r; echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    }
    c3 || exit 1
    c4 || exit 1
    echo -e "\n$(a5 '=== TARGET ===')"
    read -p "$(a6 '[+] Enter URL/domain: ')" u1
    XTRA_URL=$(c5 "$u1") || { c1 "E" "Bad URL"; exit 1; }
    c1 "I" "Target: $XTRA_URL"
    c7
    c1 "I" "Fetching..."
    c6 "$XTRA_URL" "page.html" || { c1 "E" "Fetch failed"; exit 1; }
    sed 's/<[^>]*>//g; s/&[^;]*;//g' "page.html" > "page.txt"
    if [ "$FAST_M" = 1 ]; then
        c1 "I" "Fast scan..."
        o1=$(d1 "page.txt" "emails.txt")
        o2=$(d2 "page.txt" "phones.txt")
        o3=$(d3 "page.txt" "links.txt")
        d4 "page.html" "meta.txt"
        echo -e "\n$(a5 '=== RESULTS ===')"
        a6 "Emails: $(a2 $o1)"
        a6 "Phones: $(a2 $o2)"
        a6 "Links: $(a2 $o3)"
    elif [ "$PICK_M" = 1 ]; then
        read -p "$(a6 'Get emails? (y/n): ')" -n 1 -r; echo
        [[ $REPLY =~ ^[Yy]$ ]] && d1 "page.txt" "emails.txt"
        read -p "$(a6 'Get phones? (y/n): ')" -n 1 -r; echo
        [[ $REPLY =~ ^[Yy]$ ]] && d2 "page.txt" "phones.txt"
        read -p "$(a6 'Get links? (y/n): ')" -n 1 -r; echo
        [[ $REPLY =~ ^[Yy]$ ]] && d3 "page.txt" "links.txt"
    elif [ "$DEEP_M" = 1 ]; then
        c1 "I" "Deep scan..."
        d5 "$XTRA_URL"
        find "$b3" -name "*.html" -exec cat {} \; > "deep.html"
        d1 "deep.html" "emails_d.txt"
        d2 "deep.html" "phones_d.txt"
        d3 "deep.html" "links_d.txt"
    elif [ "$META_M" = 1 ]; then
        d4 "page.html" "metadata.txt"
        c1 "I" "Metadata saved"
    elif [ "$API_M" = 1 ]; then
        d3 "page.txt" "all_links.txt"
        [ -f "all_links.txt.api" ] && cp "all_links.txt.api" "api.txt"
    fi
    echo -e "\n$(a5 '=== SAVE ===')"
    read -p "$(a6 'Save to folder? (y/n): ')" -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "$(a6 'Folder name (enter for auto): ')" p1
        d6 "$p1"
    else
        a3 "Files in current dir"
    fi
    echo -e "\n$(a5 '=== STATS ===')"
    for q1 in *.txt 2>/dev/null; do
        [ -f "$q1" ] && {
            q2=$(wc -l < "$q1" 2>/dev/null | tr -d ' ')
            a6 "$q1: $(a2 $q2)"
        }
    done
    echo -e "\n$(a2 'Done!')"
    c1 "I" "Completed for $XTRA_URL"
}

help_x() {
    c2
    cat << EOF
$(a5 'XTRA v$b2 - ExploitLab')$(a6 '

Usage:')
  $0 [options]

$(a6 'Options:')
  -u <url>      Target URL
  -o <dir>      Output folder
  -f            Fast scan
  -d            Deep scan
  -m            Metadata only
  -a            Find APIs
  -h            This help

$(a6 'Examples:')
  $0 -u example.com -f
  $0 --url target.com -d
  $0 -u site.com -a -o out

$(a1 'ExploitLab | XTRA Tool')
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url) XTRA_URL=$(c5 "$2"); shift 2;;
        -o|--output) OUT_DIR="$2"; shift 2;;
        -f|--fast) FAST_M=1; shift;;
        -d|--deep) DEEP_M=1; shift;;
        -m|--meta) META_M=1; shift;;
        -a|--api) API_M=1; shift;;
        -h|--help) help_x; exit 0;;
        *) shift;;
    esac
done

[ -z "$1" ] && main_x || help_x

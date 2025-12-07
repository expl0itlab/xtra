# XTRA v1.0 - Advanced Web Scraper

![XTRA](https://img.shields.io/badge/XTRA-ExploitLab-blue)
![Version](https://img.shields.io/badge/Version-1.0-red)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Termux-orange)
![Year](https://img.shields.io/badge/Year-2025-brightgreen)

**XTRA** is a powerful web scraping tool from **Exploit Lab** - designed for authorized security testing, reconnaissance, and data gathering operations.

##  Features

### **Core Capabilities**
- **Email Extraction** - Extract email addresses from web pages

- **Phone Number Harvesting** - Find phone numbers in various formats

- **Link Discovery** - Extract and display URLs from web pages

- **Metadata Analysis** - Extract page titles and meta information

### **Scan Modes**
- **Fast Scan** - Extract emails, phones, links, and metadata

- **Custom Scan** - Choose specific data types to extract

- **Metadata Only** - Extract only page metadata

### **Professional Output**
- **Organized Results** - Results saved in timestamped folders

- **Summary Reports** - Detailed scan reports

- **Clean Operations** - Automatic cleanup of temporary files

## 📦 Installation

### **Quick Installation**
```bash
# Clone the repository
git clone https://github.com/exploitarium/xtra.git
cd xtra
chmod +x xtra.sh
```
One-Line Installation
```bash
curl -sL https://raw.githubusercontent.com/exploitarium/xtra/main/xtra.sh -o xtra.sh && chmod +x xtra.sh
```
Termux Installation
```bash
pkg install git curl -y
git clone https://github.com/exploitarium/xtra.git
cd xtra
chmod +x xtra.sh
```
 Usage
Interactive Mode (Recommended)
```bash
./xtra.sh
```
Follow the prompts to configure your scan operation.

Command Line Mode
```bash
# Fast scan with all data types
./xtra.sh -u https://example.com -f

# Custom scan (choose what to extract)
./xtra.sh -u example.com -c

# Metadata only
./xtra.sh -u example.com -m

# With custom output directory
./xtra.sh -u example.com -f -o ./results
```
Command Line Options
```Option	Short	Description	Example
--url	-u	Target URL to scan	-u https://example.com


--fast	-f	Fast scan (all data types)	-u site.com -f


--custom	-c	Custom scan (choose data types)	-u site.com -c


--meta	-m	Metadata only	-m


--output	-o	Custom output directory	-o ./results


--help	-h	Show help information	-h
```
## 📋 Operation Modes
1. Fast Scan (Default)
```bash
./xtra.sh -u example.com -f
```
Extracts emails, phone numbers, links, and metadata in one operation.

2. Custom Scan
```bash
./xtra.sh -u example.com -c
# Or interactive mode: choose option 2
```
Allows you to select which data types to extract.

3. Metadata Scan
```bash
./xtra.sh -u example.com -m
```
Extracts only page metadata (title, meta tags).

📁 Output Structure
```text
xtra_results_20250107_153045/
├── emails.txt        # Extracted email addresses
├── phones.txt        # Phone numbers found
├── links.txt         # URLs discovered
├── metadata.txt      # Page metadata
└── report.txt        # Scan summary report
```

🛡️ **Security Features**
Automatic Cleanup - Temporary files removed after scan

Custom User-Agent - Uses XTRA-specific agent

Error Handling - Graceful failure recovery

Session Management - Clean operation tracking

⚙️ **Technical Specifications**
System Requirements
Minimum: Linux/Unix environment with bash

Recommended: 256MB RAM, 50MB disk space

Network: Internet connectivity

Dependencies
```bash
# Core dependencies (auto-installed)
- curl     # HTTP requests
- grep     # Pattern matching

# Optional
- sed      # Text processing
- awk      # Advanced text processing
```

**Platform Support**
Linux (Ubuntu, Debian, Fedora, Arch, etc.)

Termux (Android)

macOS (with bash)

WSL (Windows Subsystem for Linux)

Configuration
Environment Variables
```bash
# Set custom parameters
export XTRA_USER_AGENT="CustomAgent/1.0"
export XTRA_TIMEOUT=30
```

📊 Usage Examples
Basic Scan
```bash
./xtra.sh -u https://example.com -f
```
Save to Specific Directory
```bash
./xtra.sh -u https://target.com -f -o ./security_scan
```
Interactive Mode
```bash
./xtra.sh
# Follow the prompts
```

## Legal & Ethical Considerations⚠️
IMPORTANT DISCLAIMER

### XTRA v1.0 is developed for:

**Authorized Activities:**

Security testing with permission

Educational purposes

Bug bounty programs (in scope)

Legal reconnaissance

---
**Prohibited Activities:**

Unauthorized scanning

Terms of Service violations

Illegal activities

Harassment or spam

**Always:**

Obtain proper authorization

Respect website policies

Follow applicable laws

Use data responsibly

🐛 Troubleshooting
Common Issues
Missing dependencies:

```bash
# Linux
sudo apt-get install curl grep
```
```# Termux
pkg install curl grep
```
Permission errors:

```bash
chmod +x xtra.sh
```
Network issues:

```bash
# Test connectivity
curl -I https://google.com
```
Debug Mode
```bash
# Run with debug output
bash -x xtra.sh -u example.com -f
```

Contributing
Fork the repository

Create feature branch

Commit changes

Push and create Pull Request

### 📝 License
XTRA v1.0 is released under the MIT License - see LICENSE file.


---
⭐ Support
If XTRA helps your work:

⭐ Star the repository

🔄 Share with colleagues

🐛 Report issues

💡 Suggest improvements

---
Developed by Exploit Lab | Tremor

Security Reminder: Always use tools ethically and with proper authorization.

XTRA v1.0 | December 2025 | Exploit Lab

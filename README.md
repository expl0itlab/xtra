# XTRA v1.0 - Advanced Web Scraper

![XTRA](https://img.shields.io/badge/XTRA-Exploitarium-blue)
![Version](https://img.shields.io/badge/Version-1.0-red)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Termux-orange)
![Year](https://img.shields.io/badge/Year-2025-brightgreen)

**XTRA** is the inaugural web scraping tool from **Exploitarium** - a powerful, stealthy reconnaissance utility designed for authorized security testing and data gathering operations.

## Features

### **Core Capabilities**
- **Email Extraction** - Advanced pattern recognition (including obfuscated formats)
- **Phone Number Harvesting** - International and local formats
- **Link Discovery** - Intelligent URL categorization
- **Metadata Analysis** - Comprehensive page information extraction
- **API Endpoint Detection** - REST, GraphQL, and web service discovery
- **Social Media Mapping** - Platform-specific link identification

### **Advanced Features**
- **Multi-Mode Scanning**
  - Quick Scan (Comprehensive data collection)
  - Selective Scan (Custom data type selection)
  - Deep Scan (Recursive, depth-limited crawling)
  - Metadata-Only Mode
  - API-Focused Scan
  
- **Smart Categorization**
  - Social media platforms
  - API endpoints and services
  - File resources (PDF, DOC, ZIP, etc.)
  - Internal vs External domain classification

- **Professional Output**
  - Structured folder organization
  - Detailed summary reports
  - Session activity logging
  - Statistics and analytics

##  Installation

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

Follow the intuitive prompts to configure your reconnaissance operation.

Command Line Mode

```bash
# Comprehensive quick scan
./xtra.sh -u https://target-domain.com -f

# Deep recursive analysis
./xtra.sh --url example.com --deep

# API endpoint discovery
./xtra.sh -u api-service.com -a -o scan_results

# Metadata extraction
./xtra.sh -u example.com -m

# Custom output location
./xtra.sh -u target.com -f -o ./investigation
```

Command Line Options

Option Short Description Example
--url -u Target URL for reconnaissance -u https://example.com
--output -o Custom output directory path -o ./results
--fast -f Execute comprehensive quick scan -u site.com -f
--deep -d Enable recursive deep scanning --deep
--meta -m Extract metadata only -m
--api -a Focus on API endpoint discovery -a
--help -h Display help information -h

Operation Modes

1. Quick Scan (Default)

```bash
./xtra.sh -u example.com
```

Executes a full-spectrum data collection including emails, phone numbers, links, and metadata.

2. Selective Scan

```bash
./xtra.sh -u example.com
# Choose option 2 in the interactive menu
```

Allows manual selection of specific data types for targeted extraction.

3. Deep Scan

```bash
./xtra.sh -u example.com -d
```

Performs recursive crawling up to 2 levels deep for thorough reconnaissance.

4. Metadata Scan

```bash
./xtra.sh -u example.com -m
```

Extracts only structural page information including titles, meta tags, and headers.

5. API Scan

```bash
./xtra.sh -u example.com -a
```

Specialized mode for identifying API endpoints, web services, and data interfaces.

📁 Output Structure

```
xtra_results_20250107_153045/
├── emails.txt               # Extracted email addresses
├── phones.txt               # Phone number collection
├── links.txt                # Complete URL discovery
├── links.txt.social         # Social media platform links
├── links.txt.api            # API and service endpoints
├── links.txt.files          # Downloadable resources
├── links.txt.internal       # Internal domain references
├── links.txt.external       # External domain references
├── metadata.txt             # Page structural metadata
├── report.txt               # Operation summary report
└── .xtra_session.log        # Detailed activity log
```

🛡️ Security & Stealth Features

· Operational Security - Custom User-Agent with timeout management
· Rate Control - Intelligent retry mechanisms with backoff
· Clean Operations - Automatic temporary file cleanup
· Activity Tracking - Comprehensive session logging
· Error Resilience - Graceful failure handling and recovery

⚙️ Technical Specifications

System Requirements

· Minimum: Linux/Unix-like environment
· Recommended: 512MB RAM, 100MB disk space
· Network: Internet connectivity for target access

Dependencies

```bash
# Core dependencies (auto-installed if missing)
- curl     # HTTP/S operations
- grep     # Pattern matching
- sed      # Stream editing
- awk      # Text processing

# Optional dependencies
- wget     # Alternative download method
- html2text # Enhanced HTML parsing
```

Platform Support

· Linux Distributions (Ubuntu, Debian, Fedora, Arch, etc.)


· Termux (Android terminal environment)


· macOS (with Homebrew package manager)


· WSL/WSL2 (Windows Subsystem for Linux)



Configuration & Customization

Environment Configuration

```bash
# Set custom operational parameters
export XTRA_USER_AGENT="ResearchBot/1.0"
export XTRA_TIMEOUT=45
export XTRA_MAX_DEPTH=3
```

Configuration File

Create ~/.xtra_config for persistent settings:

```ini
# XTRA Configuration File
user_agent="Mozilla/5.0 (Research) XTRA/1.0"
timeout=30
max_retries=3
output_base="./xtra_operations"
enable_debug=false
log_level="INFO"
```

Real-World Scenarios

Scenario 1: Security Assessment

```bash
# Comprehensive target reconnaissance
./xtra.sh -u https://target-organization.com -f -o ./security_assessment
```

Collects all exposed contact information and external references for security analysis.

Scenario 2: API Surface Mapping

```bash
# Focused API discovery
./xtra.sh -u https://service-provider.com -a
```

Identifies all API endpoints and web service interfaces for security review.

Scenario 3: Asset Discovery

```bash
# Process multiple targets
for domain in $(cat targets.list); do
    ./xtra.sh -u "https://$domain" -f -o "./scans/$domain"
done
```

Batch processing of multiple targets with organized output structure.

Legal & Ethical Considerations

CRITICAL DISCLAIMER

XTRA v1.0 is developed exclusively for:
Authorized Activities:

· Penetration testing with written permission


· Security research and analysis


· Educational and training purposes


· Bug bounty programs (within scope)


· Legal reconnaissance operations


Prohibited Activities:

· Unauthorized system access


· Terms of Service violations


· Illegal surveillance


· Harassment or spamming


· Any unlawful purposes



Operational Guidelines:

1. Always obtain explicit authorization before scanning
2. Respect robots.txt and website policies
3. Comply with all applicable laws and regulations
4. Maintain ethical standards in all operations
5. Use collected data responsibly and legally

Troubleshooting Guide

Common Operational Issues

Issue: Missing dependencies

```bash
# Linux systems
sudo apt-get update && sudo apt-get install curl grep sed awk

# Termux environment
pkg update && pkg install curl grep sed awk
```

Issue: Permission errors

```bash
# Ensure execution permissions
chmod +x xtra.sh

# Run with appropriate privileges
./xtra.sh
```

Issue: Network connectivity

```bash
# Verify internet access
ping -c 3 google.com

# Test HTTP connectivity
curl -I https://github.com
```

Issue: Output directory conflicts

```bash
# Specify alternative directory
./xtra.sh -u example.com -o new_scan_directory
```

Advanced Diagnostics

```bash
# Enable verbose debugging
XTRA_DEBUG=true ./xtra.sh -u example.com

# View detailed logs
tail -f .xtra_session.log
```

Contributing to XTRA v1.0

As the inaugural release from Exploitarium, we welcome constructive contributions:

Contribution Process

1. Fork the Exploitarium repository
2. Create a feature branch (git checkout -b feature/Enhancement)
3. Implement changes with thorough testing
4. Commit with descriptive messages
5. Push to your fork and submit a Pull Request

Development Standards

· Maintain code obfuscation and operational security


· Add comprehensive error handling


· Include platform compatibility testing


· Update documentation accordingly


· Follow existing architectural patterns



License Information

XTRA v1.0 is released under the MIT License - see the LICENSE file for complete terms and conditions.


Acknowledgments & Credits


Special Thanks to the ethical security professionals and the Exploit Lab Team 


Support & Recognition

If XTRA v1.0 assists in your security operations:

⭐ Star the repository to support development


🔄 Share with authorized security professionals


🐛 Report issues and suggest improvements


💡 Contribute enhancements and features


📢 Promote responsible and ethical usage

---

Developed with precision by Tremor 

Security Reminder: Technical capability necessitates ethical responsibility. Conduct all operations within legal boundaries and with proper authorization.

---

XTRA v1.0 | Initial Release | December 2025 | Exploit Lab 

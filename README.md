# OTT Stream Discoverer

**Discover exactly what your Fire TV, Roku, or Chromecast is streaming — using nothing but network protocols. No apps on the devices required.**

Practical companion to the research paper  
**“A Current Overview of Network Service Discovery Protocols”** (included in this repo).

---

## 🎯 Purpose

This toolkit lets you **passively discover** and **inspect** OTT (Over-The-Top) streaming devices on your local Wi-Fi network using the exact protocols described in the attached PDF:

- SSDP / DIAL (the main focus of the paper)
- mDNS / DNS-SD (Google Cast / Chromecast)
- Bonus aggressive mode: ARP-spoof MITM + live DNS CNAME sniffing on Fire TV

It answers questions like:
- Is Netflix or YouTube running?
- What exact streaming domains is the Fire TV resolving right now?
- Which DIAL apps are installed and in what state?

Perfect for home-lab enthusiasts, smart-home researchers, network tinkerers, and anyone who wants to understand how modern streaming devices actually talk on the wire.

## 📖 Theory (from the attached PDF)

The PDF “A Current Overview of Network Service Discovery Protocols” (written by Fotios Basagiannis, August 2024) explains the 10 most important service discovery protocols in use today. This project focuses on the two most relevant for OTT devices:

1. **SSDP / DIAL** (page 5 of the PDF)  
   Used by Roku, Fire TV, and most smart TVs. Based on UPnP. Devices multicast “M-SEARCH” requests and respond with LOCATION headers pointing to their device description XML. DIAL then exposes an Application-URL for polling app states.

2. **mDNS / DNS-SD** (mentioned throughout the PDF)  
   Used by Google Chromecast (`_googlecast._tcp`). Zero-configuration discovery via multicast DNS.

The scripts implement these protocols exactly as described in the paper — no proprietary APIs, no cloud, no software installed on the target devices.

Full theory → see `A_Current_Overview_of_Network_Service_Discovery_Protocols.pdf` in this repository.

## ✨ Features

- Pure SSDP/DIAL discovery for any DIAL-compatible device (Roku, Fire TV, etc.)
- mDNS Google Cast discovery + DIAL app polling
- Fire TV aggressive mode with optional ARP-spoof MITM + real-time DNS CNAME sniffing (reveals Netflix, Prime, Disney+ CDNs, etc.)
- Clean, modern bash with proper cleanup and error handling
- No external config files required
- Automatic network interface detection
- Graceful restoration of network settings
- Expandable built-in app list

## ⚠️ Legal & Ethical Warning (READ BEFORE USING)

The Fire TV `--mitm` mode performs ARP poisoning.  
**Using this on any network you do not own, or without explicit written permission, is illegal** in most countries (unauthorized access, wire fraud, computer misuse laws).  

Even on your own network it can:
- Trigger router security alerts
- Temporarily disrupt the target device
- Be detected by modern devices using certificate pinning / DoH

**You have been warned.** Use at your own risk. The normal modes (no `--mitm`) are completely passive and safe.

## 📋 Prerequisites

- Linux (Debian/Ubuntu or derivative — tested on 22.04/24.04)
- Root privileges (`sudo`)
- Wireless interface
- Packages (installed automatically on first run if missing):
  ```bash
  apt install net-tools tcpdump dsniff avahi-utils curl mkchromecast adb
🚀 Installation
Bashgit clone https://github.com/yourusername/ott-stream-discoverer.git
cd ott-stream-discoverer

# Make scripts executable
chmod +x *.sh

# (Optional but recommended) Install missing packages
sudo apt update && sudo apt install net-tools tcpdump dsniff avahi-utils curl mkchromecast adb -y
That’s it. No other setup required.
📖 Usage
All commands require sudo.
Bash# Standard DIAL discovery (Roku + Fire TV + any DIAL device)
sudo ./dial-detect.sh

# Google Cast / Chromecast focused discovery
sudo ./mdns-detect.sh

# Fire TV only — safe mode (recommended first)
sudo ./firetv-detect5.sh

# Fire TV with powerful MITM DNS sniffing (dangerous)
sudo ./firetv-detect5.sh --mitm
Output appears directly in the terminal + temporary files under /tmp/ott-discover-* (automatically cleaned up).
🛠 How It Works (Quick Technical Overview)

Network prep — puts interface in promiscuous mode.
Discovery — sends M-SEARCH multicast (SSDP) or uses avahi-browse (mDNS).
Parsing — extracts LOCATION and Application-URL from responses.
App polling — queries every DIAL app in the list and returns <state> (running / stopped / etc.).
Fire TV MITM (optional) — ARP-spoofs gateway, sniffs UDP/53 traffic for CNAME records, then restores everything.

All parsing and URL-encoding is done in pure bash — no external dependencies.
📁 Project Structure
Bashott-stream-discoverer/
├── README.md
├── A_Current_Overview_of_Network_Service_Discovery_Protocols.pdf
├── utils.sh
├── dial-detect.sh
├── mdns-detect.sh
├── firetv-detect5.sh
└── (temporary files created at runtime)
⚠️ Limitations & Known Issues

Works only on Linux (bash + raw sockets).
Modern devices using DoH, QUIC, or encrypted DNS hide some domains.
MITM mode is fragile on networks with ARP inspection or 802.1X.
No IPv6 support (yet).
Parsing can still break if manufacturers radically change XML format (rare).
Requires root — as expected for raw packet operations.

📜 License
MIT License — free to use, modify, and distribute.
The ARP-spoof code remains your responsibility.
👤 Credits
Created by Fotios Basagiannis
Top Rated IT Consultant & Network Protocol Enthusiast
This repository is the practical implementation of the theory paper written for Colton Idle (USA) in August 2024.

Star this repo if you found it useful — it helps other researchers discover it.
Questions or want a Python rewrite? Open an issue.
Made with pure bash, too much coffee, and zero corporate oversight.

<div align="center">

```
 _     _                         _             _ _ _      _____           _
| |   (_)_ __  _   ___  __      / \  _   _  __| (_) |_   |_   _|__   ___ | |
| |   | | '_ \| | | \ \/ /____ / _ \| | | |/ _` | | __|____| |/ _ \ / _ \| |
| |___| | | | | |_| |>  <_____/ ___ \ |_| | (_| | | ||_____| | (_) | (_) | |
|_____|_|_| |_|\__,_/_/\_\   /_/   \_\__,_|\__,_|_|\__|    |_|\___/ \___/|_|
```

# 🛡️ Linux Audit Tool

**A comprehensive Linux security auditing framework that performs 80+ checks across system, network, and port scanning domains — and delivers reports in TXT, PDF, and an interactive HTML dashboard.**

[![Version](https://img.shields.io/badge/version-4.0-blue?style=for-the-badge)](https://github.com/MokshSharma2006)
[![Shell](https://img.shields.io/badge/shell-bash-green?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey?style=for-the-badge&logo=linux)](https://kernel.org)

[Features](#-features) • [Demo](#-demo) • [Installation](#-installation) • [Usage](#-usage) • [Checks](#-audit-checks) • [Output](#-output-formats) • [Requirements](#-requirements) • [Contributing](#-contributing)

</div>

---

## 📌 Overview

**Linux Audit Tool v4.0** is a self-contained Bash script designed for sysadmins, penetration testers, and security engineers who need a fast, dependency-light way to audit the security posture of any Linux system. No agent installation required — just run the script and get a full report.

The tool covers **50 system checks**, **22 network checks**, and **8 port-scanning checks**, automatically collects security metrics, and renders them in a dark-themed, Chart.js-powered HTML dashboard — alongside traditional TXT and PDF outputs.

---

## ✨ Features

- **80+ Security Checks** — user accounts, SSH config, SUID binaries, world-writable files, firewall rules, open ports, kernel hardening, and more
- **Interactive HTML Dashboard** — risk score, KPI cards, radar chart, bar charts, severity breakdown, and a security checklist — all in a single self-contained HTML file
- **Multi-format Output** — choose TXT, PDF, or both at runtime
- **PDF via Python/reportlab** — structured, paginated PDF with cover page, table of contents, and syntax-aware styling; falls back to `cupsfilter`, `vim+ps2pdf`, or `enscript+ps2pdf`
- **Auto-install Missing Tools** — detects and offers to install `nmap`, `lsof`, `auditd`, and other dependencies automatically
- **Distro-aware** — supports Debian/Ubuntu, RHEL/CentOS/Fedora, Arch, and SUSE
- **Privilege-aware** — runs with or without root; identifies checks that require elevated privileges and degrades gracefully
- **Bash Fallback Port Scanner** — uses `/dev/tcp` to scan common ports when `nmap` is unavailable
- **Real-time progress reporting** — colour-coded console output with per-section progress indicators
- **Risk Score Engine** — computes a 0–100 risk score based on critical findings (SSH root login, firewall status, empty passwords, MAC policy, etc.)

---

## 🎬 Demo

```
  ╔═══════════════════════════════════════════════════════════╗
  ║                LINUX SECURITY AUDIT TOOL                  ║
  ║                    Enhanced Version 4.0                   ║
  ╚═══════════════════════════════════════════════════════════╝

Date: Thu Apr 30 12:00:00 UTC 2026
Hostname: myserver

[*] Checking for required audit tools...
[+] All core audit tools are present.

Progress: 20% — System Security Audit
[*] 1.1 - Checking: User Accounts
[*] 1.2 - Checking: Password Hashes
...
[+] HTML dashboard saved: Linux_security_audit_20260430_120000.html
[+] Report saved: Linux_security_audit_20260430_120000.txt

╔════════════════════════════════════════════════════════════════╗
║                    AUDIT COMPLETED SUCCESSFULLY                ║
╚════════════════════════════════════════════════════════════════╝
[+] Results: Linux_security_audit_20260430_120000.txt
[+] Time   : 47s
```

---

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/MokshSharma2006/Linux-Audit-Tool_V4.0.git
cd Linux-Audit-Tool_V4.0

# Make the script executable
chmod +x Linux_Audit_Tool_V4_0.sh
```

No additional installation is needed. The script will prompt you to install any missing audit tools on first run.

---

## 🚀 Usage

### Basic (interactive)

```bash
sudo ./Linux_Audit_Tool_V4_0.sh
```

### Non-interactive with format flag

```bash
# Generate TXT report only
sudo ./Linux_Audit_Tool_V4_0.sh --format txt

# Generate PDF report only
sudo ./Linux_Audit_Tool_V4_0.sh --format pdf

# Generate both TXT and PDF
sudo ./Linux_Audit_Tool_V4_0.sh --format both
```

### All options

```
Usage: ./Linux_Audit_Tool_V4_0.sh [OPTIONS]

Options:
  -h, --help      Show help
  -v, --verbose   Verbose output
  -q, --quiet     Minimal console output
  -f, --format    Output format: txt | pdf | both
```

> **Tip:** Always run with `sudo` for a complete audit. Without root, some checks (shadow file, auditd rules, lsof, etc.) will be skipped or limited.

---

## 🔍 Audit Checks

### 1. System Security Audit (checks 1.1 – 1.50)

| # | Check | Description |
|---|-------|-------------|
| 1.1 | User Accounts | All accounts in `/etc/passwd` |
| 1.2 | Password Hashes | `/etc/shadow` content and expiry info |
| 1.3 | Empty Password Accounts | Accounts with no password — critical risk |
| 1.4 | UID 0 Accounts | Root-equivalent accounts |
| 1.5 | Last Logins | `lastlog` output for every account |
| 1.6 | Currently Logged-in Users | `w` and `who -a` |
| 1.7 | Failed Login Attempts | `lastb` — all recent failures |
| 1.8 | Full Login History | `last -F` complete audit trail |
| 1.9 | Password Aging Policy | `chage` and `/etc/login.defs` settings |
| 1.10 | Sudo Configuration | Full sudoers + drop-in files |
| 1.11 | Groups and Memberships | All groups; sudo/wheel/adm members |
| 1.12 | SSH Server Configuration | Active `sshd_config` directives |
| 1.13 | SSH Root Login Status | `PermitRootLogin` setting |
| 1.14 | SSH Authorized Keys | All `authorized_keys` files on the system |
| 1.15 | SSH Host Keys | Host key files and permissions |
| 1.16 | World-Writable Files | All globally writable files |
| 1.17 | World-Writable Directories | All globally writable directories |
| 1.18 | SUID Files | Binaries running as owner |
| 1.19 | SGID Files | Binaries running as group |
| 1.20 | Unowned Files | Files with missing owner/group |
| 1.21 | Hidden Files in Home Dirs | Dotfiles in `/home` and `/root` |
| 1.22 | Critical Directory Permissions | `/tmp`, `/etc`, `/root`, `/boot`, etc. |
| 1.23 | Critical File Permissions | `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`, etc. |
| 1.24 | Sticky Bit on Temp Dirs | Verify `/tmp` and `/var/tmp` sticky bit |
| 1.25 | Core Dump Configuration | `fs.suid_dumpable` and `kernel.core_pattern` |
| 1.26 | ASLR Status | `kernel.randomize_va_space` value |
| 1.27 | All Kernel Security Params | Security-relevant `sysctl` values |
| 1.28 | Loaded Kernel Modules | `lsmod` output |
| 1.29 | Recent Kernel Messages | Last 100 lines of `dmesg` |
| 1.30 | OS and Kernel Details | `uname -a`, `/proc/version`, `lsb_release` |
| 1.31 | Audit Daemon Status | `auditd` systemd status |
| 1.32 | Audit Rules | Active `auditctl -l` rules |
| 1.33 | System Log Directory | `/var/log/` contents and permissions |
| 1.34 | Logging Daemon Status | `rsyslog`, `syslog`, `systemd-journald` |
| 1.35 | Authentication Log | Full `/var/log/auth.log` or `/var/log/secure` |
| 1.36 | Recent Syslog Entries | Last 200 syslog lines |
| 1.37 | Installed Packages | `dpkg`, `rpm`, or `pacman` package list |
| 1.38 | Pending Security Updates | Available security patches |
| 1.39 | Recent Package Changes | Recently installed or upgraded packages |
| 1.40 | System Cron Directories | `/etc/cron.*` directories and `/etc/crontab` |
| 1.41 | All User Crontabs | Every user's scheduled jobs |
| 1.42 | Systemd Timers | All `systemctl list-timers` units |
| 1.43 | At Jobs | Scheduled `at` jobs |
| 1.44 | SELinux Status | Enforcement status and policy |
| 1.45 | AppArmor Status | Profiles and enforcement status |
| 1.46 | Open Files (lsof) | All open file handles and sockets |
| 1.47 | Running Processes | `ps auxf` — all processes with tree |
| 1.48 | Systemd Services | All service units and their state |
| 1.49 | Environment Variables | Current shell environment |
| 1.50 | Mounted Filesystems | `mount` output and `/etc/fstab` |

### 2. Network Security Audit (checks 2.1 – 2.22)

Covers network interfaces, listening TCP/UDP services, all connections, iptables (filter/NAT/mangle), ip6tables, UFW, firewalld, nftables, DNS/hosts config, routing tables, IPv6 routes, ARP table, interface statistics, protocol statistics, wireless interfaces, hostname configuration, and NetworkManager status.

### 3. Port Scanning Analysis (checks 3.1 – 3.8)

| # | Check |
|---|-------|
| 3.1 | Quick port scan — top 1000 TCP ports (nmap or bash fallback) |
| 3.2 | Service/version detection — top 100 ports |
| 3.3 | UDP scan — top 100 UDP ports |
| 3.4 | Full TCP scan — all 65535 ports |
| 3.5 | OS detection fingerprinting |
| 3.6 | Listening services detail |
| 3.7 | Process-to-port mapping (lsof) |
| 3.8 | Unix domain sockets |

### 4. Security Summary & Recommendations

Automatically extracts critical findings from the audit data and provides actionable recommendations across 8 domains: user account security, SSH hardening, file system security, network security, kernel hardening, logging and monitoring, service hardening, and patch management.

---

## 📊 Output Formats

### HTML Dashboard
An interactive, self-contained HTML file — open it in any browser. Includes:
- **Risk Score** (0–100) with colour-coded severity label
- **KPI Cards** — open ports, SUID binaries, world-writable files, failed logins, empty-password accounts, root users, pending updates, running processes
- **Resource Usage Doughnut** — CPU load, memory usage, disk usage
- **File System Risk Bar Chart** — SUID, world-writable, empty passwords, root accounts
- **Risk Radar Chart** — SSH, firewall, users, files, MAC/SELinux, updates
- **Findings by Severity Pie** — critical / high / medium / low
- **Security Checklist** — access controls, network & firewall, MAC & kernel hardening

### TXT Report
Plain text, structured with Unicode box-drawing characters. Compatible with `cat`, `less`, `grep`, and any log viewer. Timestamped filename: `Linux_security_audit_YYYYMMDD_HHMMSS.txt`.

### PDF Report
Generated via Python `reportlab` (preferred) with a professional cover page, metadata table, table of contents, and per-section styling. Falls back to `cupsfilter` → `vim+ps2pdf` → `enscript+ps2pdf` → `wkhtmltopdf` → ASCII fallback.

---

## 🖥️ Requirements

### Mandatory
- Bash 4.0+
- Linux (Debian, Ubuntu, RHEL, CentOS, Fedora, Arch, SUSE — or any systemd-based distro)

### Recommended (auto-installed on prompt)
| Tool | Package | Purpose |
|------|---------|---------|
| `nmap` | `nmap` | Port scanning |
| `lsof` | `lsof` | Open file / port mapping |
| `ss` | `iproute2` | Socket statistics |
| `netstat` | `net-tools` | Network connections |
| `auditctl` | `auditd` | Audit daemon rules |

### For PDF generation (optional)
- `python3` + `reportlab` — `pip install reportlab` (preferred method)
- `enscript` + `ghostscript` — `apt install enscript ghostscript`
- `cupsfilter` — `apt install cups-client`
- `wkhtmltopdf` — `apt install wkhtmltopdf`

---

## 📁 Project Structure

```
Linux-Audit-Tool/
├── Linux_Audit_Tool_V4_0.sh    # Main audit script
├── README.md                    # This file
└── LICENSE                      # License
```

Output files (generated at runtime):
```
Linux_security_audit_YYYYMMDD_HHMMSS.txt    # Text Report
Linux_security_audit_YYYYMMDD_HHMMSS.pdf    # PDF Report
Linux_security_audit_YYYYMMDD_HHMMSS.html   # Interactive Dashboard
```

---

## 🔐 Security Considerations

- Reports may contain **sensitive system information** (password hashes, private key paths, user data). Store and transmit reports securely.
- This tool is intended for **authorized use only** on systems you own or have explicit written permission to audit.
- The HTML dashboard is generated as a **local file** — it does not make any outbound network requests (Chart.js is loaded via CDN; consider hosting it locally in air-gapped environments).
- The script does **not modify** any system configuration — it is purely read-only (except for optionally installing audit tools).

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add: your feature description"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

### Ideas for contributions
- Additional audit checks (e.g., Docker security, PAM configuration, GRUB hardening)
- JSON output format for integration with SIEMs
- Scheduled audit mode via cron integration
- Comparison mode (diff two audit reports)

---

## 👤 Author

**Moksh Sharma**
- GitHub: [@MokshSharma2006](https://github.com/MokshSharma2006)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**If this tool helped you, please consider giving it a ⭐ on GitHub!**

*Linux Audit Tool v4.0 — For internal use only. Always audit responsibly.*

</div>

#!/bin/bash

# Linux Audit Tool
# Version: 4.0
# Author: Moksh Sharma

echo " _     _                         _             _ _ _      _____           _"
echo "| |   (_)_ __  _   ___  __      / \  _   _  __| (_) |_   |_   _|__   ___ | |"
echo "| |   | | '_ \| | | \ \/ /____ / _ \| | | |/ _\` | | __|____| |/ _ \ / _ \| |"
echo "| |___| | | | | |_| |>  <_____/ ___ \ |_| | (_| | | ||_____| | (_) | (_) | |"
echo "|_____|_|_| |_|\__,_/_/\_\   /_/   \_\__,_|\__,_|_|\__|    |_|\___/ \___/|_|"

echo ""
echo ""

echo "================================================================"
echo "            L I N U X   A U D I T                               "
echo "================================================================"
echo " Version : 4.0"
echo " Author  : Moksh Sharma"
echo " Project : Linux-Audit-Tool"
echo " GitHub  : https://github.com/MokshSharma2006"
echo "================================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Global variables
SCRIPT_START_TIME=$(date +%s)
OUTPUT_FORMAT="txt"
OUTPUT_FILE_TXT=""
OUTPUT_FILE_PDF=""
OUTPUT_FILE_HTML=""
TEMP_FILE="/tmp/security_audit_temp_$$.txt"

# ── Metric counters (populated during audit) ──────────────────────────────────
METRIC_OPEN_PORTS=0
METRIC_SUID_FILES=0
METRIC_WORLD_WRITABLE=0
METRIC_FAILED_LOGINS=0
METRIC_USERS_NO_PASS=0
METRIC_ROOT_USERS=0
METRIC_LISTENING_SVCS=0
METRIC_PENDING_UPDATES=0
METRIC_RUNNING_PROCS=0
METRIC_DISK_USAGE=0
METRIC_CPU_LOAD=""
METRIC_MEM_USED=0
METRIC_MEM_TOTAL=0
METRIC_UFW_STATUS="unknown"
METRIC_SSH_ROOT="unknown"
METRIC_SELINUX="unknown"
METRIC_APPARMOR="unknown"

# ──────────────────────────────────────────────────────────────────
# Privilege handling
# ──────────────────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Color support detection
if [ -t 1 ] && [ "$TERM" != "dumb" ]; then
    USE_COLORS=1
else
    USE_COLORS=0
fi

print_color() {
    local color=$1
    local message=$2
    if [ $USE_COLORS -eq 1 ]; then
        echo -e "${color}${message}${NC}"
    else
        echo "$message"
    fi
}

banner() {
    if [ $USE_COLORS -eq 1 ]; then
        echo -e "${CYAN}"
        echo "  ╔═══════════════════════════════════════════════════════════╗"
        echo "  ║                LINUX SECURITY AUDIT TOOL                  ║"
        echo "  ║                    Enhanced Version 4.0                   ║"
        echo "  ╚═══════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    else
        echo "  ==============================================================="
        echo "                LINUX SECURITY AUDIT TOOL v4.0                   "
        echo "  ==============================================================="
    fi
    echo -e "${YELLOW}Date: $(date)${NC}"
    echo -e "${YELLOW}Hostname: $(hostname)${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
}

detect_distro() {
    if [ -f /etc/debian_version ]; then echo "debian"
    elif [ -f /etc/redhat-release ]; then echo "redhat"
    elif [ -f /etc/arch-release ]; then echo "arch"
    elif [ -f /etc/fedora-release ]; then echo "fedora"
    elif [ -f /etc/SuSE-release ]; then echo "suse"
    else echo "unknown"
    fi
}

install_pdf_tools() {
    local distro=$(detect_distro)
    echo -e "\n${YELLOW}[!] PDF generation tools are not installed.${NC}"
    echo -e "${CYAN}Choose an option:${NC}"
    echo "1) Install PDF tools automatically"
    echo "2) Show installation instructions"
    echo "3) Continue with TXT format only"
    echo "4) Exit"
    while true; do
        read -p "Enter your choice [1-4]: " install_choice
        case $install_choice in
            1)
                echo -e "${YELLOW}[*] Attempting to install PDF tools...${NC}"
                case $distro in
                    debian)   $SUDO apt update && $SUDO apt install -y enscript ghostscript cups-client vim ;;
                    redhat|fedora) $SUDO yum install -y enscript ghostscript cups-client vim || $SUDO dnf install -y enscript ghostscript cups-client vim ;;
                    arch)     $SUDO pacman -S --noconfirm enscript ghostscript cups vim ;;
                    suse)     $SUDO zypper install -y enscript ghostscript cups-client vim ;;
                    *)
                        echo -e "${RED}[-] Automatic install not supported for your distro.${NC}"
                        return 2 ;;
                esac
                if command -v enscript >/dev/null 2>&1 && command -v ps2pdf >/dev/null 2>&1; then
                    echo -e "${GREEN}[+] PDF tools installed successfully!${NC}"; return 0
                else
                    echo -e "${RED}[-] Installation failed.${NC}"; return 2
                fi ;;
            2)
                echo -e "\n${CYAN}=== Installation Instructions ===${NC}"
                case $distro in
                    debian)      echo "Run: sudo apt update && sudo apt install enscript ghostscript cups-client vim" ;;
                    redhat|fedora) echo "Run: sudo yum install enscript ghostscript cups-client vim" ;;
                    arch)        echo "Run: sudo pacman -S enscript ghostscript cups vim" ;;
                    suse)        echo "Run: sudo zypper install enscript ghostscript cups-client vim" ;;
                    *)           echo "Please install: enscript ghostscript cups-client vim" ;;
                esac
                echo "" ;;
            3) echo -e "${YELLOW}[!] Continuing with TXT format only...${NC}"; return 2 ;;
            4) echo -e "${RED}[-] Exiting...${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice. Please enter 1-4.${NC}" ;;
        esac
    done
}

# ──────────────────────────────────────────────────────────────────
# AUTO-INSTALL AUDIT TOOLS
# ──────────────────────────────────────────────────────────────────
auto_install_audit_tools() {
    local distro=$(detect_distro)
    local missing_tools=()

    # Reduced to core tools to prevent endless install loops for OS-specific binaries
    local tool_pkg_map=(
        "nmap:nmap"
        "lsof:lsof"
        "ss:iproute2"
        "netstat:net-tools"
        "auditctl:auditd"
    )

    echo -e "\n${CYAN}[*] Checking for required audit tools...${NC}"

    for entry in "${tool_pkg_map[@]}"; do
        local bin="${entry%%:*}"
        local pkg="${entry##*:}"
        if ! command -v "$bin" >/dev/null 2>&1; then
            missing_tools+=("$bin ($pkg)")
        fi
    done

    if [ ${#missing_tools[@]} -eq 0 ]; then
        echo -e "${GREEN}[+] All core audit tools are present.${NC}"
        return 0
    fi

    echo -e "${YELLOW}[!] Missing tools detected:${NC}"
    for t in "${missing_tools[@]}"; do
        echo -e "    ${RED}✗${NC} $t"
    done

    echo ""
    echo "1) Install missing tools automatically (recommended)"
    echo "2) Continue without them (some checks may be incomplete)"
    echo "3) Exit"

    while true; do
        read -p "Enter your choice [1-3]: " tool_choice
        case $tool_choice in
            1)
                echo -e "${YELLOW}[*] Installing missing tools...${NC}"
                # Build unique package list
                local pkgs_to_install=()
                for entry in "${tool_pkg_map[@]}"; do
                    local bin="${entry%%:*}"
                    local pkg="${entry##*:}"
                    if ! command -v "$bin" >/dev/null 2>&1; then
                        pkgs_to_install+=("$pkg")
                    fi
                done
                # Deduplicate
                local unique_pkgs=($(printf '%s\n' "${pkgs_to_install[@]}" | sort -u))

                case $distro in
                    debian)
                        $SUDO apt-get update -qq && $SUDO apt-get install -y "${unique_pkgs[@]}" 2>/dev/null
                        ;;
                    redhat|fedora)
                        $SUDO yum install -y "${unique_pkgs[@]}" 2>/dev/null || \
                        $SUDO dnf install -y "${unique_pkgs[@]}" 2>/dev/null
                        ;;
                    arch)
                        $SUDO pacman -S --noconfirm "${unique_pkgs[@]}" 2>/dev/null
                        ;;
                    suse)
                        $SUDO zypper install -y "${unique_pkgs[@]}" 2>/dev/null
                        ;;
                    *)
                        echo -e "${RED}[-] Auto-install not supported for your distro. Install manually.${NC}"
                        return 1
                        ;;
                esac

                echo -e "${GREEN}[+] Tool installation complete.${NC}"
                return 0
                ;;
            2)
                echo -e "${YELLOW}[!] Continuing — some audit checks may show errors.${NC}"
                return 0
                ;;
            3)
                echo -e "${RED}[-] Exiting.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice.${NC}"
                ;;
        esac
    done
}

check_pdf_tools() {
    if command -v enscript >/dev/null 2>&1 && command -v ps2pdf >/dev/null 2>&1; then
        echo -e "${GREEN}[+] Found enscript and ps2pdf${NC}"; return 0
    elif command -v cupsfilter >/dev/null 2>&1; then
        echo -e "${GREEN}[+] Found cupsfilter${NC}"; return 0
    elif command -v vim >/dev/null 2>&1 && command -v ps2pdf >/dev/null 2>&1; then
        echo -e "${GREEN}[+] Found vim and ps2pdf${NC}"; return 0
    fi
    echo -e "\n${YELLOW}[!] PDF generation tools not found.${NC}"
    echo "1) Yes, install PDF tools"
    echo "2) No, use TXT only"
    echo "3) Exit"
    while true; do
        read -p "Enter your choice [1-3]: " pdf_choice
        case $pdf_choice in
            1) if install_pdf_tools; then return 0; else return 1; fi ;;
            2) echo -e "${YELLOW}[!] Using TXT format only...${NC}"; return 1 ;;
            3) echo -e "${RED}[-] Exiting...${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice.${NC}" ;;
        esac
    done
}

choose_output_format() {
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                 CHOOSE OUTPUT FORMAT                               ${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}\n"
    echo -e "${YELLOW}[1]${NC} Text File (TXT) - Default"
    echo -e "${YELLOW}[2]${NC} PDF Document"
    echo -e "${YELLOW}[3]${NC} Both (TXT + PDF)"
    echo ""
    while true; do
        read -p "Select output format [1/2/3] (default: 1): " format_choice
        case "${format_choice:-1}" in
            1) OUTPUT_FORMAT="txt";  echo -e "${GREEN}[+] TXT selected${NC}"; break ;;
            2)
                if check_pdf_tools; then OUTPUT_FORMAT="pdf"; echo -e "${GREEN}[+] PDF selected${NC}"
                else OUTPUT_FORMAT="txt"; echo -e "${YELLOW}[!] Falling back to TXT${NC}"; fi
                break ;;
            3)
                if check_pdf_tools; then OUTPUT_FORMAT="both"; echo -e "${GREEN}[+] Both selected${NC}"
                else OUTPUT_FORMAT="txt"; echo -e "${YELLOW}[!] PDF unavailable, using TXT${NC}"; fi
                break ;;
            *) echo -e "${RED}Invalid choice. Enter 1, 2, or 3.${NC}" ;;
        esac
    done
    local timestamp=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE_TXT="Linux_security_audit_${timestamp}.txt"
    OUTPUT_FILE_PDF="Linux_security_audit_${timestamp}.pdf"
    OUTPUT_FILE_HTML="Linux_security_audit_${timestamp}.html"
}

convert_to_pdf() {
    local txt_file=$1
    local pdf_file=$2
    echo -e "${YELLOW}[*] Converting to PDF...${NC}"

    if command -v python3 >/dev/null 2>&1 && python3 -c "import reportlab" 2>/dev/null; then
        python3 - "$txt_file" "$pdf_file" << 'PYEOF'
import sys, os
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER

txt_file, pdf_file = sys.argv[1], sys.argv[2]

with open(txt_file, 'r', errors='replace') as f:
    raw_lines = f.readlines()

doc = SimpleDocTemplate(
    pdf_file, pagesize=A4,
    leftMargin=15*mm, rightMargin=15*mm,
    topMargin=20*mm, bottomMargin=20*mm,
    title="Linux Security Audit Report"
)

styles = getSampleStyleSheet()
style_title   = ParagraphStyle('T', fontName='Helvetica-Bold',   fontSize=16, textColor=colors.HexColor('#1a237e'), spaceAfter=4, alignment=TA_CENTER)
style_section = ParagraphStyle('S', fontName='Helvetica-Bold',   fontSize=11, textColor=colors.HexColor('#0d47a1'), spaceBefore=10, spaceAfter=4, leading=14)
style_subhdr  = ParagraphStyle('H', fontName='Helvetica-Bold',   fontSize=9,  textColor=colors.HexColor('#37474f'), spaceBefore=6, spaceAfter=2, leading=11)
style_meta    = ParagraphStyle('M', fontName='Helvetica',        fontSize=8,  textColor=colors.HexColor('#546e7a'), spaceAfter=2, leading=10)
style_code    = ParagraphStyle('C', fontName='Courier',          fontSize=7,  textColor=colors.HexColor('#212121'), spaceAfter=1, leading=9, leftIndent=6)
style_ok      = ParagraphStyle('OK',fontName='Helvetica-Bold',   fontSize=7.5,textColor=colors.HexColor('#1b5e20'), spaceAfter=3, leading=9)
style_fail    = ParagraphStyle('FL',fontName='Helvetica-Bold',   fontSize=7.5,textColor=colors.HexColor('#b71c1c'), spaceAfter=3, leading=9)
style_warn    = ParagraphStyle('WN',fontName='Helvetica-Bold',   fontSize=7.5,textColor=colors.HexColor('#e65100'), spaceAfter=3, leading=9)
style_normal  = ParagraphStyle('N', fontName='Helvetica',        fontSize=8,  textColor=colors.HexColor('#212121'), spaceAfter=2, leading=10)

def esc(t):
    return t.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')

story = []

# --- Cover page ---
story.append(Spacer(1, 18*mm))
story.append(HRFlowable(width="100%", thickness=3, color=colors.HexColor('#1a237e')))
story.append(Spacer(1, 4*mm))
story.append(Paragraph("LINUX SECURITY AUDIT REPORT", style_title))
story.append(Paragraph("Comprehensive Security Assessment", ParagraphStyle('sub', fontName='Helvetica', fontSize=10, textColor=colors.HexColor('#455a64'), alignment=TA_CENTER, spaceAfter=4)))
story.append(Spacer(1, 3*mm))
story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#90a4ae')))
story.append(Spacer(1, 8*mm))

# Extract metadata from file header
meta = {}
for line in raw_lines[:20]:
    for k in ['Generated on', 'Hostname', 'Kernel Version', 'Distribution', 'IP Address', 'User', 'Working Dir']:
        if line.strip().startswith(k):
            val = line.split(':', 1)[-1].strip()
            meta[k] = val

meta_data = [
    ['Field', 'Value'],
    ['Generated On',  meta.get('Generated on', 'N/A')],
    ['Hostname',      meta.get('Hostname', 'N/A')],
    ['Kernel',        meta.get('Kernel Version', 'N/A')],
    ['Distribution',  meta.get('Distribution', 'N/A')],
    ['IP Address',    meta.get('IP Address', 'N/A')],
    ['Audited User',  meta.get('User', 'N/A')],
]
t = Table(meta_data, colWidths=[45*mm, 120*mm])
t.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1a237e')),
    ('TEXTCOLOR',  (0,0), (-1,0), colors.white),
    ('FONTNAME',   (0,0), (-1,0), 'Helvetica-Bold'),
    ('FONTSIZE',   (0,0), (-1,-1), 8),
    ('BACKGROUND', (0,1), (-1,-1), colors.HexColor('#f5f5f5')),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.HexColor('#fafafa'), colors.HexColor('#e8eaf6')]),
    ('GRID',       (0,0), (-1,-1), 0.5, colors.HexColor('#90a4ae')),
    ('FONTNAME',   (0,1), (0,-1), 'Helvetica-Bold'),
    ('TEXTCOLOR',  (0,1), (0,-1), colors.HexColor('#37474f')),
    ('ALIGN',      (0,0), (-1,-1), 'LEFT'),
    ('PADDING',    (0,0), (-1,-1), 5),
    ('VALIGN',     (0,0), (-1,-1), 'MIDDLE'),
]))
story.append(t)
story.append(Spacer(1, 6*mm))

# TOC
story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#90a4ae')))
story.append(Spacer(1, 3*mm))
story.append(Paragraph("TABLE OF CONTENTS", style_section))
toc_items = [
    "1. System Security Audit  (checks 1.1 - 1.50)",
    "2. Network Security Audit  (checks 2.1 - 2.22)",
    "3. Port Scanning Analysis  (checks 3.1 - 3.8)",
    "4. Security Summary &amp; Recommendations",
]
for item in toc_items:
    story.append(Paragraph(item, ParagraphStyle('toc', fontName='Helvetica', fontSize=9, textColor=colors.HexColor('#37474f'), leftIndent=10, spaceAfter=3, leading=11)))
story.append(Spacer(1, 4*mm))
story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor('#1a237e')))
story.append(PageBreak())

# --- Body ---
BOX_CHARS = set('╔╗╚╝║═╠╣╦╩╬┌┐└┘│─├┤┬┴┼')

def is_separator(line):
    stripped = line.strip()
    if not stripped:
        return False
    unique = set(stripped)
    return unique <= BOX_CHARS or unique <= {'=', '-', '─'} or '═══' in stripped or '╔══' in stripped or '╚══' in stripped

def is_section_header(line):
    stripped = line.strip()
    for mark in ['1. SYSTEM', '2. NETWORK', '3. PORT SCAN', '4. SECURITY SUMMARY']:
        if mark in stripped.upper():
            return True
    return False

def is_check_header(line):
    import re
    return bool(re.match(r'.*\d+\.\d+\s*[-\u2013]\s*\S', line.strip()))

def classify_status(line):
    u = line.upper()
    if 'STATUS: SUCCESS' in u:
        return 'ok'
    if 'STATUS: FAILED' in u or 'STATUS: FAIL' in u:
        return 'fail'
    if 'CRITICAL' in u or 'WARNING' in u or 'WARN' in u:
        return 'warn'
    return None

in_section = False
for raw in raw_lines:
    line = raw.rstrip('\n')
    clean = ''.join(c for c in line if c not in BOX_CHARS)

    if is_separator(line):
        story.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor('#b0bec5'), spaceAfter=2, spaceBefore=2))
        continue

    if is_section_header(line):
        story.append(Spacer(1, 4*mm))
        story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor('#0d47a1')))
        story.append(Paragraph(esc(clean.strip()), style_section))
        story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#90a4ae')))
        continue

    if is_check_header(line):
        story.append(Spacer(1, 3*mm))
        story.append(Paragraph(esc(clean.strip()), style_subhdr))
        continue

    st = classify_status(line)
    if st == 'ok':
        story.append(Paragraph('&#10003; ' + esc(clean.strip()), style_ok))
        continue
    if st == 'fail':
        story.append(Paragraph('&#10007; ' + esc(clean.strip()), style_fail))
        continue
    if st == 'warn':
        story.append(Paragraph('&#9888; ' + esc(clean.strip()), style_warn))
        continue

    stripped = clean.strip()
    if not stripped:
        story.append(Spacer(1, 1.5*mm))
        continue

    if line.startswith('Description:') or line.startswith('Timestamp:'):
        story.append(Paragraph(esc(stripped), style_meta))
    else:
        story.append(Paragraph(esc(stripped), style_code))

def add_page_number(canvas, doc):
    canvas.saveState()
    canvas.setFont('Helvetica', 7)
    canvas.setFillColor(colors.HexColor('#90a4ae'))
    canvas.drawString(15*mm, 10*mm, "Linux Security Audit Report  |  Confidential")
    canvas.drawRightString(A4[0] - 15*mm, 10*mm, f"Page {doc.page}")
    canvas.setStrokeColor(colors.HexColor('#e0e0e0'))
    canvas.line(15*mm, 13*mm, A4[0]-15*mm, 13*mm)
    canvas.restoreState()

doc.build(story, onFirstPage=add_page_number, onLaterPages=add_page_number)
print("PDF created via Python/reportlab")
PYEOF
        if [ -s "$pdf_file" ]; then
            echo -e "${GREEN}[+] PDF via Python/reportlab (clean formatting)${NC}"
            return 0
        fi
    fi

    if command -v cupsfilter >/dev/null 2>&1; then
        local tmp="/tmp/tmp_utf8_$$.txt"
        iconv -f UTF-8 -t UTF-8 "$txt_file" > "$tmp" 2>/dev/null || cp "$txt_file" "$tmp"
        cupsfilter "$tmp" > "$pdf_file" 2>/dev/null
        rm -f "$tmp"
        [ -s "$pdf_file" ] && { echo -e "${GREEN}[+] PDF via cupsfilter${NC}"; return 0; }
    fi

    if command -v vim >/dev/null 2>&1 && command -v ps2pdf >/dev/null 2>&1; then
        local tmp_ps="/tmp/tmp_audit_$$.ps"
        cat > /tmp/vim2ps_$$.vim << EOF
:set enc=utf-8
:set fenc=utf-8
:set printencoding=utf-8
:hardcopy > ${tmp_ps}
:q
EOF
        vim -u NONE -U NONE -N -e -s "$txt_file" -S /tmp/vim2ps_$$.vim 2>/dev/null
        rm -f /tmp/vim2ps_$$.vim
        if [ -f "$tmp_ps" ]; then
            ps2pdf "$tmp_ps" "$pdf_file" 2>/dev/null; rm -f "$tmp_ps"
            [ -f "$pdf_file" ] && { echo -e "${GREEN}[+] PDF via vim+ps2pdf${NC}"; return 0; }
        fi
    fi

    if command -v enscript >/dev/null 2>&1 && command -v ps2pdf >/dev/null 2>&1; then
        local tmp_ps="/tmp/tmp_audit_$$.ps"
        enscript --encoding=utf-8 --font=Courier10 --landscape --word-wrap \
                 --margins=30:30:30:30 --output="$tmp_ps" "$txt_file" 2>/dev/null
        if [ -f "$tmp_ps" ]; then
            ps2pdf "$tmp_ps" "$pdf_file" 2>/dev/null; rm -f "$tmp_ps"
            [ -f "$pdf_file" ] && { echo -e "${GREEN}[+] PDF via enscript+ps2pdf${NC}"; return 0; }
        fi
    fi

    if command -v wkhtmltopdf >/dev/null 2>&1; then
        local html="/tmp/tmp_audit_$$.html"
        printf '<!DOCTYPE html><html><head><meta charset="UTF-8"><style>body{font-family:monospace;font-size:11pt;margin:40px}pre{white-space:pre-wrap;word-wrap:break-word}</style></head><body><pre>' > "$html"
        cat "$txt_file" >> "$html"
        printf '</pre></body></html>' >> "$html"
        wkhtmltopdf --encoding utf-8 "$html" "$pdf_file" 2>/dev/null
        rm -f "$html"
        [ -f "$pdf_file" ] && { echo -e "${GREEN}[+] PDF via wkhtmltopdf${NC}"; return 0; }
    fi

    local asc="/tmp/tmp_ascii_$$.txt"
    sed 's/╔/+/g;s/╗/+/g;s/╚/+/g;s/╝/+/g;s/║/|/g;s/═/-/g;s/─/-/g;s/│/|/g;s/┌/+/g;s/┐/+/g;s/└/+/g;s/┘/+/g' "$txt_file" > "$asc"
    if command -v enscript >/dev/null 2>&1 && command -v ps2pdf >/dev/null 2>&1; then
        local tmp_ps="/tmp/tmp_audit_$$.ps"
        enscript --output="$tmp_ps" "$asc" 2>/dev/null
        ps2pdf "$tmp_ps" "$pdf_file" 2>/dev/null
        rm -f "$tmp_ps" "$asc"
        [ -f "$pdf_file" ] && { echo -e "${GREEN}[+] PDF via ASCII fallback${NC}"; return 0; }
    fi
    rm -f "$asc"
    echo -e "${RED}[-] All PDF methods failed.${NC}"; return 1
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${RED}[-] $1 is not installed${NC}"; return 1
    fi
    return 0
}

check_append() {
    local section_num=$1
    local title=$2
    local command=$3
    local description=$4

    echo -e "${YELLOW}[*] $section_num - Checking: $title${NC}"

    cat >> "$TEMP_FILE" << EOF

┌─────────────────────────────────────────────────────────────────────────────┐
│ $section_num - $title
└─────────────────────────────────────────────────────────────────────────────┘
Description: $description
Timestamp: $(date)

EOF

    if eval "$command" >> "$TEMP_FILE" 2>&1; then
        echo "Status: SUCCESS" >> "$TEMP_FILE"
    else
        local exit_code=$?
        if [ $exit_code -eq 1 ]; then
            echo "Status: SUCCESS (no matches found)" >> "$TEMP_FILE"
        else
            echo "Status: FAILED or INCOMPLETE (exit code: $exit_code)" >> "$TEMP_FILE"
        fi
    fi

    printf '\n────────────────────────────────────────────────────────────────────────────\n\n' >> "$TEMP_FILE"
}

initialize_output() {
    cat > "$TEMP_FILE" << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                          LINUX SECURITY AUDIT REPORT                         ║
╚══════════════════════════════════════════════════════════════════════════════╝

Generated on   : $(date)
Hostname       : $(hostname)
Kernel Version : $(uname -r)
Distribution   : $(lsb_release -d 2>/dev/null | cut -f2- || grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Unknown")
IP Address     : $(hostname -I 2>/dev/null | awk '{print $1}' || echo "Unknown")
User           : $(whoami)
Working Dir    : $(pwd)

╔══════════════════════════════════════════════════════════════════════════════╗
║                                TABLE OF CONTENTS                             ║
╚══════════════════════════════════════════════════════════════════════════════╝

1. SYSTEM SECURITY AUDIT      (checks 1.1 – 1.50)
2. NETWORK SECURITY AUDIT     (checks 2.1 – 2.22)
3. PORT SCANNING ANALYSIS     (checks 3.1 – 3.8)
4. SECURITY SUMMARY & RECOMMENDATIONS

══════════════════════════════════════════════════════════════════════════════

EOF
}

system_security_audit() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                           1. SYSTEM SECURITY AUDIT                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}\n"

    printf '\n╔══════════════════════════════════════════════════════════════════════════════╗\n' >> "$TEMP_FILE"
    printf '║                           1. SYSTEM SECURITY AUDIT                           ║\n' >> "$TEMP_FILE"
    printf '╚══════════════════════════════════════════════════════════════════════════════╝\n' >> "$TEMP_FILE"

    check_append "1.1"  "User Accounts"              "cat /etc/passwd" "All user accounts on the system"
    check_append "1.2"  "Password Hashes"            "$SUDO cat /etc/shadow 2>/dev/null || echo 'Access denied'" "Password hashes and account expiry info"
    check_append "1.3"  "Empty Password Accounts"    "$SUDO awk -F: '(\$2==\"\"){print \$1\" - CRITICAL: Empty Password!\"}' /etc/shadow 2>/dev/null || echo 'Requires root'" "Accounts with no password set (critical risk)"
    check_append "1.4"  "UID 0 Accounts"             "awk -F: '(\$3==0){print \$1\" - UID 0 (root equivalent)\"}' /etc/passwd" "Any account with root-level UID"
    check_append "1.5"  "Last Logins"                "lastlog 2>/dev/null || grep -v 'Never logged in' /var/log/wtmp 2>/dev/null | strings | head -50 || echo 'lastlog not available'" "Last login time for every account"
    check_append "1.6"  "Currently Logged In Users"  "w && echo && who -a" "Users active right now"
    check_append "1.7"  "Failed Login Attempts"      "$SUDO lastb 2>/dev/null || echo 'No records or access denied'" "All recent failed login attempts"
    check_append "1.8"  "Full Login History"         "last -F 2>/dev/null || last 2>/dev/null || echo 'last not available'" "Complete login/logout history"
    check_append "1.9"  "Password Aging Policy"      "$SUDO chage -l root 2>/dev/null; echo; grep -E '^PASS_MAX_DAYS|^PASS_MIN_DAYS|^PASS_WARN_AGE' /etc/login.defs 2>/dev/null" "Password expiry configuration"
    check_append "1.10" "Sudo Configuration"         "$SUDO cat /etc/sudoers 2>/dev/null; $SUDO ls -la /etc/sudoers.d/ 2>/dev/null; for f in \$($SUDO ls /etc/sudoers.d/ 2>/dev/null); do echo \"=== /etc/sudoers.d/\$f ===\"; $SUDO cat \"/etc/sudoers.d/\$f\" 2>/dev/null; done" "Full sudoers config including drop-in files"
    check_append "1.11" "Groups and Memberships"     "cat /etc/group; echo; getent group sudo 2>/dev/null; getent group wheel 2>/dev/null; getent group adm 2>/dev/null" "All groups and privileged group memberships"
    check_append "1.12" "SSH Server Configuration"   "$SUDO cat /etc/ssh/sshd_config 2>/dev/null | grep -v '^#' | grep -v '^\$' || echo 'SSH config not accessible'" "Active SSH daemon settings"
    check_append "1.13" "SSH Root Login Status"      "$SUDO grep -i 'PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null || echo 'Not explicitly set (defaults to prohibit-password)'" "Whether root can log in over SSH"
    check_append "1.14" "SSH Authorized Keys"        "find /root /home -name 'authorized_keys' 2>/dev/null -exec echo '=== {} ===' \\; -exec cat {} \\;" "All SSH public keys authorized on this system"
    check_append "1.15" "SSH Host Keys"              "ls -la /etc/ssh/ssh_host_* 2>/dev/null" "SSH host key files and permissions"
    check_append "1.16" "World-Writable Files"       "$SUDO find / -xdev -type f -perm -0002 -exec ls -l {} + 2>/dev/null || echo 'None found or access denied'" "All world-writable files (security risk)"
    check_append "1.17" "World-Writable Directories" "$SUDO find / -xdev -type d -perm -0002 -exec ls -ld {} + 2>/dev/null || echo 'None found'" "All world-writable directories"
    check_append "1.18" "SUID Files"                 "$SUDO find / -xdev -perm -4000 -type f -exec ls -l {} + 2>/dev/null" "Files that run with the owner's privileges"
    check_append "1.19" "SGID Files"                 "$SUDO find / -xdev -perm -2000 -type f -exec ls -l {} + 2>/dev/null" "Files that run with the group's privileges"
    check_append "1.20" "Unowned Files"              "$SUDO find / -xdev \\( -nouser -o -nogroup \\) -exec ls -l {} + 2>/dev/null || echo 'None found'" "Files with no valid owner or group"
    check_append "1.21" "Hidden Files in Home Dirs"  "$SUDO find /home /root -maxdepth 3 -name '.*' -exec ls -la {} + 2>/dev/null" "Dotfiles in user home directories"
    check_append "1.22" "Critical Directory Perms"   "ls -ld /tmp /var /etc /root /boot /usr /bin /sbin /home 2>/dev/null" "Permissions on key system directories"
    check_append "1.23" "Critical File Permissions"  "ls -l /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/sudoers /etc/ssh/sshd_config /etc/hosts /etc/crontab 2>/dev/null" "Permissions on sensitive system files"
    check_append "1.24" "Sticky Bit on Temp Dirs"    "ls -ld /tmp /var/tmp 2>/dev/null" "Verify sticky bit is set to prevent file hijacking"
    check_append "1.25" "Core Dump Configuration"    "$SUDO sysctl fs.suid_dumpable kernel.core_pattern 2>/dev/null || echo 'Access denied'" "Core dump security settings"
    check_append "1.26" "ASLR Status"                "cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo 'Not accessible'" "Address Space Layout Randomization (0=off,1=partial,2=full)"
    check_append "1.27" "All Kernel Security Params" "$SUDO sysctl -a 2>/dev/null | grep -E 'kernel\\.(randomize|dmesg|kptr|perf|yama|unprivileged)|net\\.ipv4\\.(ip_forward|conf|tcp_syncookies)|fs\\.(suid|protected)'" "Security-relevant kernel parameters"
    check_append "1.28" "Loaded Kernel Modules"      "lsmod | sort" "All currently loaded kernel modules"
    check_append "1.29" "Recent Kernel Messages"     "$SUDO dmesg 2>/dev/null | tail -100 || echo 'Access denied'" "Last 100 kernel ring buffer messages"
    check_append "1.30" "OS and Kernel Details"      "uname -a; echo; cat /proc/version; echo; lsb_release -a 2>/dev/null || cat /etc/os-release" "Full OS and kernel version information"
    check_append "1.31" "Audit Daemon Status"        "$SUDO systemctl status auditd 2>/dev/null || echo 'auditd not available'" "Linux audit daemon status"
    check_append "1.32" "Audit Rules"                "$SUDO auditctl -l 2>/dev/null || echo 'No rules or access denied'" "Active auditd rules"
    check_append "1.33" "System Log Directory"       "$SUDO ls -la /var/log/ 2>/dev/null" "All log files and their permissions"
    check_append "1.34" "Logging Daemon Status"      "$SUDO systemctl status rsyslog syslog systemd-journald 2>/dev/null" "Status of syslog / journald services"
    check_append "1.35" "Authentication Log"         "$SUDO cat /var/log/auth.log 2>/dev/null || $SUDO cat /var/log/secure 2>/dev/null || echo 'Auth log not accessible'" "Full authentication log"
    check_append "1.36" "Recent Syslog Entries"      "$SUDO tail -200 /var/log/syslog 2>/dev/null || $SUDO journalctl -n 200 --no-pager 2>/dev/null || echo 'Syslog not accessible'" "Last 200 syslog entries"
    check_append "1.37" "Installed Packages"         "dpkg -l 2>/dev/null || rpm -qa 2>/dev/null || pacman -Q 2>/dev/null || echo 'Package manager not detected'" "All installed packages"
    check_append "1.38" "Pending Security Updates"   "$SUDO apt list --upgradable 2>/dev/null | grep -i security || $SUDO yum list updates 2>/dev/null | grep -i security || echo 'None detected or unsupported package manager'" "Available security patches"
    check_append "1.39" "Recent Package Changes"     "grep -iE 'install|upgrade' /var/log/dpkg.log 2>/dev/null | tail -100 || rpm -qa --last 2>/dev/null | head -100 || echo 'Not available'" "Recently installed or upgraded packages"
    check_append "1.40" "System Cron Directories"    "$SUDO ls -laR /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly 2>/dev/null; $SUDO cat /etc/crontab 2>/dev/null" "All system-wide cron job directories"
    check_append "1.41" "All User Crontabs"          "for user in \$(cut -f1 -d: /etc/passwd); do ct=\$($SUDO crontab -u \"\$user\" -l 2>/dev/null); if [ -n \"\$ct\" ]; then echo \"=== Crontab for \$user ===\"; echo \"\$ct\"; fi; done; $SUDO ls -la /var/spool/cron/crontabs/ 2>/dev/null || true" "Every user's crontab entries"
    check_append "1.42" "Systemd Timers"             "$SUDO systemctl list-timers --all 2>/dev/null || echo 'Not available'" "All systemd timer units"
    check_append "1.43" "At Jobs"                    "$SUDO atq 2>/dev/null; $SUDO ls -la /var/spool/at/ 2>/dev/null || echo 'at not installed or no jobs'" "Scheduled at-jobs"
    check_append "1.44" "SELinux Status"             "$SUDO sestatus 2>/dev/null || echo 'SELinux not installed'" "SELinux enforcement status and policy"
    check_append "1.45" "AppArmor Status"            "$SUDO aa-status 2>/dev/null || echo 'AppArmor not installed'" "AppArmor profiles and enforcement status"
    check_append "1.46" "Open Files (lsof)"          "$SUDO lsof 2>/dev/null || echo 'lsof not available'" "All open file handles and sockets"
    check_append "1.47" "Running Processes"          "ps auxf 2>/dev/null || ps aux 2>/dev/null" "All running processes with tree view"
    check_append "1.48" "Systemd Services"           "$SUDO systemctl list-units --type=service --all 2>/dev/null || echo 'systemd not available'" "All systemd service units and their status"
    check_append "1.49" "Environment Variables"      "env | sort" "Current shell environment"
    check_append "1.50" "Mounted Filesystems"        "mount | sort; echo; cat /etc/fstab 2>/dev/null" "Mounted filesystems and fstab configuration"

    # ── Collect metrics for graph generation ─────────────────────────────────
    echo -e "${CYAN}[*] Collecting security metrics for dashboard...${NC}"

    # SUID files count
    METRIC_SUID_FILES=$(find / -perm -4000 -type f 2>/dev/null | wc -l)

    # World-writable files (excluding /proc /sys /dev)
    METRIC_WORLD_WRITABLE=$(find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o \
        -perm -0002 -type f -print 2>/dev/null | wc -l)

    # Users with empty passwords
    METRIC_USERS_NO_PASS=$(awk -F: '($2=="" || $2=="!!" || $2=="*"){print $1}' /etc/shadow 2>/dev/null | wc -l)

    # UID 0 (root equivalent) users
    METRIC_ROOT_USERS=$(awk -F: '$3==0{print $1}' /etc/passwd 2>/dev/null | wc -l)

    # Failed login attempts
    METRIC_FAILED_LOGINS=$(grep -c "Failed password\|authentication failure\|FAILED" \
        /var/log/auth.log /var/log/secure /var/log/audit/audit.log 2>/dev/null | \
        awk -F: '{sum+=$2}END{print sum+0}')

    # Open/listening TCP ports
    METRIC_OPEN_PORTS=$(ss -tlnp 2>/dev/null | grep -c LISTEN || netstat -tlnp 2>/dev/null | grep -c LISTEN || echo 0)

    # Listening services
    METRIC_LISTENING_SVCS=$METRIC_OPEN_PORTS

    # Pending security updates
    METRIC_PENDING_UPDATES=$(apt list --upgradable 2>/dev/null | grep -c security || \
        yum list updates 2>/dev/null | grep -c security || echo 0)

    # Running processes
    METRIC_RUNNING_PROCS=$(ps aux 2>/dev/null | wc -l)

    # Disk usage (root partition %)
    METRIC_DISK_USAGE=$(df / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')

    # CPU load (1-min)
    METRIC_CPU_LOAD=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}')

    # Memory
    METRIC_MEM_TOTAL=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}')
    METRIC_MEM_USED=$(free -m  2>/dev/null | awk '/^Mem:/{print $3}')

    # UFW / firewall
    if command -v ufw >/dev/null 2>&1; then
        METRIC_UFW_STATUS=$(ufw status 2>/dev/null | grep -q "Status: active" && echo "active" || echo "inactive")
    fi

    # SSH root login
    METRIC_SSH_ROOT=$(grep -i "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null | \
        awk '{print tolower($2)}' | head -1)
    [ -z "$METRIC_SSH_ROOT" ] && METRIC_SSH_ROOT="not-set"

    # SELinux
    METRIC_SELINUX=$(sestatus 2>/dev/null | grep "SELinux status" | awk '{print $3}' || echo "not-installed")

    # AppArmor
    METRIC_APPARMOR=$(aa-status 2>/dev/null | grep -q "apparmor module is loaded" && echo "loaded" || echo "not-loaded")
}

network_security_audit() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                          2. NETWORK SECURITY AUDIT                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}\n"

    printf '\n╔══════════════════════════════════════════════════════════════════════════════╗\n' >> "$TEMP_FILE"
    printf '║                          2. NETWORK SECURITY AUDIT                           ║\n' >> "$TEMP_FILE"
    printf '╚══════════════════════════════════════════════════════════════════════════════╝\n' >> "$TEMP_FILE"

    check_append "2.1"  "Network Interfaces"         "ip -br addr show; echo; ip link show" "Interface list and link status"
    check_append "2.2"  "Full IP Address Config"     "ip addr show" "All IP addresses on all interfaces"
    check_append "2.3"  "Active Interfaces"          "ip -br addr show | grep -v DOWN" "Interfaces currently up"
    check_append "2.4"  "Listening TCP Services"     "$SUDO ss -tulnp 2>/dev/null | grep LISTEN || $SUDO netstat -tulnp 2>/dev/null | grep LISTEN || echo 'Tools not available'" "TCP ports currently accepting connections"
    check_append "2.5"  "Listening UDP Services"     "$SUDO ss -ulnp 2>/dev/null || $SUDO netstat -ulnp 2>/dev/null || echo 'Not available'" "UDP ports currently open"
    check_append "2.6"  "All Network Connections"    "$SUDO ss -atnp 2>/dev/null || $SUDO netstat -atnp 2>/dev/null || echo 'Not available'" "All established and listening connections"
    check_append "2.7"  "IPTables Filter Rules"      "$SUDO iptables -L -n -v --line-numbers 2>/dev/null || echo 'Not accessible'" "iptables FILTER chain"
    check_append "2.8"  "IPTables NAT Rules"         "$SUDO iptables -t nat -L -n -v --line-numbers 2>/dev/null || echo 'Not accessible'" "iptables NAT chain"
    check_append "2.9"  "IPTables Mangle Rules"      "$SUDO iptables -t mangle -L -n -v --line-numbers 2>/dev/null || echo 'Not accessible'" "iptables mangle chain"
    check_append "2.10" "IP6Tables Rules"            "$SUDO ip6tables -L -n -v --line-numbers 2>/dev/null || echo 'ip6tables not accessible'" "IPv6 firewall rules"
    check_append "2.11" "UFW Status"                 "$SUDO ufw status verbose 2>/dev/null || echo 'UFW not installed'" "Uncomplicated Firewall status"
    check_append "2.12" "Firewalld Status"           "$SUDO firewall-cmd --state 2>/dev/null && $SUDO firewall-cmd --get-active-zones 2>/dev/null && $SUDO firewall-cmd --list-all 2>/dev/null || echo 'Not available'" "Firewalld zones and rules"
    check_append "2.13" "nftables Ruleset"           "$SUDO nft list ruleset 2>/dev/null || echo 'nftables not available'" "Modern nftables firewall rules"
    check_append "2.14" "DNS and Hosts Config"       "cat /etc/resolv.conf 2>/dev/null; echo; cat /etc/hosts; echo; cat /etc/nsswitch.conf 2>/dev/null" "Resolver, hosts file, name service config"
    check_append "2.15" "Routing Table"              "ip route show; echo; $SUDO route -n 2>/dev/null" "IPv4 routing table"
    check_append "2.16" "IPv6 Routes"                "ip -6 route show 2>/dev/null || echo 'No IPv6 routes'" "IPv6 routing table"
    check_append "2.17" "ARP Table"                  "ip neigh show || arp -a 2>/dev/null || echo 'Not available'" "ARP neighbour table"
    check_append "2.18" "Interface Statistics"       "ip -s link" "TX/RX counters for all interfaces"
    check_append "2.19" "Protocol Statistics"        "$SUDO netstat -s 2>/dev/null || $SUDO ss -s 2>/dev/null || echo 'Not available'" "Per-protocol network statistics"
    check_append "2.20" "Wireless Interfaces"        "iwconfig 2>/dev/null || iw dev 2>/dev/null || echo 'No wireless interfaces'" "Wi-Fi interface configuration"
    check_append "2.21" "Hostname Config"            "hostname -f 2>/dev/null; hostname -I 2>/dev/null; cat /etc/hostname 2>/dev/null" "System hostname settings"
    check_append "2.22" "NetworkManager Status"      "$SUDO systemctl status NetworkManager 2>/dev/null || echo 'NetworkManager not running'" "NetworkManager service status"
}

port_scanning_audit() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                         3. PORT SCANNING ANALYSIS                           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}\n"

    printf '\n╔══════════════════════════════════════════════════════════════════════════════╗\n' >> "$TEMP_FILE"
    printf '║                         3. PORT SCANNING ANALYSIS                            ║\n' >> "$TEMP_FILE"
    printf '╚══════════════════════════════════════════════════════════════════════════════╝\n' >> "$TEMP_FILE"

    if check_command "nmap"; then
        check_append "3.1" "Quick Port Scan (top 1000)" "nmap -sS --top-ports 1000 -T4 localhost 2>/dev/null || nmap --top-ports 1000 localhost 2>/dev/null" "Fast scan of the 1000 most common TCP ports"
        check_append "3.2" "Service Version Detection" "nmap -sV -sC --top-ports 100 localhost 2>/dev/null || echo 'Requires elevated privileges'" "Version and default script scan (top 100)"
        check_append "3.3" "UDP Port Scan" "$SUDO nmap -sU --top-ports 100 localhost 2>/dev/null || echo 'UDP scan requires root'" "UDP scan of top 100 ports"
        check_append "3.4" "Full TCP Scan (all ports)" "$SUDO nmap -sS -p- -T4 localhost 2>/dev/null || echo 'Requires root'" "Scan all 65535 TCP ports"
        check_append "3.5" "OS Detection" "$SUDO nmap -O localhost 2>/dev/null || echo 'Requires root'" "Remote OS fingerprinting"
    else
        check_append "3.1" "Fallback Port Scan (bash)" "
            echo 'nmap not available - using bash /dev/tcp fallback'
            common_ports=(20 21 22 23 25 53 67 80 88 110 111 119 135 139 143 161 389 443 445 465 514 587 631 636 993 995 1080 1194 1433 1521 1723 2049 2181 3306 3389 4444 5432 5900 5901 6379 6443 7001 8080 8443 8888 9000 9090 9200 27017)
            for port in \"\${common_ports[@]}\"; do
                if timeout 1 bash -c \"echo >/dev/tcp/localhost/\$port\" 2>/dev/null; then
                    echo \"Port \$port: OPEN\"
                fi
            done
        " "TCP probe of common ports using bash built-ins"
    fi

    check_append "3.6" "Listening Services Detail" "$SUDO netstat -tlnp 2>/dev/null | grep LISTEN || $SUDO ss -tlnp 2>/dev/null | grep LISTEN || echo 'Not available'" "All services with listening sockets"
    check_append "3.7" "Process-to-Port Mapping" "$SUDO lsof -i -P -n 2>/dev/null || echo 'lsof not available'" "Which process owns each open port"
    check_append "3.8" "Unix Domain Sockets" "$SUDO ss -xnp 2>/dev/null || echo 'Not available'" "Local Unix socket connections"
}

generate_security_summary() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                      4. SECURITY SUMMARY & RECOMMENDATIONS                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}\n"

    local SNAPSHOT="/tmp/security_audit_snapshot_$$.txt"
    cp "$TEMP_FILE" "$SNAPSHOT"

    cat >> "$TEMP_FILE" << EOF

╔══════════════════════════════════════════════════════════════════════════════╗
║                      4. SECURITY SUMMARY & RECOMMENDATIONS                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

CRITICAL SECURITY FINDINGS:
══════════════════════════

EOF

    echo -e "${YELLOW}[*] Analysing audit results...${NC}"
    echo "Potential findings extracted from audit data:" >> "$TEMP_FILE"

    grep -iE \
        'empty password|permitrootlogin yes|world.writable|suid.*root|uid 0|password.*none|audit.*inactive|CRITICAL|FAILED' \
        "$SNAPSHOT" | grep -v "Description:" >> "$TEMP_FILE" 2>/dev/null

    rm -f "$SNAPSHOT"

    cat >> "$TEMP_FILE" << EOF

SECURITY RECOMMENDATIONS:
═════════════════════════

1. USER ACCOUNT SECURITY
   - Enforce strong passwords on all accounts; consider PAM password quality
   - Lock or remove unused accounts (usermod -L / userdel)
   - Implement lockout policy with faillock or pam_tally2
   - Audit sudo access: principle of least privilege
   - Enable MFA for privileged accounts where possible

2. SSH HARDENING
   - Set PermitRootLogin no  in /etc/ssh/sshd_config
   - Set PasswordAuthentication no  (key-based auth only)
   - Change SSH port away from 22 (AllowedPorts or Port directive)
   - Restrict access: AllowUsers / AllowGroups
   - Deploy fail2ban with an SSH jail

3. FILE SYSTEM SECURITY
   - Remove unnecessary world-writable files
   - Audit all SUID/SGID binaries; remove unneeded ones (chmod -s)
   - Confirm /tmp and /var/tmp have sticky bit (chmod +t)
   - Deploy a file-integrity monitor: AIDE or Tripwire
   - Review unowned files and assign or remove them

4. NETWORK SECURITY
   - Close all non-essential listening ports
   - Configure a stateful firewall (ufw enable / firewall-cmd)
   - Disable IP forwarding unless this host routes traffic
   - Block ICMP redirects: net.ipv4.conf.all.accept_redirects=0
   - Enable SYN cookies: net.ipv4.tcp_syncookies=1

5. KERNEL HARDENING
   - Full ASLR: kernel.randomize_va_space=2
   - Restrict dmesg: kernel.dmesg_restrict=1
   - Hide kernel pointers: kernel.kptr_restrict=2
   - Disable SUID core dumps: fs.suid_dumpable=0
   - Consider linux-hardened or grsecurity kernel

6. LOGGING AND MONITORING
   - Run auditd with comprehensive rules
   - Forward logs to a remote syslog server
   - Deploy OSSEC or Wazuh for HIDS
   - Alert on authentication failures and privilege escalation

7. SERVICE HARDENING
   - Disable and mask unused systemd units
   - Run services as dedicated low-privilege users
   - Use systemd sandboxing: ProtectSystem=strict, NoNewPrivileges=yes
   - Enable MAC profiles (AppArmor/SELinux) for internet-facing services

8. PATCH MANAGEMENT
   - Apply all pending security updates immediately
   - Enable unattended-upgrades for automatic security patches
   - Subscribe to your distro's security advisory mailing list
   - Target SLA: critical patches within 24 h, high within 7 days

AUDIT COMPLETION SUMMARY:
═════════════════════════
Completed on    : $(date)
Duration        : $(($(date +%s) - SCRIPT_START_TIME)) seconds
System examined : $(hostname) running $(uname -r)

NOTE: This is a point-in-time assessment. Schedule recurring audits
      and remediate findings according to your risk acceptance policy.

╔══════════════════════════════════════════════════════════════════════════════╗
║                              END OF REPORT                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
}

generate_html_dashboard() {
    local html_file="$1"
    local audit_duration=$(($(date +%s) - SCRIPT_START_TIME))

    # Compute memory percentage safely
    local mem_pct=0
    if [ "${METRIC_MEM_TOTAL:-0}" -gt 0 ] 2>/dev/null; then
        mem_pct=$(( METRIC_MEM_USED * 100 / METRIC_MEM_TOTAL ))
    fi

    # Derive overall risk score (0-100, lower = better)
    local risk=0
    [ "$METRIC_SSH_ROOT" = "yes" ]       && risk=$((risk + 25))
    [ "$METRIC_UFW_STATUS" = "inactive" ] && risk=$((risk + 20))
    [ "${METRIC_USERS_NO_PASS:-0}" -gt 0 ] && risk=$((risk + 20))
    [ "$METRIC_SELINUX" = "disabled" ]   && risk=$((risk + 10))
    [ "$METRIC_APPARMOR" != "loaded" ]   && risk=$((risk + 10))
    [ "${METRIC_FAILED_LOGINS:-0}" -gt 50 ] && risk=$((risk + 15))
    [ "${METRIC_SUID_FILES:-0}" -gt 30 ]    && risk=$((risk + 10))
    [ "$risk" -gt 100 ] && risk=100

    local risk_label="Low"
    local risk_color="#22c55e"
    if [ "$risk" -ge 60 ]; then risk_label="High";   risk_color="#ef4444"
    elif [ "$risk" -ge 30 ]; then risk_label="Medium"; risk_color="#f59e0b"
    fi

    echo -e "${CYAN}[*] Generating HTML dashboard: ${YELLOW}$html_file${NC}"

    cat > "$html_file" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Linux Security Audit Dashboard — $(hostname)</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<style>
  :root{
    --bg:#0f172a;--bg2:#1e293b;--bg3:#334155;--text:#f1f5f9;--muted:#94a3b8;
    --green:#22c55e;--yellow:#f59e0b;--red:#ef4444;--blue:#3b82f6;--purple:#a855f7;
    --cyan:#06b6d4;--border:#334155;
  }
  *{box-sizing:border-box;margin:0;padding:0}
  body{background:var(--bg);color:var(--text);font-family:'Segoe UI',system-ui,sans-serif;font-size:14px;line-height:1.6;padding:24px}
  h1{font-size:1.6rem;font-weight:700;margin-bottom:4px}
  h2{font-size:1rem;font-weight:600;color:var(--muted);margin-bottom:16px}
  h3{font-size:.85rem;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.06em;margin-bottom:12px}
  .header{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:28px;flex-wrap:wrap;gap:12px}
  .meta{font-size:.8rem;color:var(--muted)}
  .badge{display:inline-block;padding:3px 10px;border-radius:999px;font-size:.75rem;font-weight:700}
  .grid{display:grid;gap:16px;margin-bottom:24px}
  .grid-4{grid-template-columns:repeat(auto-fill,minmax(160px,1fr))}
  .grid-2{grid-template-columns:repeat(auto-fill,minmax(320px,1fr))}
  .grid-3{grid-template-columns:repeat(auto-fill,minmax(260px,1fr))}
  .card{background:var(--bg2);border:1px solid var(--border);border-radius:12px;padding:18px}
  .stat-val{font-size:2.4rem;font-weight:800;line-height:1;margin-bottom:4px}
  .stat-label{font-size:.75rem;color:var(--muted);text-transform:uppercase;letter-spacing:.05em}
  .stat-sub{font-size:.7rem;color:var(--muted);margin-top:4px}
  .chart-wrap{position:relative;height:220px}
  .check-row{display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid var(--border)}
  .check-row:last-child{border:none}
  .dot{width:10px;height:10px;border-radius:50%;flex-shrink:0}
  .dot-ok{background:var(--green)} .dot-warn{background:var(--yellow)} .dot-bad{background:var(--red)}
  .check-name{flex:1;font-size:.82rem}
  .check-val{font-size:.78rem;color:var(--muted);text-align:right}
  .risk-bar-wrap{height:10px;background:var(--bg3);border-radius:5px;margin-top:8px;overflow:hidden}
  .risk-bar{height:100%;border-radius:5px;transition:width .5s}
  .section-title{font-size:.95rem;font-weight:700;color:var(--text);margin:0 0 4px}
  footer{text-align:center;color:var(--muted);font-size:.72rem;margin-top:32px}
</style>
</head>
<body>

<div class="header">
  <div>
    <h1>&#x1F6E1; Linux Security Audit</h1>
    <h2>$(hostname) &nbsp;&bull;&nbsp; $(uname -r) &nbsp;&bull;&nbsp; $(date)</h2>
  </div>
  <div style="text-align:right">
    <div style="font-size:2rem;font-weight:800;color:${risk_color}">${risk}/100</div>
    <span class="badge" style="background:${risk_color}22;color:${risk_color};border:1px solid ${risk_color}55">Risk: ${risk_label}</span>
    <div class="meta" style="margin-top:6px">Audit duration: ${audit_duration}s</div>
  </div>
</div>

<!-- ── KPI cards ────────────────────────────────────────── -->
<div class="grid grid-4">

  <div class="card">
    <div class="stat-val" style="color:$([ "${METRIC_OPEN_PORTS:-0}" -gt 10 ] && echo 'var(--yellow)' || echo 'var(--green)')">${METRIC_OPEN_PORTS:-0}</div>
    <div class="stat-label">Open TCP ports</div>
  </div>

  <div class="card">
    <div class="stat-val" style="color:$([ "${METRIC_SUID_FILES:-0}" -gt 30 ] && echo 'var(--yellow)' || echo 'var(--green)')">${METRIC_SUID_FILES:-0}</div>
    <div class="stat-label">SUID binaries</div>
  </div>

  <div class="card">
    <div class="stat-val" style="color:$([ "${METRIC_WORLD_WRITABLE:-0}" -gt 0 ] && echo 'var(--red)' || echo 'var(--green)')">${METRIC_WORLD_WRITABLE:-0}</div>
    <div class="stat-label">World-writable files</div>
  </div>

  <div class="card">
    <div class="stat-val" style="color:$([ "${METRIC_FAILED_LOGINS:-0}" -gt 20 ] && echo 'var(--red)' || echo 'var(--green)')">${METRIC_FAILED_LOGINS:-0}</div>
    <div class="stat-label">Failed logins</div>
  </div>

  <div class="card">
    <div class="stat-val" style="color:$([ "${METRIC_USERS_NO_PASS:-0}" -gt 0 ] && echo 'var(--red)' || echo 'var(--green)')">${METRIC_USERS_NO_PASS:-0}</div>
    <div class="stat-label">Users w/ empty password</div>
  </div>

  <div class="card">
    <div class="stat-val" style="color:$([ "${METRIC_ROOT_USERS:-1}" -gt 1 ] && echo 'var(--red)' || echo 'var(--green)')">${METRIC_ROOT_USERS:-1}</div>
    <div class="stat-label">Root-equiv (UID 0)</div>
  </div>

  <div class="card">
    <div class="stat-val" style="color:$([ "${METRIC_PENDING_UPDATES:-0}" -gt 0 ] && echo 'var(--yellow)' || echo 'var(--green)')">${METRIC_PENDING_UPDATES:-0}</div>
    <div class="stat-label">Pending sec. updates</div>
  </div>

  <div class="card">
    <div class="stat-val" style="color:var(--cyan)">${METRIC_RUNNING_PROCS:-0}</div>
    <div class="stat-label">Running processes</div>
  </div>

</div>

<!-- ── Charts row ───────────────────────────────────────── -->
<div class="grid grid-2">

  <div class="card">
    <h3>Resource usage</h3>
    <div class="chart-wrap"><canvas id="resourceChart"></canvas></div>
  </div>

  <div class="card">
    <h3>File system risk breakdown</h3>
    <div class="chart-wrap"><canvas id="fileRiskChart"></canvas></div>
  </div>

  <div class="card">
    <h3>Risk score — contributing factors</h3>
    <div class="chart-wrap"><canvas id="riskRadar"></canvas></div>
  </div>

  <div class="card">
    <h3>Findings by severity</h3>
    <div class="chart-wrap"><canvas id="severityChart"></canvas></div>
  </div>

</div>

<!-- ── Security checklist ───────────────────────────────── -->
<div class="grid grid-3">

  <div class="card">
    <h3>Access controls</h3>
    <div class="check-row">
      <span class="dot $([ "$METRIC_SSH_ROOT" != "yes" ] && echo 'dot-ok' || echo 'dot-bad')"></span>
      <span class="check-name">SSH root login</span>
      <span class="check-val">${METRIC_SSH_ROOT}</span>
    </div>
    <div class="check-row">
      <span class="dot $([ "${METRIC_ROOT_USERS:-1}" -le 1 ] && echo 'dot-ok' || echo 'dot-bad')"></span>
      <span class="check-name">UID-0 accounts</span>
      <span class="check-val">${METRIC_ROOT_USERS:-1}</span>
    </div>
    <div class="check-row">
      <span class="dot $([ "${METRIC_USERS_NO_PASS:-0}" -eq 0 ] && echo 'dot-ok' || echo 'dot-bad')"></span>
      <span class="check-name">Empty passwords</span>
      <span class="check-val">${METRIC_USERS_NO_PASS:-0} accounts</span>
    </div>
    <div class="check-row">
      <span class="dot $([ "${METRIC_FAILED_LOGINS:-0}" -le 20 ] && echo 'dot-ok' || echo 'dot-warn')"></span>
      <span class="check-name">Failed login attempts</span>
      <span class="check-val">${METRIC_FAILED_LOGINS:-0}</span>
    </div>
  </div>

  <div class="card">
    <h3>Network &amp; firewall</h3>
    <div class="check-row">
      <span class="dot $([ "$METRIC_UFW_STATUS" = "active" ] && echo 'dot-ok' || echo 'dot-bad')"></span>
      <span class="check-name">UFW firewall</span>
      <span class="check-val">${METRIC_UFW_STATUS}</span>
    </div>
    <div class="check-row">
      <span class="dot $([ "${METRIC_OPEN_PORTS:-0}" -le 10 ] && echo 'dot-ok' || echo 'dot-warn')"></span>
      <span class="check-name">Open ports</span>
      <span class="check-val">${METRIC_OPEN_PORTS:-0} listening</span>
    </div>
    <div class="check-row">
      <span class="dot $([ "${METRIC_PENDING_UPDATES:-0}" -eq 0 ] && echo 'dot-ok' || echo 'dot-warn')"></span>
      <span class="check-name">Security updates</span>
      <span class="check-val">${METRIC_PENDING_UPDATES:-0} pending</span>
    </div>
  </div>

  <div class="card">
    <h3>MAC &amp; kernel hardening</h3>
    <div class="check-row">
      <span class="dot $([ "$METRIC_SELINUX" = "enabled" ] && echo 'dot-ok' || echo 'dot-warn')"></span>
      <span class="check-name">SELinux</span>
      <span class="check-val">${METRIC_SELINUX}</span>
    </div>
    <div class="check-row">
      <span class="dot $([ "$METRIC_APPARMOR" = "loaded" ] && echo 'dot-ok' || echo 'dot-warn')"></span>
      <span class="check-name">AppArmor</span>
      <span class="check-val">${METRIC_APPARMOR}</span>
    </div>
    <div class="check-row">
      <span class="dot $([ "${METRIC_SUID_FILES:-0}" -le 30 ] && echo 'dot-ok' || echo 'dot-warn')"></span>
      <span class="check-name">SUID binaries</span>
      <span class="check-val">${METRIC_SUID_FILES:-0} found</span>
    </div>
    <div class="check-row">
      <span class="dot $([ "${METRIC_WORLD_WRITABLE:-0}" -eq 0 ] && echo 'dot-ok' || echo 'dot-bad')"></span>
      <span class="check-name">World-writable files</span>
      <span class="check-val">${METRIC_WORLD_WRITABLE:-0} found</span>
    </div>
  </div>

</div>

<footer>Generated by Linux Audit Tool v4.0 &mdash; $(date) &mdash; For internal use only</footer>

<script>
const C={green:'#22c55e',yellow:'#f59e0b',red:'#ef4444',blue:'#3b82f6',purple:'#a855f7',cyan:'#06b6d4',bg3:'#334155',text:'#94a3b8'};
const defaults={responsive:true,maintainAspectRatio:false,plugins:{legend:{labels:{color:C.text,font:{size:11}}}}};

// Resource usage doughnut
new Chart(document.getElementById('resourceChart'),{
  type:'doughnut',
  data:{
    labels:['CPU load (×10)','Mem used %','Disk used %','Idle'],
    datasets:[{
      data:[Math.min(parseFloat('${METRIC_CPU_LOAD:-0}')*10,100).toFixed(1), ${mem_pct}, ${METRIC_DISK_USAGE:-0}, Math.max(0,100-${mem_pct})],
      backgroundColor:[C.purple,C.blue,C.cyan,C.bg3],
      borderWidth:0,hoverOffset:4
    }]
  },
  options:{...defaults,cutout:'65%'}
});

// File risk bar
new Chart(document.getElementById('fileRiskChart'),{
  type:'bar',
  data:{
    labels:['SUID files','World-writable','Empty-pwd users','Root accounts','Failed logins ÷10'],
    datasets:[{
      label:'Count',
      data:[${METRIC_SUID_FILES:-0},${METRIC_WORLD_WRITABLE:-0},${METRIC_USERS_NO_PASS:-0},${METRIC_ROOT_USERS:-1},Math.round(${METRIC_FAILED_LOGINS:-0}/10)],
      backgroundColor:[C.purple,C.red,C.red,C.yellow,C.yellow],
      borderRadius:6,borderWidth:0
    }]
  },
  options:{
    ...defaults,
    indexAxis:'y',
    scales:{x:{ticks:{color:C.text},grid:{color:'#334155'}},y:{ticks:{color:C.text},grid:{display:false}}}
  }
});

// Risk radar
new Chart(document.getElementById('riskRadar'),{
  type:'radar',
  data:{
    labels:['SSH','Firewall','Users','Files','MAC/SELinux','Updates'],
    datasets:[{
      label:'Risk level',
      data:[
        $( [ "$METRIC_SSH_ROOT" = "yes" ] && echo 100 || echo 5),
        $( [ "$METRIC_UFW_STATUS" = "inactive" ] && echo 80 || echo 10),
        $(echo "${METRIC_USERS_NO_PASS:-0} * 20 + ${METRIC_ROOT_USERS:-1} * 5" | bc 2>/dev/null || echo 10),
        $(echo "${METRIC_WORLD_WRITABLE:-0} * 2 + ${METRIC_SUID_FILES:-0}" | bc 2>/dev/null | awk '{if($1>100)print 100;else print $1}'),
        $( [ "$METRIC_SELINUX" != "enabled" ] && [ "$METRIC_APPARMOR" != "loaded" ] && echo 80 || echo 15),
        $(echo "${METRIC_PENDING_UPDATES:-0} * 5" | bc 2>/dev/null | awk '{if($1>100)print 100;else print $1}')
      ],
      fill:true,
      backgroundColor:'rgba(239,68,68,.15)',
      borderColor:'#ef4444',
      pointBackgroundColor:'#ef4444',
      pointRadius:4
    }]
  },
  options:{
    ...defaults,
    scales:{r:{ticks:{color:C.text,backdropColor:'transparent',stepSize:25},grid:{color:'#334155'},pointLabels:{color:C.text,font:{size:11}},min:0,max:100}}
  }
});

// Severity pie
const critCount = $( val=0; [ "$METRIC_SSH_ROOT" = "yes" ] && val=$((val+1)); [ "$METRIC_UFW_STATUS"="inactive" ] && val=$((val+1)); [ "${METRIC_USERS_NO_PASS:-0}" -gt 0 ] && val=$((val+1)); echo $val );
const highCount = $( val=0; [ "${METRIC_WORLD_WRITABLE:-0}" -gt 0 ] && val=$((val+1)); [ "${METRIC_FAILED_LOGINS:-0}" -gt 50 ] && val=$((val+1)); echo $val );
const medCount  = $( val=0; [ "${METRIC_SUID_FILES:-0}" -gt 30 ] && val=$((val+1)); [ "${METRIC_PENDING_UPDATES:-0}" -gt 0 ] && val=$((val+1)); echo $val );
const lowCount  = Math.max(1, 8 - critCount - highCount - medCount);
new Chart(document.getElementById('severityChart'),{
  type:'doughnut',
  data:{
    labels:['Critical','High','Medium','Low / Info'],
    datasets:[{
      data:[critCount,highCount,medCount,lowCount],
      backgroundColor:[C.red,C.yellow,C.purple,C.green],
      borderWidth:0,hoverOffset:4
    }]
  },
  options:{...defaults,cutout:'60%'}
});
</script>
</body>
</html>
HTMLEOF
    echo -e "${GREEN}[+] HTML dashboard saved: ${YELLOW}$html_file${NC}"
}

show_progress() {
    local current=$1 total=$2 description=$3
    local percent=$((current * 100 / total))
    if [ $USE_COLORS -eq 1 ]; then
        echo -e "${CYAN}Progress: ${GREEN}${percent}%${NC} — ${description}"
    else
        echo "Progress: ${percent}% — ${description}"
    fi
}

main() {
    local total_sections=5 current_section=0

    banner

    if [[ $EUID -eq 0 ]]; then
        echo -e "${GREEN}[+] Running as root — full audit available${NC}"
    else
        echo -e "${YELLOW}[!] Not root — some checks will be limited${NC}"
        echo -e "${YELLOW}[!] For a complete audit run: sudo $0${NC}"
    fi

    auto_install_audit_tools

    choose_output_format
    echo -e "${BLUE}[*] Initialising audit...${NC}"
    initialize_output

    current_section=$((current_section + 1))
    show_progress $current_section $total_sections "System Security Audit"
    system_security_audit

    current_section=$((current_section + 1))
    show_progress $current_section $total_sections "Network Security Audit"
    network_security_audit

    current_section=$((current_section + 1))
    show_progress $current_section $total_sections "Port Scanning Analysis"
    port_scanning_audit

    current_section=$((current_section + 1))
    show_progress $current_section $total_sections "Generating Security Summary"
    generate_security_summary

    # ── Generate HTML dashboard ───────────────────────────────────────────────
    echo -e "\n${BLUE}[*] Generating visual HTML dashboard...${NC}"
    generate_html_dashboard "$OUTPUT_FILE_HTML"

    echo -e "\n${BLUE}[*] Saving report(s)...${NC}"
    case $OUTPUT_FORMAT in
        txt)
            cp "$TEMP_FILE" "$OUTPUT_FILE_TXT"
            echo -e "${GREEN}[+] Report saved: ${YELLOW}$OUTPUT_FILE_TXT${NC}"
            FINAL_FILE="$OUTPUT_FILE_TXT" ;;
        pdf)
            cp "$TEMP_FILE" "$OUTPUT_FILE_TXT"
            if convert_to_pdf "$OUTPUT_FILE_TXT" "$OUTPUT_FILE_PDF"; then
                rm -f "$OUTPUT_FILE_TXT"
                echo -e "${GREEN}[+] Report saved: ${YELLOW}$OUTPUT_FILE_PDF${NC}"
                FINAL_FILE="$OUTPUT_FILE_PDF"
            else
                echo -e "${YELLOW}[!] PDF failed, keeping TXT: $OUTPUT_FILE_TXT${NC}"
                FINAL_FILE="$OUTPUT_FILE_TXT"
            fi ;;
        both)
            cp "$TEMP_FILE" "$OUTPUT_FILE_TXT"
            echo -e "${GREEN}[+] TXT saved: ${YELLOW}$OUTPUT_FILE_TXT${NC}"
            if convert_to_pdf "$OUTPUT_FILE_TXT" "$OUTPUT_FILE_PDF"; then
                echo -e "${GREEN}[+] PDF saved: ${YELLOW}$OUTPUT_FILE_PDF${NC}"
                FINAL_FILE="$OUTPUT_FILE_TXT and $OUTPUT_FILE_PDF"
            else
                echo -e "${YELLOW}[!] PDF failed, keeping TXT only${NC}"
                FINAL_FILE="$OUTPUT_FILE_TXT"
            fi ;;
    esac

    rm -f "$TEMP_FILE"

    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    AUDIT COMPLETED SUCCESSFULLY                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}[+] Results: ${YELLOW}$FINAL_FILE${NC}"
    echo -e "${GREEN}[+] Time   : ${YELLOW}$(($(date +%s) - SCRIPT_START_TIME))s${NC}"
    for f in "$OUTPUT_FILE_TXT" "$OUTPUT_FILE_PDF" "$OUTPUT_FILE_HTML"; do
        [ -f "$f" ] && echo -e "${GREEN}[+] Size   : ${YELLOW}$(du -h "$f" | cut -f1) — $f${NC}"
    done
    echo -e "${CYAN}[*] Open the .html file in a browser for an interactive security dashboard.${NC}"
    echo -e "${CYAN}[*] Review the report carefully and remediate findings.${NC}"
}

show_help() {
    echo -e "${CYAN}Linux Security Audit Tool v3.1${NC}"
    echo ""
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help"
    echo "  -v, --verbose   Verbose output"
    echo "  -q, --quiet     Minimal console output"
    echo "  -f, --format    Output format: txt | pdf | both"
    echo ""
    echo "Recommended: sudo $0"
}

# Argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)   show_help; exit 0 ;;
        -v|--verbose) VERBOSE=1; shift ;;
        -q|--quiet)  QUIET=1; shift ;;
        -f|--format)
            if [[ $2 =~ ^(txt|pdf|both)$ ]]; then
                OUTPUT_FORMAT=$2
            else
                echo -e "${RED}[-] Invalid format. Use txt, pdf, or both.${NC}"; exit 1
            fi
            shift 2 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; show_help; exit 1 ;;
    esac
done

if [ -z "$OUTPUT_FILE_TXT" ]; then
    timestamp=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE_TXT="Linux_security_audit_${timestamp}.txt"
    OUTPUT_FILE_PDF="Linux_security_audit_${timestamp}.pdf"
    OUTPUT_FILE_HTML="Linux_security_audit_${timestamp}.html"
fi

main
exit 0

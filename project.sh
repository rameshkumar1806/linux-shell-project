#!/bin/bash

# ============================================================
#   Linux System Administration Toolkit
#   Author: Shell Script Project
#   Description: A comprehensive menu-driven admin utility
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

LOG_FILE="$HOME/toolkit_logs/activity.log"
mkdir -p "$HOME/toolkit_logs"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

pause() {
    echo ""
    read -rp "$(echo -e "${YELLOW}Press Enter to continue...${RESET}")"
}

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║      🛠  Linux SysAdmin Toolkit  🛠              ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ─────────────────────────────────────────
# MODULE 1: System Monitoring
# ─────────────────────────────────────────
monitor_menu() {
    while true; do
        print_header
        echo -e "${BLUE}${BOLD}  [ System Monitoring ]${RESET}"
        echo ""
        echo "  1. CPU & Memory Usage"
        echo "  2. Disk Usage"
        echo "  3. Running Processes (Top 10)"
        echo "  4. Network Interfaces & IP"
        echo "  5. System Uptime & Load"
        echo "  6. Check Open Ports"
        echo "  0. Back to Main Menu"
        echo ""
        read -rp "  Choose an option: " choice

        case $choice in
            1)
                echo -e "\n${GREEN}--- CPU & Memory ---${RESET}"
                echo -e "${YELLOW}CPU Info:${RESET}"
                lscpu | grep -E "Model name|CPU\(s\)|Thread|Socket"
                echo ""
                echo -e "${YELLOW}Memory Usage:${RESET}"
                free -h
                log "Viewed CPU & Memory"
                pause ;;
            2)
                echo -e "\n${GREEN}--- Disk Usage ---${RESET}"
                df -hT | grep -v tmpfs
                echo ""
                echo -e "${YELLOW}Top 5 Large Directories in Home:${RESET}"
                du -sh "$HOME"/*/ 2>/dev/null | sort -rh | head -5
                log "Viewed Disk Usage"
                pause ;;
            3)
                echo -e "\n${GREEN}--- Top 10 Processes by CPU ---${RESET}"
                ps aux --sort=-%cpu | awk 'NR<=11 {printf "%-10s %-8s %-6s %-6s %s\n", $1,$2,$3,$4,$11}'
                log "Viewed Processes"
                pause ;;
            4)
                echo -e "\n${GREEN}--- Network Interfaces ---${RESET}"
                ip -brief addr show
                echo ""
                echo -e "${YELLOW}Default Gateway:${RESET}"
                ip route | grep default
                log "Viewed Network Info"
                pause ;;
            5)
                echo -e "\n${GREEN}--- Uptime & Load ---${RESET}"
                uptime -p
                echo ""
                cat /proc/loadavg
                log "Viewed Uptime"
                pause ;;
            6)
                echo -e "\n${GREEN}--- Open Ports ---${RESET}"
                if command -v ss &>/dev/null; then
                    ss -tuln | grep LISTEN
                else
                    netstat -tuln 2>/dev/null || echo "netstat not available"
                fi
                log "Viewed Open Ports"
                pause ;;
            0) break ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
        esac
    done
}

# ─────────────────────────────────────────
# MODULE 2: File Management
# ─────────────────────────────────────────
file_menu() {
    while true; do
        print_header
        echo -e "${BLUE}${BOLD}  [ File Management ]${RESET}"
        echo ""
        echo "  1. Find Large Files (>50MB)"
        echo "  2. Find Files by Extension"
        echo "  3. Backup a Directory"
        echo "  4. Remove Old Logs (>7 days)"
        echo "  5. Count Files in Directory"
        echo "  6. Find Duplicate Files (by name)"
        echo "  0. Back to Main Menu"
        echo ""
        read -rp "  Choose an option: " choice

        case $choice in
            1)
                read -rp "  Search in directory (default: $HOME): " dir
                dir=${dir:-$HOME}
                echo -e "\n${GREEN}--- Files larger than 50MB ---${RESET}"
                find "$dir" -type f -size +50M 2>/dev/null -exec ls -lh {} \; | awk '{print $5, $9}'
                log "Searched large files in $dir"
                pause ;;
            2)
                read -rp "  Enter extension (e.g. txt, sh, log): " ext
                read -rp "  Search in (default: $HOME): " dir
                dir=${dir:-$HOME}
                echo -e "\n${GREEN}--- .$ext files in $dir ---${RESET}"
                find "$dir" -type f -name "*.$ext" 2>/dev/null
                log "Searched .$ext files"
                pause ;;
            3)
                read -rp "  Source directory to backup: " src
                read -rp "  Backup destination (default: $HOME/backups): " dest
                dest=${dest:-$HOME/backups}
                mkdir -p "$dest"
                timestamp=$(date '+%Y%m%d_%H%M%S')
                bname=$(basename "$src")
                tar -czf "$dest/${bname}_$timestamp.tar.gz" "$src" 2>/dev/null && \
                    echo -e "${GREEN}Backup created: $dest/${bname}_$timestamp.tar.gz${RESET}" || \
                    echo -e "${RED}Backup failed!${RESET}"
                log "Backed up $src to $dest"
                pause ;;
            4)
                read -rp "  Directory to clean (default: /var/log): " dir
                dir=${dir:-/var/log}
                echo -e "\n${YELLOW}Old log files (>7 days):${RESET}"
                find "$dir" -name "*.log" -mtime +7 2>/dev/null
                read -rp "  Delete these? (y/n): " confirm
                if [[ $confirm == "y" ]]; then
                    find "$dir" -name "*.log" -mtime +7 -delete 2>/dev/null
                    echo -e "${GREEN}Old logs deleted.${RESET}"
                    log "Deleted old logs from $dir"
                fi
                pause ;;
            5)
                read -rp "  Directory to count (default: .): " dir
                dir=${dir:-.}
                total=$(find "$dir" -type f 2>/dev/null | wc -l)
                dirs=$(find "$dir" -type d 2>/dev/null | wc -l)
                echo -e "\n${GREEN}Files: $total | Directories: $dirs${RESET}"
                log "Counted files in $dir"
                pause ;;
            6)
                read -rp "  Search in (default: $HOME): " dir
                dir=${dir:-$HOME}
                echo -e "\n${GREEN}--- Duplicate filenames ---${RESET}"
                find "$dir" -type f 2>/dev/null | sed 's|.*/||' | sort | uniq -d
                log "Found duplicates in $dir"
                pause ;;
            0) break ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
        esac
    done
}

# ─────────────────────────────────────────
# MODULE 3: User Management
# ─────────────────────────────────────────
user_menu() {
    while true; do
        print_header
        echo -e "${BLUE}${BOLD}  [ User Management ]${RESET}"
        echo ""
        echo "  1. List All Users"
        echo "  2. List Logged-in Users"
        echo "  3. Add New User"
        echo "  4. Delete a User"
        echo "  5. Change User Password"
        echo "  6. Show User Info"
        echo "  0. Back to Main Menu"
        echo ""
        read -rp "  Choose an option: " choice

        case $choice in
            1)
                echo -e "\n${GREEN}--- System Users ---${RESET}"
                awk -F: '$3 >= 1000 && $1 != "nobody" {print $1, "(UID:"$3")"}' /etc/passwd
                log "Listed users"
                pause ;;
            2)
                echo -e "\n${GREEN}--- Currently Logged In ---${RESET}"
                who
                log "Viewed logged-in users"
                pause ;;
            3)
                read -rp "  New username: " uname
                if id "$uname" &>/dev/null; then
                    echo -e "${RED}User already exists!${RESET}"
                else
                    sudo useradd -m -s /bin/bash "$uname" && \
                        echo -e "${GREEN}User '$uname' created.${RESET}" || \
                        echo -e "${RED}Failed (run as root/sudo)${RESET}"
                    log "Created user $uname"
                fi
                pause ;;
            4)
                read -rp "  Username to delete: " uname
                if ! id "$uname" &>/dev/null; then
                    echo -e "${RED}User not found!${RESET}"
                else
                    read -rp "  Also remove home dir? (y/n): " rmhome
                    if [[ $rmhome == "y" ]]; then
                        sudo userdel -r "$uname" 2>/dev/null
                    else
                        sudo userdel "$uname" 2>/dev/null
                    fi
                    echo -e "${GREEN}User '$uname' deleted.${RESET}"
                    log "Deleted user $uname"
                fi
                pause ;;
            5)
                read -rp "  Username: " uname
                sudo passwd "$uname"
                log "Changed password for $uname"
                pause ;;
            6)
                read -rp "  Username: " uname
                if id "$uname" &>/dev/null; then
                    echo -e "\n${GREEN}--- Info for $uname ---${RESET}"
                    id "$uname"
                    grep "^$uname:" /etc/passwd
                    echo -e "${YELLOW}Groups:${RESET} $(groups "$uname")"
                else
                    echo -e "${RED}User not found!${RESET}"
                fi
                log "Viewed info for $uname"
                pause ;;
            0) break ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
        esac
    done
}

# ─────────────────────────────────────────
# MODULE 4: Process Management
# ─────────────────────────────────────────
process_menu() {
    while true; do
        print_header
        echo -e "${BLUE}${BOLD}  [ Process Management ]${RESET}"
        echo ""
        echo "  1. List All Running Processes"
        echo "  2. Search Process by Name"
        echo "  3. Kill Process by Name"
        echo "  4. Kill Process by PID"
        echo "  5. Show Process Tree"
        echo "  0. Back to Main Menu"
        echo ""
        read -rp "  Choose an option: " choice

        case $choice in
            1)
                ps aux | head -20
                log "Listed all processes"
                pause ;;
            2)
                read -rp "  Process name to search: " pname
                echo -e "\n${GREEN}--- Matching Processes ---${RESET}"
                pgrep -la "$pname" 2>/dev/null || echo "No process found."
                log "Searched process: $pname"
                pause ;;
            3)
                read -rp "  Process name to kill: " pname
                if pgrep "$pname" &>/dev/null; then
                    pkill "$pname" && echo -e "${GREEN}Process '$pname' killed.${RESET}"
                    log "Killed process $pname"
                else
                    echo -e "${RED}No such process running.${RESET}"
                fi
                pause ;;
            4)
                read -rp "  Enter PID to kill: " pid
                if kill -0 "$pid" 2>/dev/null; then
                    kill "$pid" && echo -e "${GREEN}Process $pid killed.${RESET}"
                    log "Killed PID $pid"
                else
                    echo -e "${RED}PID not found.${RESET}"
                fi
                pause ;;
            5)
                echo -e "\n${GREEN}--- Process Tree ---${RESET}"
                pstree -p 2>/dev/null || ps axf
                log "Viewed process tree"
                pause ;;
            0) break ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
        esac
    done
}

# ─────────────────────────────────────────
# MODULE 5: System Health Report
# ─────────────────────────────────────────
generate_report() {
    REPORT="$HOME/toolkit_logs/report_$(date '+%Y%m%d_%H%M%S').txt"
    {
        echo "========================================"
        echo "  SYSTEM HEALTH REPORT"
        echo "  Generated: $(date)"
        echo "========================================"
        echo ""
        echo "--- HOSTNAME & OS ---"
        hostnamectl 2>/dev/null || uname -a
        echo ""
        echo "--- UPTIME ---"
        uptime
        echo ""
        echo "--- CPU ---"
        lscpu | grep -E "Model name|CPU\(s\)"
        echo ""
        echo "--- MEMORY ---"
        free -h
        echo ""
        echo "--- DISK USAGE ---"
        df -hT | grep -v tmpfs
        echo ""
        echo "--- TOP 5 CPU PROCESSES ---"
        ps aux --sort=-%cpu | awk 'NR<=6 {printf "%-15s %-8s %-6s\n", $11,$2,$3}'
        echo ""
        echo "--- LOGGED IN USERS ---"
        who
        echo ""
        echo "--- OPEN PORTS ---"
        ss -tuln 2>/dev/null | grep LISTEN | head -10
        echo ""
        echo "========================================"
        echo "  END OF REPORT"
        echo "========================================"
    } > "$REPORT"

    echo -e "${GREEN}Report saved to: $REPORT${RESET}"
    log "Generated health report: $REPORT"
    pause
}

# ─────────────────────────────────────────
# MAIN MENU
# ─────────────────────────────────────────
main_menu() {
    while true; do
        print_header
        echo -e "  ${BOLD}Select a Module:${RESET}"
        echo ""
        echo -e "  ${CYAN}1.${RESET} 📊  System Monitoring"
        echo -e "  ${CYAN}2.${RESET} 📁  File Management"
        echo -e "  ${CYAN}3.${RESET} 👤  User Management"
        echo -e "  ${CYAN}4.${RESET} ⚙️   Process Management"
        echo -e "  ${CYAN}5.${RESET} 📄  Generate System Health Report"
        echo -e "  ${CYAN}6.${RESET} 📋  View Activity Log"
        echo -e "  ${CYAN}0.${RESET} 🚪  Exit"
        echo ""
        read -rp "  Choose a module: " choice

        case $choice in
            1) monitor_menu ;;
            2) file_menu ;;
            3) user_menu ;;
            4) process_menu ;;
            5) generate_report ;;
            6)
                echo -e "\n${GREEN}--- Activity Log ---${RESET}"
                tail -30 "$LOG_FILE" 2>/dev/null || echo "No logs yet."
                pause ;;
            0)
                echo -e "\n${GREEN}Goodbye! Toolkit exited.${RESET}\n"
                log "Toolkit exited"
                exit 0 ;;
            *) echo -e "${RED}Invalid option!${RESET}"; sleep 1 ;;
        esac
    done
}

# Entry point
log "Toolkit started"
main_menu

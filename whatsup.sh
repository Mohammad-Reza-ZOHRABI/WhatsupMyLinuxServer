#!/bin/bash

# Function to check command existence
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "Error: Required command '$1' is not available. Skipping."
        return 1
    fi
    return 0
}

# Function to safely run commands with error handling
run_command() {
    if ! $1; then
        echo "Error executing command: $1. Skipping."
    fi
}

# Attempt to extract the last login time and format it
formatted_date=""
if check_command "last"; then
    last_login=$(last -n 2 | awk 'NR==2{if ($6 ~ /:/) print $5, $6, $7; else print $6, $7, $8}')
    last_login_reformatted=$(echo $last_login | awk '{print $1, $2, $4, $3":00"}') 2>/dev/null
    if formatted_date=$(date -d "$last_login_reformatted" +"%Y-%m-%d %H:%M:%S" 2>/dev/null); then
        echo "Overview since last login ($formatted_date):"
    else
        echo "Failed to parse the last login time. Some date-specific features will be skipped."
    fi
fi

echo "============================================"
echo

echo "Overall System Health:"
echo "----------------------"

# Show system uptime and load averages
check_command "uptime" && run_command "uptime"
echo

# Show available disk space
check_command "df" && run_command "df -h"
echo

# Show memory and swap usage
check_command "free" && run_command "free -h"
echo

# Show network statistics
check_command "netstat" && run_command "netstat -i"
echo

# Show logged-in users since last login
if [ -n "$formatted_date" ]; then
    if check_command "last"; then
        echo "Logged-in Users:"
        echo "----------------"
        last -w | awk -v date="$formatted_date" '$0 ~ date,0'
        echo
    fi
else
    echo "Skipping logged-in users since last login due to missing date."
fi

# Show SSH authentication-related activities since last login using /var/log/auth.log
if [ -n "$formatted_date" ] && check_command "sudo" && [ -f /var/log/auth.log ]; then
    echo "SSH Auth Logs:"
    echo "--------------"
    sudo awk -v date="$formatted_date" '$0 > date' /var/log/auth.log | grep 'Accepted'
    echo
else
    echo "Skipping SSH authentication logs due to missing date or permissions."
fi

# Show the last 20 logs of Fail2Ban
if check_command "sudo" && [ -f /var/log/fail2ban.log ]; then
    echo "Last 20 Fail2Ban Logs:"
    echo "----------------------"
    sudo tail -n 20 /var/log/fail2ban.log
    echo
else
    echo "Skipping Fail2Ban logs due to missing file or permissions."
fi

# Show top processes by CPU and memory usage
check_command "top" && run_command "top -b -n 1 | head -n 12"

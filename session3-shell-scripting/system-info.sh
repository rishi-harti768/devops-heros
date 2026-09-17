#!/bin/bash

# Store information in variables
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

# Display system information
echo "===== System Information ====="
echo "Current Date : $current_date"
echo "Hostname     : $host_name"
echo "Username     : $user_name"

echo
echo "===== Disk Usage ====="
df -h

echo
echo "===== Running Processes ====="
ps -ef

# Take user input
echo
read -p "Enter a directory name: dir_name"

# Create directory
mkdir -p "$dir_name"
echo "Directory '$dir_name' created."

# Take file name input
read -p "Enter a file name: file_name"

# Create file
touch "$dir_name/$file_name"

# Store running processes in the file
ps -ef > "$dir_name/$file_name"

echo "Running processes have been saved to $dir_name/$file_name"
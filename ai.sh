#!/bin/zsh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# History directory
HISTORY_DIR="$HOME/.term_llm"
HISTORY_FILE="$HISTORY_DIR/history.txt"

# Dangerous command patterns
DANGEROUS_PATTERNS=(
    "rm -rf"
    "rm -r"
    "rm -f"
    "rm -rf /"
    "rm -r /"
    "rm -f /"
    "dd if="
    "dd of="
    "mkfs"
    "mkfs."
    "format"
    "erase"
    "wipe"
    "delete"
    "destroy"
    "overwrite"
    "shred"
    "mv /"
    "cp /"
    "chmod -R"
    "chown -R"
    "chgrp -R"
    "> /dev/"
    "> /proc/"
    "> /sys/"
    "> /etc/"
    "> /var/"
    "> /usr/"
    "> /bin/"
    "> /sbin/"
    "> /lib/"
    "> /opt/"
    "> /root/"
    "> /home/"
    "> /boot/"
    "> /media/"
    "> /mnt/"
    "> /srv/"
    "> /tmp/"
    "find . -type d -exec"
    "find . -type f -exec"
    "find . -delete"
    "find / -delete"
    "find . -exec rm"
    "find / -exec rm"
)

# Help function
show_help() {
    cat << EOF
Usage: $(basename $0) [OPTIONS] "your prompt"

A CLI tool that converts natural language to shell commands using LLM.

Options:
    -h, --help          Show this help message
    -m, --model MODEL   Specify the model to use (default: llama3.1:8b)
    --history [SEARCH]  Show command history, optionally filtered by SEARCH term
    --clear-history     Clear the command history
    
Environment variables:
    TERM_LLM_MODEL     Set default model (overrides built-in default)
    
Example:
    $(basename $0) "list all PDF files in current directory"
EOF
}

# History viewing function
show_history() {
    if [ ! -f "$HISTORY_FILE" ]; then
        echo -e "${YELLOW}No history found.${NC}"
        return
    fi

    if [ -n "$1" ]; then
        echo -e "${BLUE}Searching history for: $1${NC}\n"
        grep -i "$1" "$HISTORY_FILE" | while IFS='|' read -r date prompt command; do
            echo -e "${YELLOW}Date:${NC} $date"
            echo -e "${YELLOW}Prompt:${NC} $prompt"
            echo -e "${YELLOW}Command:${NC} $command"
            echo "----------------------------------------"
        done
    else
        echo -e "${BLUE}Command History:${NC}\n"
        while IFS='|' read -r date prompt command; do
            echo -e "${YELLOW}Date:${NC} $date"
            echo -e "${YELLOW}Prompt:${NC} $prompt"
            echo -e "${YELLOW}Command:${NC} $command"
            echo "----------------------------------------"
        done < "$HISTORY_FILE"
    fi
}

# Clear history function
clear_history() {
    if [ -f "$HISTORY_FILE" ]; then
        rm "$HISTORY_FILE"
        echo -e "${GREEN}History cleared.${NC}"
    else
        echo -e "${YELLOW}No history to clear.${NC}"
    fi
}

# Error handling function
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Check if Ollama is running
check_ollama() {
    if ! curl -s "http://localhost:11434/api/health" > /dev/null; then
        error_exit "Ollama service is not running. Please start it first."
    fi
}

# Sanitize input for JSON
sanitize_json() {
    local input="$1"
    # Escape backslashes, quotes, and control characters
    echo "$input" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\x1b/\\u001b/g' -e 's/\x0d/\\r/g' -e 's/\x0a/\\n/g'
}

# Check for dangerous commands
check_dangerous_command() {
    local command="$1"
    local prompt="$2"
    
    # Check for dangerous patterns
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if [[ "$command" == *"$pattern"* ]]; then
            echo -e "${RED}WARNING: This command contains potentially dangerous operations:${NC}"
            echo -e "${RED}Pattern detected: $pattern${NC}"
            echo -e "${RED}Original prompt: $prompt${NC}"
            echo -e "${RED}Command: $command${NC}"
            echo -e "${YELLOW}If you really need to run this command, please type it manually.${NC}"
            return 1
        fi
    done
    
    # Check for root operations
    if [[ "$command" == *"sudo "* ]] || [[ "$command" == *"su "* ]]; then
        echo -e "${YELLOW}WARNING: This command requires elevated privileges.${NC}"
        echo -e "${YELLOW}Please review carefully before proceeding.${NC}"
        return 0
    fi
    
    # Check for recursive operations
    if [[ "$command" == *" -R "* ]] || [[ "$command" == *" -r "* ]] || [[ "$command" == *" -rf "* ]]; then
        echo -e "${YELLOW}WARNING: This command performs recursive operations.${NC}"
        echo -e "${YELLOW}Please review carefully before proceeding.${NC}"
        return 0
    fi
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -m|--model)
            MODEL_NAME="$2"
            shift 2
            ;;
        --history)
            if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
                show_history "$2"
            else
                show_history
            fi
            exit 0
            ;;
        --clear-history)
            clear_history
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# Check for command line arguments
if [ "$#" -eq 0 ]; then
    show_help
    exit 1
fi

# Join all remaining arguments into a single prompt string
USER_PROMPT="$*"

# Set model name from environment variable or default
MODEL_NAME=${MODEL_NAME:-${TERM_LLM_MODEL:-"llama3.1:8b"}}

# System prompt to enforce shell-only output
SYSTEM_PROMPT="You are a terminal assistant. Only output the correct Unix shell command to achieve the user's goal. Do not include explanations, markdown formatting, or anything else—only output the raw command. If you're not sure about a command or if it might be dangerous, output 'UNSAFE' instead."

# Check if Ollama is running
check_ollama

# Sanitize inputs for JSON
SANITIZED_PROMPT=$(sanitize_json "$USER_PROMPT")
SANITIZED_SYSTEM=$(sanitize_json "$SYSTEM_PROMPT")

# Create JSON payload with proper escaping
PAYLOAD=$(jq -n \
    --arg model "$MODEL_NAME" \
    --arg system "$SANITIZED_SYSTEM" \
    --arg user "$SANITIZED_PROMPT" \
    '{
        model: $model,
        messages: [
            {role: "system", content: $system},
            {role: "user", content: $user}
        ],
        stream: false
    }') || error_exit "Failed to create JSON payload. Please check your input for special characters."

# Send request to ollama via curl
RESPONSE=$(curl -s http://localhost:11434/api/chat -d "$PAYLOAD") || error_exit "Failed to communicate with Ollama"

# Extract the command
COMMAND=$(echo "$RESPONSE" | jq -r '.message.content') || error_exit "Failed to parse Ollama response. The response might contain invalid characters."

# Safety check
if [[ "$COMMAND" == "UNSAFE" ]]; then
    error_exit "The requested command was deemed unsafe to execute"
fi

# Check for dangerous commands
if ! check_dangerous_command "$COMMAND" "$USER_PROMPT"; then
    exit 1
fi

# Save to history file
mkdir -p "$HISTORY_DIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') | $USER_PROMPT | $COMMAND" >> "$HISTORY_FILE"

# Display the command and ask for confirmation
echo -e "\n${BLUE}Here's the command:${NC}"
echo -e "${GREEN}$COMMAND${NC}"
echo
read "CONFIRM?Shall I run it? [y/N] "

# Check confirmation
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "\n${BLUE}Running command...${NC}"
    eval "$COMMAND"
else
    echo -e "\n${BLUE}Aborted. Nothing was run.${NC}"
fi
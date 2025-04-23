# Term LLM

A command-line tool that converts natural language into shell commands using LLMs via Ollama. This tool makes it easier to execute complex shell commands by describing what you want to do in plain English.

## Features

- 🤖 Natural language to shell command conversion
- 🛡️ Advanced safety checks for potentially dangerous commands
- 📝 Command history with search functionality
- 🎨 Colorized output for better readability
- 🔧 Configurable model selection
- ✅ Interactive command confirmation
- 🚫 Protection against destructive operations
- 🔍 Detection of recursive and privileged operations

## Safety Features

The tool includes multiple layers of protection:

- **Command Validation**: Checks for dangerous patterns like:
  - Destructive commands (`rm -rf`, `dd`, etc.)
  - System file operations
  - Recursive operations
  - Privilege escalation
  - Dangerous `find` commands
- **Interactive Confirmation**: Always asks for confirmation before execution
- **History Tracking**: Maintains a log of all commands for auditing
- **Special Character Handling**: Properly escapes special characters in input
- **Warning System**: Color-coded warnings for different types of dangerous operations

## Prerequisites

- [Ollama](https://ollama.ai/) installed and running
- `jq` command-line JSON processor
- `curl` for API communication
- Zsh shell

## Installation

1. Make the script executable:
```bash
chmod +x ai.sh
```

2. (Optional) Add it to your PATH for global access:
```bash
sudo ln -s "$(pwd)/ai.sh" /usr/local/bin/term-llm
```

## Usage

### Basic Usage

```bash
./ai.sh "your prompt describing what you want to do"
```

For example:
```bash
./ai.sh "list all PDF files in the current directory"
```

### Command History

View your command history:
```bash
./ai.sh --history
```

Search through history:
```bash
./ai.sh --history "pdf"
```

Clear history:
```bash
./ai.sh --clear-history
```

### Model Selection

Specify a different model:
```bash
./ai.sh -m "llama3.1:16b" "your prompt"
```

Or set a default model via environment variable:
```bash
export TERM_LLM_MODEL="llama3.1:16b"
./ai.sh "your prompt"
```

### Help

View help message:
```bash
./ai.sh --help
```

## Safety Warnings

The tool will warn you about potentially dangerous operations:

1. **Destructive Commands**: Commands that could delete or overwrite data
2. **System Operations**: Commands that affect system files or directories
3. **Recursive Operations**: Commands that operate recursively on directories
4. **Privileged Operations**: Commands that require elevated privileges

When a dangerous command is detected:
- The command is displayed with a warning
- The original prompt is shown
- The specific dangerous pattern is identified
- You're advised to type the command manually if absolutely necessary

## How It Works

1. The tool takes your natural language prompt
2. Sanitizes the input to handle special characters
3. Sends it to Ollama with a system prompt to generate shell commands
4. Validates the generated command for safety
5. Displays the command and asks for confirmation
6. If confirmed, executes the command
7. Stores the interaction in history

## History Storage

Command history is stored in `~/.term_llm/history.txt` with the following format:
```
timestamp | original prompt | generated command
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available under the MIT License.

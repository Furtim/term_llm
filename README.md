# Term LLM

A command-line tool that converts natural language into shell commands using LLMs via Ollama. This tool makes it easier to execute complex shell commands by describing what you want to do in plain English.

## Features

- 🤖 Natural language to shell command conversion
- 🛡️ Safety checks for potentially dangerous commands
- 📝 Command history with search functionality
- 🎨 Colorized output for better readability
- 🔧 Configurable model selection
- ✅ Interactive command confirmation

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

## How It Works

1. The tool takes your natural language prompt
2. Sends it to Ollama with a system prompt to generate shell commands
3. Displays the generated command and asks for confirmation
4. If confirmed, executes the command
5. Stores the interaction in history

## Safety Features

- Commands are always shown for confirmation before execution
- The LLM is instructed to output "UNSAFE" for potentially dangerous commands
- Command history is maintained for auditing purposes

## History Storage

Command history is stored in `~/.term_llm/history.txt` with the following format:
```
timestamp | original prompt | generated command
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available under the MIT License.

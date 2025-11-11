# 🐀 rat: Next-Gen CLI File Viewer

[![Build Status](https://img.shields.io/github/actions/workflow/status/your-repo/rat.yml?branch=main)](https://github.com/your-repo/rat)
[![License](https://img.shields.io/github/license/your-repo/rat)](LICENSE)

## 💡 Why `rat`?

`rat` is a powerful, feature-rich command-line utility that goes beyond simple file viewing. It combines streaming simplicity with modern enhancements including SSH support, archive viewing, structured data rendering, Git annotations, and inline image display.

## ⭐ Key Features

- **TTY-aware dual mode** - raw byte-perfect output when piped, rich mode when attached to a terminal
- **SSH Support** - view files on remote servers seamlessly
- **Extended Language Support** - 15+ programming languages with custom configuration support
- **Archive Viewing** - .gz, .bz2, .tar, .zip and more
- **Structured Data Viewers** - JSON tree visualization, CSV tables
- **Git Annotations** - inline git blame with author and date information
- **Inline Image Display** - supports Kitty, iTerm2, w3m, and Sixel protocols
- **Plugin Architecture** - JSON-RPC based plugin system for custom renderers
- **Type Safe** - built with Crystal for compile-time type safety
- **Input/Output Sanitization** - safe handling of binary and malformed data
- **Paging Control** - `--paging=auto|always|never` for external pager integration
- **Line-range & Limit Options** - `--lines=START-END`, `--max-lines=N`
- **Clean Codebase in Crystal v1.18.2** - fast binary, easy to build & distribute

- **Input/Output Sanitization** - safe handling of binary and malformed data
- **Paging Control** - `--paging=auto|always|never` for external pager integration
- **Line-range & Limit Options** - `--lines=START-END`, `--max-lines=N`
- **Clean Codebase in Crystal v1.18.2** - fast binary, easy to build & distribute

## 🚀 Quick Start

### Install

```bash
# Clone and build
git clone https://github.com/OkaVatti/rat.git
cd rat
shards install
crystal build main.cr -o rat --release
```

### Usage

```bash
# Basic file viewing with syntax highlighting
./rat file.cr

# SSH file viewing
./rat -S -L user@192.168.1.100:22 -K ~/.ssh/id_rsa -l "/home/user/code.rs"

# View with line numbers
./rat -n main.cr

# Git blame annotations
./rat -g lib/rat/cli.cr

# View JSON as tree
./rat data.json

# View CSV as table
./rat data.csv

# View compressed file
./rat archive.tar.gz

# View image (if terminal supports it)
./rat image.png

# Line range with numbers
./rat --lines=10-50 -n README.md

# Use custom language config
./rat -c ~/.config/rat/my-languages.json code.custom
```

### Flags at a Glance

| Flag                   | Description                                        |
| ---------------------- | -------------------------------------------------- |
| `--plain`              | Disable all decorations (raw output)               |
| `--fast`               | Reduce highlighting overhead                       |
| `--paging=...`         | Control pager behavior (`auto`, `always`, `never`) |
| `--lines=START-END`    | Show only the specified inclusive line range       |
| `--max-lines=N`        | Stop after N lines (safety cap)                    |
| `-n`, `--number`       | Show line numbers                                  |
| `-S`, `--ssh`          | Enable SSH mode                                    |
| `-L`, `--location`     | SSH location (user@host:port)                      |
| `-K`, `--key`          | Path to SSH private key                            |
| `-P`, `--password`     | SSH password                                       |
| `-l`, `--remote-file`  | Remote file path                                   |
| `-g`, `--git-annotate` | Show git blame annotations                         |
| `-c`, `--config`       | Custom language config file                        |
| `--list-plugins`       | List available plugins                             |

## 🔌 SSH Support

View files on remote servers without manually SSHing:

```bash
# Using SSH key
rat -S -L lilith@192.168.50.127:22 -K ~/.ssh/lilith-devbox -l "~/code/lsd/lsd.cr"

# Using password (prompts if not provided)
rat -S -L user@example.com:22 -l "/var/log/app.log"

# Multiple files
rat -S -L user@server:22 -K ~/.ssh/key file1.cr file2.rs
```

## 🎨 Language Support

Supports 15+ languages out of the box:

- Crystal, Ruby, Rust, Python
- JavaScript, TypeScript, Go, C, C++, Java
- Shell (bash/zsh), YAML, JSON, Markdown
- HTML, CSS, SQL

### Custom Language Configuration

Create `~/.config/rat/languages.json`:

```json
{
  "languages": [
    {
      "name": "mylang",
      "extensions": [".ml"],
      "shebangs": ["mylang"],
      "keywords": ["func", "var", "if", "else"],
      "comment_single": "//",
      "string_delimiters": ["\""],
      "number_pattern": "\\b\\d+\\b"
    }
  ]
}
```

Then use:

```bash
rat -c ~/.config/rat/languages.json myfile.ml
```

## 📦 Archive Support

Automatically detects and handles compressed files:

```bash
# Gzip
rat file.gz

# Bzip2
rat archive.bz2

# Tar (shows contents)
rat package.tar

# Zip (shows contents)
rat bundle.zip
```

Supported formats: `.gz`, `.bz2`, `.tar`, `.zip`, `.tgz`, `.tbz2`, `.xz`, `.lz`

## 📊 Structured Data Viewing

### JSON Tree View

```bash
rat data.json
```

Output:

```
├─ name: "John Doe"
├─ age: 30
└─ address:
   ├─ street: "123 Main St"
   └─ city: "Springfield"
```

### CSV Table View

```bash
rat data.csv
```

Output:

```
Name          │ Age │ City
──────────────┼─────┼──────────────
John Doe      │ 30  │ Springfield
Jane Smith    │ 25  │ Boston
```

## 🎭 Git Annotations

View files with git blame information:

```bash
rat -g -n main.cr
```

Output:

```
a3f2c8d1 John Doe     2025-01-15 │   1  require "./lib/rat/cli"
a3f2c8d1 John Doe     2025-01-15 │   2
b7e4f9a2 Jane Smith   2025-01-20 │   3  Rat::CLI.run(ARGV)
```

## 🖼️ Inline Image Display

Supports multiple terminal graphics protocols:

- **Kitty Graphics Protocol** (kitty terminal)
- **iTerm2 Inline Images** (iTerm2)
- **w3m** (terminals with w3m support)
- **Sixel** (terminals with sixel support)

```bash
rat screenshot.png
rat logo.jpg
rat diagram.svg
```

Supported formats: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.svg`, `.ico`, `.bmp`

If your terminal doesn't support graphics, `rat` shows metadata instead.

## 🔧 Plugin System

Create custom renderers using JSON-RPC protocol.

### Plugin Directory Structure

```
~/.config/rat/plugins/
├── my-renderer.json       # Plugin config
└── my-renderer            # Executable
```

### Plugin Config (`my-renderer.json`)

```json
{
  "name": "my-renderer",
  "version": "1.0.0",
  "executable": "my-renderer",
  "file_types": [".custom"],
  "description": "Custom file renderer"
}
```

### Plugin Executable

Must accept JSON-RPC requests on stdin:

```json
{
  "jsonrpc": "2.0",
  "method": "render",
  "params": {
    "path": "/path/to/file.custom",
    "content": "file contents..."
  },
  "id": 1
}
```

And return:

```json
{
  "jsonrpc": "2.0",
  "result": "rendered output",
  "id": 1
}
```

### List Plugins

```bash
rat --list-plugins
```

## 🧱 Design Philosophy

- **Composable & Pipeline-Safe** - default to raw output when piped
- **Progressive Enhancement** - streaming first, rich UI only when terminal-attached
- **Type Safe** - Crystal's compile-time type checking prevents runtime errors
- **Secure by Default** - input/output sanitization, path validation
- **Extensible Architecture** - plugins and custom language configs
- **Zero Configuration** - works out of the box with sensible defaults

## 📂 Project Structure

```txt
rat/
├── main.cr                      # Entry point
├── shard.yml                    # Crystal dependencies
├── config/
│   └── languages.json           # Default language configs
├── lib/
│   ├── rat/
│   │   ├── cli.cr               # CLI logic & argument parsing
│   │   ├── reader.cr            # Safe file/stdin reading
│   │   ├── formatter.cr         # Output formatting
│   │   ├── ssh_client.cr        # SSH file fetching
│   │   ├── archive_reader.cr    # Archive handling
│   │   ├── image_viewer.cr      # Inline image display
│   │   ├── structured_viewer.cr # JSON/CSV rendering
│   │   ├── git_annotator.cr     # Git blame integration
│   │   └── plugin_manager.cr    # Plugin system
│   └── internals/
│       ├── highlighter.cr       # Syntax highlighting engine
│       └── language_config.cr   # Language configuration
└── spec/
    ├── spec_helper.cr
    └── spec_highlighter.cr
```

## 🔒 Security Features

- **Path Sanitization** - prevents directory traversal attacks
- **Input Validation** - all user input is validated and sanitized
- **Output Sanitization** - strips control characters from output
- **File Size Limits** - warnings for very large files
- **SSH Key Verification** - secure SSH authentication
- **Type Safety** - Crystal's type system prevents entire classes of bugs

## 🎯 Use Cases

- **Development** - syntax-highlighted code viewing with git context
- **DevOps** - view logs on remote servers without SSH session
- **Data Analysis** - quick CSV/JSON inspection
- **Documentation** - view markdown files with proper formatting
- **Debugging** - inspect compressed logs and archives
- **System Administration** - remote file inspection with annotations

## 📈 Roadmap

- [x] SSH support for remote files
- [x] Extended language syntax support
- [x] Type-safe implementation
- [x] Input/output sanitization
- [x] Git annotations support
- [x] Archive/compression support
- [x] Structured data viewers (JSON, CSV)
- [x] Plugin architecture (JSON-RPC)
- [x] Inline image preview support
- [ ] `--follow` / `-f` mode for live-tail with highlighting
- [ ] Multi-file diff view
- [ ] Syntax theme customization
- [ ] WASM plugin support
- [ ] Performance profiling mode
- [ ] Configurable key bindings

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

- Additional language syntax definitions
- New image display protocols
- Plugin examples
- Performance optimizations
- Documentation improvements

Please open issues for bugs or feature requests, and submit pull requests with tests.

## 📝 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built with:

- [Crystal Language](https://crystal-lang.org/) - Fast, type-safe language
- [ssh2-cr](https://github.com/spider-gazelle/ssh2-cr) - SSH2 protocol support
- [crystal-compress](https://github.com/naqvis/crystal-compress) - Compression support

---

Made with ❤️ for developers who live in the terminal.

**Author**: Lily Parker <okavatti@proton.me>

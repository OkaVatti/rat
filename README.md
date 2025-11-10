# 🐀 rat: Next‑Gen CLI File Viewer

[![Build Status](https://img.shields.io/github/actions/workflow/status/your‑repo/rat.yml?branch=main)](https://github.com/your‑repo/rat)
[![License](https://img.shields.io/github/license/your‑repo/rat)](LICENSE)

## 💡 Why `rat`?

`rat` is a lightweight, nimble command‑line utility that combines the streaming simplicity of `cat` with modern enhancements for interactive use. It auto‑adapts to pipelines and terminal usage, offers syntax‑highlighting, paging and future‑proof extensibility.

## ⭐ Key Features

* **TTY‑aware dual mode** – raw byte‑perfect output when piped, rich mode when attached to a terminal.
* **Paging control** – `--paging=auto|always|never` gives you full control of external pager integration.
* **Line‑range & limit options** – `--lines=START‑END`, `--max‑lines=N`.
* **Highlighting (fast or full)** – `--fast` disables heavy parsing for large files.
* **Simple, streaming architecture** – minimal memory footprint; start viewing before the whole file is loaded.
* **Clean codebase in Crystal v1.18.2** – fast binary, easy to build & distribute.

## 🚀 Quick Start

### Install

```bash
# Clone and build
git clone https://github.com/your‑repo/rat.git
cd rat
crystal build main.cr -o rat
```

### Usage

```bash
# Default rich mode when stdout is a terminal
./rat file.cr

# Raw mode (script friendly)
./rat --plain file.bin > output.bin

# Range of lines with line numbers
./rat --lines=10‑50 -n README.md

# Fast mode, skip heavy highlighting
./rat --fast large.log

# Force external pager
./rat --paging=always big_source.rs
```

### Flags at a glance

| Flag                | Description                                        |
| ------------------- | -------------------------------------------------- |
| `--plain`           | Disable all decorations (raw output)               |
| `--fast`            | Reduce highlighting overhead                       |
| `--paging=...`      | Control pager behavior (`auto`, `always`, `never`) |
| `--lines=START‑END` | Show only the specified inclusive line range       |
| `--max-lines=N`     | Stop after N lines (safety cap)                    |
| `-n`, `--number`    | Show line numbers (future enhancement)             |

## 🧱 Design Philosophy

* **Composable & pipeline‑safe** – default to raw output when piped.
* **Progressive enhancement** – streaming first, rich UI only when terminal‑attached.
* **Extensible architecture** – designed for plugins (future) and custom renderers.
* **Secure & performant** – no unnecessary buffering, safe defaults for unknown file types.
* **Crystal native** – built in Crystal v1.18.2 for static binary distribution, cross‑platform simplicity.

## 📂 Project Structure

```txt
main.cr             # Entry point  
lib/rat/cli.cr       # CLI logic & flag parsing  
lib/rat/reader.cr    # Safe streaming of stdin & files  
lib/rat/formatter.cr # Header, highlighting & line formatting  
internals/highlighter.cr # Lightweight syntax highlighter  
```

## 📈 Roadmap

* [ ] `--follow` / `-f` mode for live‑tail + highlighting
* [ ] Git annotations: inline gutter markers, `--git-annotate`
* [ ] Archive & compression support (.gz/.zip/.tar)
* [ ] Structured data viewers: JSON tree, CSV tables
* [ ] Plugin architecture (WASM / JSON‑RPC) for custom renderers
* [ ] Inline image previews for terminals that support graphics

## 🤝 Contributing

Contributions are welcome! Feel free to open issues, suggest features, or submit pull requests. Please follow the [Contributor Covenant](CONTRIBUTING.md) style (coming soon) and include tests for new features.

## 📝 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

Made with :heart: for developers who live in the terminal.

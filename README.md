# Numr - Natural Language Calculator for Omarchy

## Demo

<!-- TODO: Insert your demo video or GIF here -->
<!-- Example: ![Numr Demo](path/to/demo.gif) -->
[Insert Demo Video/GIF Here]

## Features

- **Natural Language Calculation**: Write calculations in plain, natural language, and Numr will parse and solve them seamlessly.
- **Multi-Notes**: Keep track of multiple calculations, notes, and context over separate sheets or entries.
- **JSON-RPC Integration**: Utilizes a robust JSON-RPC interface to communicate with the underlying Numr calculator engine.
- **Custom Look & Feel**: Fully customize the appearance, theme, fonts, and colors to match your Omarchy shell environment.

## Installation

### Dependency

Numr is a core dependency for this plugin. It must be installed on your system using `pacman` (or an AUR helper like `yay`):

```bash
sudo pacman -S numr
# Or using yay:
yay -S numr
```

### Plugin Installation

Once the dependency is installed, you can add the plugin to your Omarchy shell by running:

```bash
omarchy plugin add https://github.com/niedch/omarchy-numr-plugin --enable
```

### Configuration

To display and use the Numr plugin, add it to your `shell.json` configuration file inside the `bar.layout` array using the ID `"nic.numr"`:

```json
{
  "bar": {
    "layout": [
      {
        "id": "nic.numr"
      }
    ]
  }
}
```

## Development

### Setting up the Environment

Development for this plugin is done inside a Nix environment to ensure reproducible builds and dependencies.

1. Enter the Nix environment:
   ```bash
   nix develop
   ```

2. Start the sandboxed environment to run and test the plugin:
   ```bash
   mise run-quickshell
   # Or alternatively:
   mise run run-quickshell
   ```

### Formatting and Linting

To maintain code quality and follow the project's standards, use the following commands for formatting and linting:

- To format the codebase:
  ```bash
  mise run format
  ```

- To lint the codebase:
  ```bash
  mise run lint
  ```

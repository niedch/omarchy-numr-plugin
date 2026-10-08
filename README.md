# Numr - Natural Language Calculator for Omarchy

## Demo

https://github.com/user-attachments/assets/60ef1ba0-23b8-481e-92cc-f8946d6371e4

## Features

- **Natural Language Calculation**: Write calculations in plain, natural language, and Numr will parse and solve them seamlessly.
- **Multi-Notes**: Keep track of multiple calculations, notes, and context over separate sheets or entries.
- **JSON-RPC Integration**: Utilizes a robust JSON-RPC interface to communicate with the underlying Numr calculator engine.
- **Custom Look & Feel**: Fully customize the appearance, theme, fonts, and colors to match your Omarchy shell environment.

## Installation

### Dependency

Numr is a core dependency for this plugin. It is only available in the Arch User Repository (AUR), so install it with an AUR helper like `yay`:

```bash
yay -S numr
```

### Plugin Installation

Once the dependency is installed, you can add the plugin to your Omarchy shell by running:

```bash
omarchy plugin add https://github.com/niedch/omarchy-numr-plugin --enable
```

### Removal

To remove the plugin, run:

```bash
omarchy plugin remove nic.numr
```

This disables the plugin and deletes the checkout (the repo stays on GitHub).

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

### Rendering

The sandboxed shell renders with Qt's software scene graph (`QT_QUICK_BACKEND=software`). The nixpkgs Qt/EGL stack cannot create GL contexts against the NVIDIA proprietary driver on the host, so GPU-accelerated rendering is disabled by default. This only affects visuals (for example, `ShaderEffect`-based effects will not render). If your Nix environment can create GL contexts, override it:

```bash
QT_QUICK_BACKEND=rhi mise run run-quickshell
```

### Automated smoke check

To verify the dev shell boots and renders without graphics errors, run:

```bash
mise run check-quickshell
```

The check launches the shell for about 12 seconds and fails if it crashes, fails to reach `service-ready`, or logs RHI/graphics-context errors. To run the shell manually under a timeout (a GUI process that keeps running until killed, so expect exit code 124):

```bash
timeout 60s nix develop -c mise run run-quickshell
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

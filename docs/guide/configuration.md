---
title : Flint | Configuration Guide
---

# Configuration

<br>

Flint uses a `flint.config.json` file to manage formatting commands, allowing you to specify how code should be formatted both locally and remotely. This configuration file is crucial for ensuring that your codebase remains consistent while accommodating individual style preferences.

## Config File

The `flint.config.json` file is by default located in the root of your project directory. It contains an array of linter configurations, each specifying the extensions of files to be formatted, the binary or command to be executed, and the specific commands for local and remote formatting.

## Example Configuration

Below is an example configuration file that demonstrates how to set up Flint to format JavaScript files using ESLint. This example shows both local and remote formatting commands:

```json
{
  "linters": [
    {
      "extensions": ["js"],
      "binary": "node_modules/.bin/eslint",
      "commands": {
        "local": "--fix --config eslint.local.config.js --quiet",
        "remote": "--fix --config eslint.remote.config.js --quiet"
      }
    }
  ]
}
```

## Customizing Configuration

You can customize the configuration to suit your project's needs by adding more linters or modifying the existing ones. For example, you can configure Flint to use different linters for different file types or add additional formatting options.

### Change configuration file path

The configuration file is located by default at the root of your project. If you wish to move this file, for example, to the `.flint` directory, you can modify the `config` variable in the `.flint/git.sh` file.

### Adding Multiple Linters

To add multiple linters, simply include additional objects in the `linters` array. Each object should specify the extensions, binary, and commands for the respective linter.


More details about [Configuration references here](../reference/configuration.md)

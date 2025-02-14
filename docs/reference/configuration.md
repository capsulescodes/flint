---
title : Flint | Config References
---


# Configuration

Flint config is where you can define the settings of processes run during Flint hooks. Config options define settings that apply to every file located in the repository.

## Overview

Flint uses a JSON file to manage processes.

Below is an example configuration file formatting Javascript files with `ESLint`. It formats locally based on `eslint.local.config.js` file and remotely based on `eslint.remote.config.js`.

```json
{
  "linters" :
  [
    {
      "extensions" : [ "js" ],
      "binary" : "node_modules/.bin/eslint",
      "commands" : {
        "local" : "--fix --config eslint.local.config.js --quiet",
        "remote" : "--fix --config eslint.remote.config.js --quiet"
      }
    }
  ]
}
```

## Metadata

### linters
- Type : `array`

It includes the different processes run during flint hooks. A `linter` is composed of a set of `extensions`, a `binary` and `commands`.

### extensions
- Type : `array`

A linter can filter files based on specified extension. Keep in mind the internal function of the binary can also have a filtering process.

### binary
- Type : `string`

Specified path where your binary is located. A warning is returned if no binary is found.

### commands
- Type : `object`

An inexhaustive list of commands. Default ones are `local` and `remote`. They are run when needed in Flint hooks. You can run specific ones with [Flint CLI command](./command-line-interface.md#flint-run)

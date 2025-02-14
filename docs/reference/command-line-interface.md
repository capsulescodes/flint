---
title : Flint | CLI References
---

# Command Line Interface



## `flint`

Runs flint as a git command on steroids

#### Usage

```bash
#runs git help
flint

#runs git status
flint status
```

#### Options

Refers to [git documentation](https://git-scm.com/docs/git)

<br>

## `flint init`

Create a hidden `.flint` Flint repository or reinitialize an existing one

#### Usage

```bash
flint init <options>
```

#### Options

| Option        | Description                                                              |
| ------------- | ------------------------------------------------------------------------ |
| --wrap        | Integrates a Git wrapper function into local shell configuration file    |
| --hooks       | Includes modifiable hooks for custom workflows                           |
| -no-config    | Skips default configuration template integration ( `flint.config.json` ) |

<br>

## `flint run`

Execute Flint purpose on current directory. Defaults to `local` command.
Commands are specified in config file.

#### Usage

```bash
flint run [command]
```

## `flint help`

Display help information about Flint

#### Usage

```
flint help
```

<br>

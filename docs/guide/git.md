---
title : Flint | Wrapping Git
---

# Git Integration

<br>

Flint seamlessly integrates with Git to automate code formatting during various Git operations. This integration ensures that your codebase remains consistent without requiring manual intervention. Here's how you can leverage Flint's Git integration features.

## How Flint Works with Git

Flint operates by wrapping Git commands to intercept and format code during `pull` and `push` operations. This ensures that:

<br>

- **Checking out and Pulling Code**: When you pull code from the remote repository, Flint adapts the code to match your local style preferences, making it easier to read and work with.
- **Committing and Pushing Code**: Before pushing code to the remote repository, Flint reformats it to align with the project's agreed-upon style guidelines, ensuring consistency across the codebase.

## Wrapping Git

Flint don't override the git command by default. To enable seamless integration with Git, you can run the command option during initialization or add the Flint Git wrapper to your local shell configuration manually. This wrapper aims to call Flint hooks **if and only if** a `.flint` directory is present in repository. It runs standard `git` otherwise.

::: tip Running Flint without wrapping Git
You initially access `flint` based on the way you installed it. See the [Quick Start section](./quick-start.md) for more information.
:::

<br>

#### Populate git wrapper during initialization

When initializing flint on your repository, add the `--wrap` option to add the git wrapper function inside your preferred shell configuration file.

```bash
flint init --wrap
```

::: details .bashrc
```bash
# Flint git wrapper
git() { if [[ -f "$PWD/.flint/git.sh" ]]; then bash "$PWD/.flint/git.sh" "$@"; else command git "$@"; fi; }
```
:::

<br>

#### Adding the Git Wrapper manually

Add the following function to your shell configuration file ( e.g., `.bashrc`, `.zshrc`, ... ):

```bash
git() {
  if [[ -f "$PWD/.flint/git.sh" ]]; then
    bash "$PWD/.flint/git.sh" "$@";
  else
    command git "$@";
  fi
}
```

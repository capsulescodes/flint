---
title : Flint | How it Works
---

# How it works

<br>

Flint operates by integrating seamlessly with Git, leveraging pseudo Git hooks to automate code formatting during various Git operations. This ensures that your codebase remains consistent without manual intervention. Here's a detailed look at how Flint works.

<br>

---

### Basics

Except for this Markdown-written documentation, Flint is entirely written in Shell and is compatible with every Git-friendly operating system.<br>
Flint is a bundle of multiple scripts and wrappers but its core functionality revolves around wrapping Git with [pseudo Git hooks](#pseudo-git-hooks).

<br>

### Pseudo Git Hooks

Flint runs multiple pseudo Git hooks when executing different Git commands. These include `pre` and `post` hooks for the follwoing operations:


| Command       | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| checkout      | Switch branches or restore working tree files                        |
| commit        | Record changes to the repository                                     |
| pull          | Fetch from and integrate with another repository or a local branch   |
| push          | Update remote refs along with associated objects                     |


<br>

There is two types of hooks: `pull` and `push` hooks. The `pull` type hook format code locally, while the `push` type hook format code remotely. 'checkout' and 'pull' commands are `pull` types, whereas 'commit' and 'push' are inherently `push` types. These hooks run before the legitimate git hooks, as illustrated below:

```
flint-pre-commit > git-pre-commit > git-commit > git-post-commit > flint-post-commit
```

<br>

Each time one of these commands is executed, Flint triggers the corresponding pseudo Git hook, running the commands specified in [your configuration file](#configuration-file-and-flint-hidden-directory) for each relevant file. This ensures that only the files affected by the Git operation are formatted, maintaining efficiency and consistency.

When `pull` type hooks are triggered, Flint applies local formatting, resulting in a [temporary commit](#temporary-commits). This ensures that any local Git operations, such as modifying files or viewing diffs, reflect your local formatting preferences. Consequently, you won't see any formatting changes from the remote repository.

<br>

### Configuration file and Flint hidden directory

The configuration file lists all the processes needed to be run during Flint hooks. To access Flint module files, Flint creates a directory based on the installation method. This directory contains the main wrapper which ensures wide compatiblity with package managers and allows for customization of config and hook paths.

Additionnlly, the directory stores and hides populated hooks and config files. Its presence enables Git wrapping, meaning Flint will run its hooks if the directory exist. Otherwise, it will run regular Git commands.

<br>

### Temporary Commits

One of the key features of Flint is its use of temporary commits. When running `pull` type Git commands, Flint formats the retrieved files according to the local command. It creates a temporary commit to preserve the history and diff aspects of Git, making it appear as though the formatting changes were always part of local style.

Before sending any information to the remote repository with `push` type Git commands, Flint performs a soft reset of the temporary commit, reverting the formatting to the remote command. This ensures that the remote repository receives only the functional changes, maintaining a clean and consistent codebase.

<br>

### Git wrapping

Git itself does not support all the hooks that Flint requires to function effectively. By wrapping Git commands, Flint can intercept and augment these operations, providing the necessary functionality to automate processes seamlessly. This wrapping ensures that Flint can operate without modifying Git's core behavior, making it a non-intrusive addition to the development workflow.

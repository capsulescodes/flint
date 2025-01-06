
<p align="center"><img src="art/capsules-flint-image.png" height="265px" alt="Flint Image" /></p>

<br>

Write code your way while ensuring remote consistency.

<br>

Flint empowers developers to use their personal style and formatting preferences locally, while maintaining a consistent remote codebase. By integrating with Git, Flint automatically formats code during `pull` and `push` operations. This approach prevents commits from being cluttered with formatting changes, making code reviews cleaner and collaboration smoother.

<br>

> [!NOTE]
> Flint is currently under development. Contributions are warmly welcomed.

<br>

## Installation

**1. Install Flint using your package manager**

```bash
# npm
npm install --save-dev @capsulescodes/flint
```

<br>

**2. Initialize Flint**

```bash
# npm
node_modules/.bin/flint --init
```

<br>

This command will :

- Create a `.flint` directory in your project's root [ unless already present ].
- Create a `flint.config.json` file in your project's root [ unless already present ].

<br>

**3. Optional - Integrate a Git wrapper inside your local shell configuration file**

```
# Flint git wrapper
git() { if [[ -f "$PWD/.flint/git.sh" ]]; then sh "$PWD/.flint/git.sh" "$@"; else command git "$@"; fi; }
```

This wrapper will :

- Call Flint around Git if a `.flint` directory is present inside the current location. If not, it will call Git as usual.

> [!NOTE]
> Running ```flint --init --wrap``` integrates the wrapper during setup.
> More options below.

<br>

## Usage

Once initialized, Flint integrates with your Git workflow to streamline coding practices.

- **Local Development** : Format your code according to personal preferences.
- **Pulling Code** : Flint adapts remote code to your local style for easier readability.
- **Committing and Pushing Code** : Flint reformats your code to align with remote style guidelines.

<br>

This esnures :

- **Maintaining Code Consistency** :Ensures the repository always adheres to agreed-upon styles.
- **Improving Readability** : Local preferences don’t impact others' workflows.
- **Cleaner Commits** : Keeps formatting changes separate from logic changes.

<br>

## Caveats

Flint creates a hidden temporary commit during certain `git` operations, which may result in the following message to appear when running `git status` :

```diff
On branch main
+ Your branch is ahead of 'origin/main' by 1 commit.
+     (use "git push" to publish your local commits)

nothing to commit, working tree clean
```

<br>

This message indicates that your local branch is configured to track the remote branch, and Flint's hidden temporary commit makes your local branch appear ahead by one commit. To ignore this message, you can unset the upstream tracking for your branch by running :

```git
git branch --unset-upstream <branch-name>
```

<br>

## Configuration

Flint uses a `flint.config.json` file to manage formatting commands. Specify your local and remote formatting commands here.

<br>

Below is an example configuration file formatting Javascript files with [ESLint](https://eslint.org/). It formats locally based on `eslint.local.config.js` file and remotely based on `eslint.remote.config.js` :

<br>

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

<br>

## Currently supported Package Managers

- [x] Flint is available on [npm](https://www.npmjs.com/).

<br>

## Options

**- Include Flint hooks during initialization**

If you want to access Flint hooks, use the `--init` or `-i` option with the `--hooks` flag.

```bash
# npm
node_modules/.bin/flint -i --hooks
```

<br>

**- Include Git wrapper function during initialization**

If you want to run Flint while using Git, use the `--init` or `-i` option with the `--wrap` flag.

```bash
# npm
node_modules/.bin/flint -i --wrap
```

<br>

**- Skip adding default configuration file during initialization**

If you don't want to add a configuration file template to your project, use the `--init` or `-i` option with the `--no-config` flag.

```bash
# npm
node_modules/.bin/flint -i --no-config
```

<br>

**- Run Flint command manually**

If you want to run a specific **command** from configuration file property ***commands***, use your command after the `--run` or `-r` option. Default is `local`.

```bash
# npm
node_modules/.bin/flint -r remote
```

<br>

**- Use Flint as a Git alternative**

Flint can act as a Git wrapper, allowing you to seamlessly use Git commands while benefiting from Flint's formatting hooks. To enable this, simply replace `git` with `flint` in your commands.

```bash
# npm
node_modules/.bin/flint status
```

<br>

## Contributing

Contributions are warmly welcomed. For major changes, please open an issue first to discuss what you would like to change.
Please make sure to update tests as appropriate.

<br>

## Testing

```bash
# npm
npm run test

# bash
sh tests/runner.sh
```

<br>

## Credits

[Capsules Codes](https://github.com/capsulescodes)

<br>

## License

[MIT](https://choosealicense.com/licenses/mit/)

<br>

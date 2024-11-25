
<p align="center"><img src="art/capsules-flint-image.png" height="265px" alt="Flint Image" /></p>

<br>

Write code in your own style while maintaining team consistency.

<br>

Flint empowers developers to use their personal style and formatting preferences locally, while ensuring consistency in the remote codebase. By wrapping Git commands with its own wrapper and custom hooks, Flint automatically formats code during pull and push operations. This approach prevents commits from being cluttered with formatting changes, making code reviews cleaner and collaboration smoother.

<br>

> [!NOTE]
> This package is currently under development. Contributions are warmly welcomed.

<br>

## Installation

**1. Install package with your project's package manager**

```bash
# NPM
npm install --save-dev @capsulescodes/flint

# Composer
composer require-dev capsulescodes/flint
```

<br>


**2. Initialize Flint**

```bash
# NPM
node_modules/.bin/flint --init

# Composer
vendor/bin/flint --init
```

<br>

It will do multiple things :

- Create the .flint directory on your project's root if not present
- Create the flint.config.json on your project's root if not present
- Write the Flint git wrapper in your shell's RC file if not present

<br>

## Usage

Once installed and initialized, Flint seamlessly integrates with your Git workflow.

- **Local Development** : Write and format your code according to your personal preferences.
- **Pulling Code** : When you pull code from the repository, Flint formats it to match your local style, making it easier for you to read and work with.
- **Committing and Pushing** : Before code is committed and pushed to the repository, Flint reformats it to adhere to the team's style guidelines based on remote config, ensuring consistency across the codebase.

<br>

This process helps in :

- **Maintaining Code Consistency** : The remote repository always reflects the team's agreed-upon code style.
- **Improving Readability** : Developers can work in an environment tailored to their preferences without affecting others.
- **Cleaner Commits** : By separating formatting changes from actual code changes, commits become more meaningful and easier to review.

<br>

## Caveats

Flint creates a hidden temporary commit between certain `git` commands, which may sometimes cause the following message to appear when running `git status` :

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

Flint uses the `flint.config.json` file for configuration. You can specify your local and team formatting rules here.

<br>

Here is a basic config file formatting Javascript and Typescript files with ESLint with `remote.config.js` file remotely and `local.config.js` locally.

<br>

```json
{
    "linters" :
    [
        {
            "extensions" : [ "js" ],
            "binary" : "node_modules/.bin/eslint",
            "commands" : {
                "local" : "--fix --config eslint.local.config.js",
                "remote" : "--fix --config eslint.remote.config.js"
            }
        }
    ]
}
```

<br>

## Supported Package Managers [ WIP ]

- [x] Flint is available on NPM.
- [x] Flint is available on Composer.

<br>

## Options

<br>

**- Init flint hooks in your project**

If you want to modify your own flint hooks, you can run the `--init` or `-i` command with the `--with-hooks` flag.

```bash
# NPM
node_modules/.bin/flint -i --with-hooks

# Composer
vendor/bin/flint -i --with-hooks
```

<br>

**- Run Flint manually**

If you want to run your Flint configuration manually, you can run the `--run` or `-r` command.

```bash
# NPM
node_modules/.bin/flint --run

# Composer
vendor/bin/flint --run
```

<br>

if you want to run a specific command from configuration file like `local` or `remote`, you can run your command after the `--run` or `-r` command.

```bash
# NPM
node_modules/.bin/flint -r remote

# Composer
vendor/bin/flint -r remote
```

<br>

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
Please make sure to update tests as appropriate.

<br>

## Testing

```bash
# NPM
npm run test

# Composer
composer test

# Bash
sh tests/tester.sh
```

<br>

## Credits

[Capsules Codes](https://github.com/capsulescodes)

<br>

## License

[MIT](https://choosealicense.com/licenses/mit/)

<br>

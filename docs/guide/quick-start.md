---
title : Flint | Quick Start
---

# Quick Start

<br>

Follow these steps to add Flint to your project.

::: info
Flint is currently in alpha and is available exclusively on npm.
:::

## Prerequisites

- Ensure you have Node.js installed (version 18 or higher recommended).
- A Git repository for your project.

## 1 - Installation

<br>

Install Flint using your preferred package manager.

::: code-group

```bash [npm]
npm install --save-dev @capsulescodes/flint
```

```bash [pnpm]
pnpm add --save-dev @capsulescodes/flint
```

```bash [yarn]
yarn add --dev @capsulescodes/flint
```

:::

## 2 - Initialization

<br>

Initialize Flint in your project by running the following command:

::: code-group

```bash [-]
node_modules/.bin/flint init
```

```bash [npx]
npx flint init
```

:::

This command will:

- Create a `.flint` directory in your project's root (if not already present).<br>
- Generate a `flint.config.json` file in your project's root for configuration.

## 3 - Configuration

<br>

Configure the `flint.config.json` file to specify your `local` and `remote` base commands. Here's an example configuration for formatting JavaScript files using the most popular Javascript Linter `ESLint` :

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

<br>

For the purpose of this, here are two `Eslint` config file examples

::: details eslint.local.config.js
```js
export default [ {
 	rules : {
 		'yoda' : [ 'error', "always" ]
 	}
} ];
```
:::

::: details eslint.remote.config.js
```js
export default [ {
 	rules : {
 		'yoda' : [ 'error', "never" ]
 	}
} ];
```
:::


## 4 - Start

<br>

You're all set and ready!<br>But before actually run Flint, add a JS file and write some code first.

`foo.js`

```js:line-numbers
if( "red" === color )
{
    // ...
}
```

<br>

Now run `flint` like you run `git`.

::: code-group

```bash [-]
# Add foo.js file
node_modules/.bin/flint add foo.js

# Commit with message
node_modules/.bin/flint commit -m "Added foo.js file"

# Push to remote
node_modules/.bin/flint push origin main
```

```bash [npx]
# Add foo.js file
npx flint add foo.js

# Commit with message
npx flint commit -m "Added foo.js file"

# Push to remote
npx flint push origin main
```

:::

::: tip Wrap git
If you'd like to keep typing `git` as usual instead of `flint`. See the [Git section](./git.md).
:::


<br>

Your local and remote code will have their respective config files style from now on.

::: code-group

```js:line-numbers [local]
if( "red" === color )
{
    // ...
}
```

```js:line-numbers [remote]
if( "red" === color ) // [!code --]
if( color === "red" ) // [!code ++]
{
    // ...
}
```

:::


Flint will automatically format your code during `pull` and `push` operations, ensuring a consistent codebase while allowing you to use your preferred coding style locally.

---

<br>

::: danger Remove Flint

To remove Flint from your project, first uninstall it using your package manager. Additionally, you should manually remove the following files and directories that Flint may have created :

- The `.flint` directory at the root of your project.
- The `flint.config.json` file at the root of your project.
- The git wrapper function from your shell configuration file.

:::

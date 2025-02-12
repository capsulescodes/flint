---
title: Getting Started with Flint
---

# Getting Started with Flint

Flint is designed to help developers maintain code consistency while allowing personal style. This guide will help you get Flint up and running in your project.

## Installation

To install Flint, follow the instructions for your package manager:

### npm
```bash
npm install --save-dev @capsulescodes/flint
```

### yarn
```bash
yarn add --dev @capsulescodes/flint
```

### pnpm
```bash
pnpm add --save-dev @capsulescodes/flint
```

## Configuration

After installation, initialize Flint in your project:
```bash
npx flint --init
```

This command creates a `.flint` directory and a `flint.config.json` file in your project's root.

## Usage

Once Flint is configured, it integrates with your Git workflow. Here’s how to use it:
- **Local Development**: Format your code according to your preferences.
- **Pulling Code**: Flint adapts remote code to your local style.
- **Committing and Pushing Code**: Flint reformats your code to align with remote style guidelines.

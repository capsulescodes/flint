---
title : Flint | Team Collaboration
---

# Team Collaboration

<br>

Flint is particularly beneficial for teams, as it helps maintain a consistent codebase across collaborators while allowing each developer to use their preferred coding style locally. Here’s how to configure and use Flint effectively in a team setting:

---

### Installation

1. **Install Flint**: Install Flint using your preferred package manager. If Flint is already part of dependencies, install dependencies. If `.flint` directory is missing, run Flint init command.

2. **Create linter related configs**: Create local configs. If remote configs are missing, create them. Locate them in `.flint` directory if needed. Remote Configs must be committed to the repository along with Flint directory. On the other hand, local config files must be ignored.

3. **Edit Flint Config**: If necessary, modify the `flint.config.json` file that outlines the agreed-upon style guidelines for the project. This configuration must be committed to the repository. It is important for team members to use the same typo for local config names, otherwise, local linting will fail.

4. **Start coding with Flint**: with or without wrapping Git.

---
title : Flint | Caveats
---

# Caveats

While Flint offers benefits in maintaining code consistency and reducing cognitive load, there are a few caveats to be aware of when using it in your development workflow.

<br>

### Temporary Commits

Flint creates a temporary commit to adapt code to your local style during pull operations. This can sometimes result in your local branch appearing ahead of the remote branch by one commit, which may lead to a message like:

```bash
On branch main
 Your branch is ahead of 'origin/main' by 1 commit. # [!code ++]
     (use "git push" to publish your local commits) # [!code ++]

nothing to commit, working tree clean
```

This is a side effect of Flint's temporary commit mechanism, which ensures that your local changes are formatted according to your preferences. If this bothers you, you can unset the upstream tracking for your branch by running:

```bash
git branch --unset-upstream <branch-name>
```

<br>

### Performance Considerations

Running binaries in `pre` and `post` hooks can introduce slowness to your Git operations. The complexity of ensuring that all formatting and linting processes run smoothly can add overhead to your workflow. This is particularly noticeable in larger projects or when using multiple linters and formatters. Even if these processes are meant to be focused on `git` 'dirty' files only.


To mitigate these issues, consider optimizing your linter and formatter configurations and ensuring that only necessary tools are run during these hooks. Additionally, you may want to evaluate the performance impact of each tool and adjust your setup accordingly to balance between consistency and speed.

<br>

### Formatting Limitations

Flint allows you to format your code locally according to your personal preferences. However, this flexibility can introduce challenges when pushing code to the remote repository.

Your local changes might not be distinguishable from intentional formatting when reviewed remotely. This is particularly problematic if your remote formatting rules do not account for removing such local styles, leading to potential inconsistencies or misunderstandings about the intent behind the formatting.

To mitigate this issue, ensure that your remote formatting rules are comprehensive and can handle both the addition and removal of such stylistic elements. This helps maintain clarity and consistency in the codebase, ensuring that all formatting changes are intentional and meaningful.

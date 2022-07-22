# Nightly Merge Action

Automatically merge the latest release branch into the staging one.

If the merge is not necessary, the action will do nothing.
If the merge fails due to conflicts, the action will fail, and the repository
maintainer should perform the merge manually.

## Installation

To enable the action simply create the `.github/workflows/nightly-merge.yml`
file with the following content:

```yml
name: 'Nightly Merge'

on:
  schedule:
    - cron:  '0 0 * * *'

jobs:
  nightly-merge:

    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v1

    - name: Nightly Merge
      uses: robotology/gh-action-nightly-merge@v1.3.1
      with:
        staging_branch: 'staging'
        allow_ff: false
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Even though this action was created to run as a scheduled workflow,
[`on`](https://help.github.com/en/articles/workflow-syntax-for-github-actions#on)
can be replaced by any other trigger.

For example, this will run the action whenever something is pushed on the
`master` branch:

```yml
on:
  push:
    branches:
      - master
```

This will add a button to the action to trigger it manually:

```yml
on:
  workflow_dispatch:
```

## Parameters

### `staging_branch`

The name of the staging branch (default `staging`).

### `user_name`

User name for git commits (default `Nightly Merge`).

### `user_email`

User email for git commits (default `pablo.giraud-carrier@rideyego.com`).

### `push_token`

Environment variable containing the token to use for push (default
`GITHUB_TOKEN`).
Useful for pushing on protected branches.
Using a secret to store this variable value is strongly recommended, since this
value will be printed in the logs.
The `GITHUB_TOKEN` is still used for API calls, therefore both token should be
available.

```yml
      with:
        push_token: 'FOO_TOKEN'
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        FOO_TOKEN: ${{ secrets.FOO_TOKEN }}
```

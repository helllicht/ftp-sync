# helllicht/security-check

## IMPORTANT INFO:
> Wenn man im nachhinein Dateien/Ordner zum ignore hinzufügt werden diese ignoriert, diese werden *NICHT* auf dem Server gelöscht, dass mus man selbst machen! Nur Dateien die nicht ignoriert werden werden auch abgeglichen und gelöscht wenn diese nun nicht mehr vorhanden sind!

> https://docs.github.com/en/free-pro-team@latest/actions/creating-actions/creating-a-composite-run-steps-action

## Active versions
INFO: This action just have one active version -> master!
+ master

## How to use this action
If not already done, add following folder structure to the project (name of the yml-file is up to you).
```
.
└── .github/
    └── workflows/
        └── check.yml
```
Example:
> In this example just the 'staging'-Branch is deployed!
> read more about 'on:'
> here: https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions#on
```
name: Check

on:
    push:
        branches:
            - staging

jobs:
    build:
        name: Check vulnerabilities
        runs-on: ubuntu-18.04
        steps:
            - name: Checkout Repository
              uses: actions/checkout@v2
            - ...build your project
            - name: Sync to server
              uses: helllicht/ftp-sync@master
            - ...
```

## Update an active version
Breaking changes are not allowed when updating an active version!
1) ...change code
2) commit & push

## Release new version
Make release note with a short overview.
1) ...change code
2) commit & push

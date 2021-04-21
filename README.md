# helllicht/ftp-sync

## IMPORTANT INFO:
If you add files/folders to the .syncignore later, they will be ignored and NOT automatically deleted from the server.
The script skips them immediately, without any comparison.
You have to delete them yourself (if wished)!
Only files and folders that are not ignored will be synchronised and deleted if they are no longer present!

This Action is using [lftp](http://lftp.yar.ru/lftp-man.html). 

## Upload filter
The Sync action already filters out some files itself: [.defaultignore](https://github.com/helllicht/ftp-sync/blob/master/.defaultignore)
You can create a .syncignore in your repository (in the root!) and have files and folders filtered there in glob style.
If the action has found a .syncignore, you can also see this in the text output.

e.g. of an valid .syncignore:
```
# .syncignore

.dockerignore
my_folder/
other_folder/dont_upload.json
# a comment :)
main.js
```
### Files
If you ignore `test.js` they will be excluded no matter where they are, recursive in all directories!
```
# .syncignore
test.js
```
```
.
├── exampleDir/
│   ├── test.js <-- not uploaded
│   └── example.json
├── importantStuff/
│   ├── test.js <-- not uploaded
│   └── whoa.png
└── test.js <-- not uploaded
```
If you want that only the `exampleDir/test.js` is ignored so use this syntax:
```
# .syncignore
exampleDir/test.js
```

### Folder
If you want to ignore folders, they must end with "/".
```
willBeUploadedDir <-- does not work

myDir/ <-- valid
```

### Comments
You can only write a comment or a file/folder, not both in one line!
```
# this is a valid comment

main.js # this not!
```

### Extended example
Nested logic for e.g. kirby CMS.
`content/` wouldn't upload `assets/content/` so we will force it. LFTP does not support better syntax for this.
```
# exclude content dir
content/ <-- ignore all content folders!
!*/content/ <-- don't ignore content folders (if they have a prefix => not in root) 
site/cache/
```

## Active versions
INFO: This action just have one active version -> master!
+ master

## How to use this action
If not already done, add following folder structure to the project (name of the yml-file is up to you).
```
.
└── .github/
    └── workflows/
        └── deploy.yml
```
Example:
> In this example just the 'staging'-Branch is deployed!
> read more about 'on:'
> here: https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions#on
```yaml
name: Deploy

on:
    push:
        branches:
            - staging

jobs:
    build:
        name: Build and deploy
        runs-on: ubuntu-18.04
        steps:
            - name: Checkout Repository
              uses: actions/checkout@v2
            # ...build your project
            - name: Sync to server
              uses: helllicht/ftp-sync@master
              with:
                  host: 'ftp.example-upload.com'
                  username: 'the_ftp_username'
                  password: ${{ secrets.SFTP_PASS }}
                  localDir: 'dist'
                  uploadPath: 'app'
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

# psakezero

[![Build status](https://ci.appveyor.com/api/projects/status/tafyfqtcuqvw4ft8/branch/master?svg=true)](https://ci.appveyor.com/project/motowilliams/script/branch/master)

## Why

There was a project 42 years ago, called Tree Surgeon, that would setup a directory structure for your next project. This was early, early .NET days, but it was a handy little utility.

init.ps1 takes some CLI observations from NPM and attempts to setup an initialized empty shell of a repo to help projects get setup quickly.

## The Defaults

- [x] source code into a root level src directory
- [x] components to deploy into an artifacts directory
- [x] permanent tools going into a tools directory
- [x] using a file named default.ps1 as your primary build script
- [x] prompts you for a few default tasks
  - [x] optional CI task that you would use on your build server
  - [x] optional TC tasks that added TeamCity blockOpened & blockClosed messages around each task
  - [x] optional nuget package restore task
  - [x] optional MSBuild octopack version of a compile task
- [x] using a bootstrapper to help with setting up and calling psake
- [x] adds a .gitattributes file
- [x] adds a .gitignore file (https://github.com/github/gitignore/blob/master/VisualStudio.gitignore)
- [x] defaults to using Nuget Package Restore
- [x] gets the latest version of Nuget and will update itself occasionally
- [ ] updates nuget occasionally
- [x] creates a readme.md file
- [ ] dynamically adds dependent tasks

## Installing

``` powershell
Invoke-WebRequest psakezero.com | Invoke-Expression
```

``` powershell
iwr psakezero.com | iex
```

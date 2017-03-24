#!/bin/bash

gitattributesUrl="https://raw.githubusercontent.com/dotnetzero/script/master/components/gitattributes.tx
gitignoreUrl="https://raw.githubusercontent.com/github/gitignore/master/VisualStudio.gitignore "

getInput () {
    message=$1
    variableDefault=$2

    if [ -z "$2" ]
    then
        read -p "$message " variable
    else
        read -p "$message ($variableDefault) " variable
        variable=${variable:-$variableDefault}
    fi

    echo $variable >&1

    return 0
}

company=$(getInput "What is your company name?")
project=$(getInput "What is your project name?")
sourceDirectory=$(getInput "Where do you want your source code directory?" "src")
artifactsPath=$(getInput "Where do you want your tools directory?" "artifacts")
toolsPath=$(getInput "Where do you want your tools directory?" "tools")
buildScript=$(getInput "Select name for build script?" "default")

echo -e "Creating readme"
echo "# $company" > readme.md
echo "## $project" >> readme.md

echo -e "Creating source code directory \e[2m$sourceDirectory\e[0m"
mkdir $sourceDirectory

echo -e "Creating artifacts directory \e[2m$artifactsPath\e[0m"
mkdir $artifactsPath

echo -e "Creating tools directory \e[2m$toolsPath\e[0m"
mkdir $toolsPath

echo -e "Creating build script \e[2m$buildScript\e[0m"
touch "$buildScript.sh"

echo -e "Getting file .gitattributes from \e[2m$gitattributesUrl\e[0m"
curl -s $gitattributesUrl > .gitattributes

echo -e "Getting file .gitignore from \e[2m$gitignoreUrl\e[0m"
curl -s $gitignoreUrl > .gitignore

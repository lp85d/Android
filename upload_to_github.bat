@echo off
SETLOCAL

SET REPO_NAME=%1
SET GITHUB_USER=lp85d

rem Read the token from the first line of the file
set /p GITHUB_TOKEN=<github_token.txt

git --version >nul 2>nul
IF !ERRORLEVEL! NEQ 0 (
    echo Git is not installed or not in PATH.
    exit /b 1
)

echo Initializing local Git repository...
git init
git add .
git commit -m "Initial commit"

echo Pushing code to existing GitHub repository...
git branch -M main
git push --force "https://%GITHUB_TOKEN%@github.com/%GITHUB_USER%/%REPO_NAME%.git" main

ENDLOCAL

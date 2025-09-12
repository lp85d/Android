@echo off
SETLOCAL

set /p GITHUB_TOKEN=<github_token.txt

echo Checking GitHub Actions status...

curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer %GITHUB_TOKEN%" https://api.github.com/repos/lp85d/Android/actions/runs

ENDLOCAL

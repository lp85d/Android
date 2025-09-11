@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

IF NOT EXIST "github_token.txt" (
    echo github_token.txt not found.
    exit /b 1
)

IF "%~1"=="" (
    echo Repository name not provided.
    exit /b 1
)

SET REPO_NAME=%1

echo Starting upload process for repository: %REPO_NAME%

CALL upload_to_github.bat %REPO_NAME%

IF !ERRORLEVEL! NEQ 0 (
    echo An error occurred during the GitHub upload.
) ELSE (
    echo Process completed successfully.
)

ENDLOCAL
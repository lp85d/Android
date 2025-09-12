@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

set "REPO_URL=https://api.github.com/repos/lp85d/Android"
set "LOG_FILE=failed_run_log.txt"
set "TOKEN_FILE=github_token.txt"

if NOT EXIST "%TOKEN_FILE%" (
    echo ERROR: %TOKEN_FILE% not found. Please create it and place your GitHub token inside.
    exit /b 1
)

set /p GITHUB_TOKEN=<%TOKEN_FILE%

:check_loop
cls
echo Checking GitHub Actions status for lp85d/Android...
echo Press Ctrl+C to stop.

rem Get the latest workflow run
for /f "delims=" %%i in ('curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer %GITHUB_TOKEN%" "%REPO_URL%/actions/runs?per_page=1"') do (
    set "JSON=%%i"
)

rem Poor man's JSON parsing in batch
set "LATEST_RUN_ID="
set "STATUS="
set "CONCLUSION="

rem Extract run_id
for /f "tokens=2 delims=," %%a in ('echo %JSON% ^| findstr /r "id"') do (
    set "TEMP_ID=%%a"
    set "LATEST_RUN_ID=!TEMP_ID:~5!"
    goto :found_id
)
:found_id

rem Extract status
for /f "tokens=2 delims=," %%a in ('echo %JSON% ^| findstr /r "status"') do (
    set "TEMP_STATUS=%%a"
    set "STATUS=!TEMP_STATUS:~9,-1!"
    goto :found_status
)
:found_status

rem Extract conclusion
for /f "tokens=2 delims=," %%a in ('echo %JSON% ^| findstr /r "conclusion"') do (
    set "TEMP_CONCLUSION=%%a"
    set "CONCLUSION=!TEMP_CONCLUSION:~13,-1!"
    goto :found_conclusion
)
:found_conclusion


echo Latest Run ID: %LATEST_RUN_ID%
echo Status: %STATUS%
echo Conclusion: %CONCLUSION%

if "%STATUS%"=="completed" (
    if "%CONCLUSION%"=="success" (
        echo.
        echo =================================
        echo.
        echo      BUILD SUCCEEDED! ^_^)
        echo.
        echo =================================
        goto :end
    ) else (
        echo.
        echo =================================
        echo.
        echo      BUILD FAILED! T_T
        echo.
        echo =================================
        echo Downloading logs for run %LATEST_RUN_ID%...
        curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer %GITHUB_TOKEN%" -o %LOG_FILE% "%REPO_URL%/actions/runs/%LATEST_RUN_ID%/logs"
        echo Logs saved to %LOG_FILE%.
        goto :end
    )
) else (
    echo.
    echo Build is in progress (%STATUS%)... Checking again in 15 seconds.
    timeout /t 15 /nobreak >nul
    goto :check_loop
)

:end
echo.
echo Script finished.
pause
ENDLOCAL
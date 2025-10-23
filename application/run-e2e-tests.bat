@echo off
REM ################################################################################
REM E2E Test Runner Script for Windows
REM
REM This script:
REM 1. Starts Docker Compose services
REM 2. Waits for the API to be healthy
REM 3. Runs e2e tests
REM 4. Cleans up Docker Compose services
REM
REM Usage:
REM   run-e2e-tests.bat                                      # Use defaults
REM   run-e2e-tests.bat --url http://localhost:5000/api/v1  # Custom URL
REM   run-e2e-tests.bat --concurrency 1000                  # Custom concurrency
REM   run-e2e-tests.bat --url <url> --concurrency 1000     # Both custom
REM ################################################################################

setlocal EnableDelayedExpansion

REM Default values
set "API_URL=http://localhost:3000/api/v1"
set "CONCURRENCY="
set "MAX_HEALTH_CHECKS=30"
set "HEALTH_CHECK_INTERVAL=2"

REM Parse command line arguments
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="--url" (
    set "API_URL=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--concurrency" (
    set "CONCURRENCY=%~2"
    shift
    shift
    goto parse_args
)
shift
goto parse_args

:args_done

echo ================================================================
echo          E2E Test Runner for Task Manager API
echo ================================================================
echo.
echo Configuration:
echo   API URL: %API_URL%
if defined CONCURRENCY (
    echo   Concurrency: %CONCURRENCY%
) else (
    echo   Concurrency: 500 ^(default^)
)
echo.

REM Step 1: Start Docker Compose
echo Step 1: Starting Docker Compose services...
docker-compose up -d

if errorlevel 1 (
    echo [ERROR] Failed to start Docker Compose services
    goto cleanup_and_exit
)

echo [OK] Docker Compose services started
echo.

REM Step 2: Wait for API to be healthy
echo Step 2: Waiting for API to be healthy...
echo   Health check URL: %API_URL%/health

set HEALTH_CHECK_COUNT=0
set API_HEALTHY=false

:health_check_loop
if %HEALTH_CHECK_COUNT% geq %MAX_HEALTH_CHECKS% goto health_check_failed

set /a HEALTH_CHECK_COUNT+=1
echo   Attempt %HEALTH_CHECK_COUNT%/%MAX_HEALTH_CHECKS%...

REM Use curl to check health endpoint
curl -s -o nul -w "%%{http_code}" "%API_URL%/health" > health_response.tmp 2>nul
set /p HEALTH_RESPONSE=<health_response.tmp
del health_response.tmp 2>nul

if "%HEALTH_RESPONSE%"=="200" (
    echo [OK] API is healthy!
    set API_HEALTHY=true
    goto health_check_done
) else (
    echo   Waiting ^(HTTP %HEALTH_RESPONSE%^)...
    timeout /t %HEALTH_CHECK_INTERVAL% /nobreak >nul
    goto health_check_loop
)

:health_check_failed
echo [ERROR] API did not become healthy within the timeout period
echo Please check Docker logs: docker-compose logs
goto cleanup_and_exit

:health_check_done
echo.

REM Step 3: Run E2E Tests
echo Step 3: Running E2E tests...
echo.

REM Build test command with optional parameters
if defined CONCURRENCY (
    set TEST_CONCURRENCY=%CONCURRENCY%
    call npm run test:e2e
) else (
    call npm run test:e2e
)

set TEST_EXIT_CODE=%ERRORLEVEL%

echo.
if %TEST_EXIT_CODE%==0 (
    echo ================================================================
    echo              [OK] ALL E2E TESTS PASSED!
    echo ================================================================
) else (
    echo ================================================================
    echo              [ERROR] SOME E2E TESTS FAILED
    echo ================================================================
)

REM Cleanup
:cleanup_and_exit
echo.
echo Cleaning up...
echo Stopping Docker Compose services...
docker-compose down -v 2>nul

if %TEST_EXIT_CODE%==0 (
    echo [OK] Tests completed successfully and cleanup done!
    exit /b 0
) else (
    echo [ERROR] Tests failed or were interrupted. Cleanup done.
    exit /b 1
)

@echo off
setlocal EnableDelayedExpansion

:: Change to the docker directory
pushd %~dp0\..

echo Gentrace Self-Hosted Environment Setup
echo =====================================
echo.
echo This script will help you set up your environment variables.
echo Press Enter to accept the default values or input your own.
echo.
echo Working directory: %CD%
echo.

:: Instructions for generating secure values
echo Before proceeding, please generate the following secure values:
echo.
echo 1. JWT Secret Key:
echo    Run this command in your terminal:
echo    openssl rand -base64 32
echo.
echo 2. Prisma Field Encryption Key:
echo    Visit https://cloak.47ng.com/ to generate a key
echo.
echo Please have these values ready before continuing.
echo.
pause
echo.

:: Function to prompt for input
:prompt
set "input="
set /p "input=%~1 [%~2]: "
if "!input!"=="" set "input=%~2"
set "%~3=!input!"
goto :eof

:: Get user inputs
call :prompt "Node environment" "production" NODE_ENV
call :prompt "Environment" "production" ENVIRONMENT
call :prompt "Enable TLS (true/false)" "true" NEXT_PUBLIC_SELF_HOSTED_TLS
call :prompt "Admin email" "admin@yourdomain.com" ADMIN_EMAIL
call :prompt "Admin name" "Admin User" ADMIN_NAME
call :prompt "Admin password" "your-secure-admin-password" ADMIN_PASSWORD
call :prompt "PostgreSQL username" "gentrace" POSTGRES_USER
call :prompt "PostgreSQL password" "gentrace123" POSTGRES_PASSWORD
call :prompt "PostgreSQL database" "gentrace" POSTGRES_DB
call :prompt "ClickHouse database" "gentrace" CLICKHOUSE_DATABASE
call :prompt "ClickHouse username" "default" CLICKHOUSE_USER
call :prompt "ClickHouse password" "gentrace123" CLICKHOUSE_PASSWORD
call :prompt "Storage access key" "your-access-key" STORAGE_ACCESS_KEY_ID
call :prompt "Storage secret key" "your-secret-key" STORAGE_SECRET_ACCESS_KEY
call :prompt "Storage endpoint" "https://storage.googleapis.com" STORAGE_ENDPOINT
call :prompt "Storage bucket" "gentrace-public" STORAGE_BUCKET
call :prompt "Storage region" "us-central1" STORAGE_REGION
call :prompt "API hostname" "api.yourdomain.com" PUBLIC_HOSTNAME
call :prompt "WebSocket hostname" "ws.yourdomain.com" WEBSOCKET_HOSTNAME
call :prompt "Task Runner hostname" "taskrunner.yourdomain.com" TASKRUNNER_HOSTNAME
call :prompt "Scheduler hostname" "scheduler.yourdomain.com" SCHEDULER_HOSTNAME

echo Enter your generated JWT secret (from openssl command):
call :prompt "JWT secret" "generate-using-openssl-command" JWT_SECRET
echo Enter your Prisma field encryption key (from cloak website):
call :prompt "Prisma field encryption key" "generate-from-cloak-website" PRISMA_FIELD_ENCRYPTION_KEY

:: Create .env file
(
echo # Common Settings
echo NODE_ENV=!NODE_ENV!
echo ENVIRONMENT=!ENVIRONMENT!
echo NEXT_PUBLIC_SELF_HOSTED=true
echo NEXT_PUBLIC_SELF_HOSTED_TLS=!NEXT_PUBLIC_SELF_HOSTED_TLS!
echo NEXT_OTEL_VERBOSE=1
echo.
echo # Admin Configuration
echo ADMIN_EMAIL=!ADMIN_EMAIL!
echo ADMIN_NAME=!ADMIN_NAME!
echo ADMIN_PASSWORD=!ADMIN_PASSWORD!
echo.
echo # PostgreSQL Configuration
echo POSTGRES_USER=!POSTGRES_USER!
echo POSTGRES_PASSWORD=!POSTGRES_PASSWORD!
echo POSTGRES_DB=!POSTGRES_DB!
echo DATABASE_URL=postgresql://!POSTGRES_USER!:!POSTGRES_PASSWORD!@postgres:5432/!POSTGRES_DB!
echo.
echo # ClickHouse Configuration
echo CLICKHOUSE_DATABASE=!CLICKHOUSE_DATABASE!
echo CLICKHOUSE_HOST=clickhouse
echo CLICKHOUSE_PORT=8123
echo CLICKHOUSE_PROTOCOL=http
echo CLICKHOUSE_USER=!CLICKHOUSE_USER!
echo CLICKHOUSE_PASSWORD=!CLICKHOUSE_PASSWORD!
echo.
echo # Kafka Configuration
echo KAFKA_BROKER=kafka
echo KAFKA_PORT=9092
echo.
echo # Object Storage Configuration
echo STORAGE_ACCESS_KEY_ID=!STORAGE_ACCESS_KEY_ID!
echo STORAGE_SECRET_ACCESS_KEY=!STORAGE_SECRET_ACCESS_KEY!
echo STORAGE_ENDPOINT=!STORAGE_ENDPOINT!
echo STORAGE_BUCKET=!STORAGE_BUCKET!
echo STORAGE_REGION=!STORAGE_REGION!
echo STORAGE_FORCE_PATH_STYLE=true
echo.
echo # Security
echo JWT_SECRET=!JWT_SECRET!
echo PRISMA_FIELD_ENCRYPTION_KEY=!PRISMA_FIELD_ENCRYPTION_KEY!
echo.
echo # Service Ports and Hostnames
echo PORT=3000
echo PUBLIC_HOSTNAME=!PUBLIC_HOSTNAME!
echo WEBSOCKET_PORT=3001
echo WEBSOCKET_HOSTNAME=!WEBSOCKET_HOSTNAME!
echo TASKRUNNER_HOSTNAME=!TASKRUNNER_HOSTNAME!
echo SCHEDULER_HOSTNAME=!SCHEDULER_HOSTNAME!
) > .env

echo.
echo Environment file created at %CD%\.env
echo Please review the generated values and adjust if needed.
echo.
echo Important:
echo 1. Make sure you've set a secure JWT_SECRET using 'openssl rand -base64 32'
echo 2. Ensure you've generated a proper encryption key from https://cloak.47ng.com/
echo.
echo Note: Keep these values secure and backed up!

:: Return to original directory
popd

endlocal 
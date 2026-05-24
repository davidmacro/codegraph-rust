@echo off
REM ABOUTME: Launches the SurrealDB 2.x server that codegraph expects to talk to.
REM ABOUTME: Defaults match install-codegraph.bat; override via SURREAL_* env vars.
setlocal EnableExtensions

if not defined SURREAL_BIN  set "SURREAL_BIN=%USERPROFILE%\.codegraph\bin\surreal.exe"
if not defined SURREAL_DATA set "SURREAL_DATA=%USERPROFILE%\.codegraph\surreal.db"
if not defined SURREAL_BIND set "SURREAL_BIND=127.0.0.1:3004"
if not defined SURREAL_USER set "SURREAL_USER=root"
if not defined SURREAL_PASS set "SURREAL_PASS=root"
if not defined SURREAL_LOG  set "SURREAL_LOG=info"

if not exist "%SURREAL_BIN%" (
    echo [ERROR] SurrealDB binary not found at "%SURREAL_BIN%". 1>&2
    echo [ERROR] Download SurrealDB 2.x (NOT 3.x — 3.x renamed SurrealQL functions and the schema 1>&2
    echo [ERROR] will not import) from: 1>&2
    echo [ERROR]   https://github.com/surrealdb/surrealdb/releases/download/v2.6.5/surreal-v2.6.5.windows-amd64.exe 1>&2
    echo [ERROR] Place it at "%SURREAL_BIN%" (or set SURREAL_BIN to its location) and re-run. 1>&2
    endlocal
    exit /b 1
)

echo [INFO] Binary:    %SURREAL_BIN%
echo [INFO] Data dir:  %SURREAL_DATA%
echo [INFO] Bind:      %SURREAL_BIND%
echo [INFO] Log level: %SURREAL_LOG%
echo [INFO] Make sure %USERPROFILE%\.codegraph\.env CODEGRAPH_SURREALDB_* vars match the bind/user/pass above.

"%SURREAL_BIN%" start ^
    --bind %SURREAL_BIND% ^
    --user %SURREAL_USER% ^
    --pass %SURREAL_PASS% ^
    --allow-all ^
    --log %SURREAL_LOG% ^
    "rocksdb://%SURREAL_DATA%"

endlocal

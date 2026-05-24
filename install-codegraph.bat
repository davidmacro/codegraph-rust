@echo off
REM ABOUTME: Windows-safe installer for codegraph-rust on the MSVC toolchain.
REM ABOUTME: Uses the SurrealDB-only local preset; avoids macOS-only features.
setlocal EnableExtensions EnableDelayedExpansion

REM We intentionally avoid `--all-features` because it pulls in macOS-only
REM crates (candle's metal backend → objc2) and jemalloc-sys (which cannot
REM build on Windows MSVC). The feature set below is the full Windows-safe
REM preset and matches what the project README's "local stack" preset uses.
set "FEATURE_FLAGS=--no-default-features --features daemon,ai-enhanced,server-http,all-rig-providers,embeddings-ollama,embeddings-lmstudio,embeddings-jina,embeddings-openai,embeddings-local,all-agents"

set "SURR_URL=ws://localhost:3004"
set "SURR_NAMESPACE=ouroboros"
set "SURR_DATABASE=codegraph"

if defined CARGO_HOME (
    set "INSTALL_PATH=%CARGO_HOME%\bin"
) else (
    set "INSTALL_PATH=%USERPROFILE%\.cargo\bin"
)

call :info "Checking prerequisites..."

where cargo >nul 2>&1
if errorlevel 1 (
    call :fail "Rust is required. Install from https://rustup.rs and re-run this script."
    endlocal
    exit /b 1
)

where surreal >nul 2>&1
if errorlevel 1 (
    call :warn "surreal CLI not found on PATH; attempting to install SurrealDB via winget."
    where winget >nul 2>&1
    if errorlevel 1 (
        call :fail "winget is not available. Install SurrealDB manually from https://surrealdb.com/install and re-run."
        endlocal
        exit /b 1
    )
    winget install --id SurrealDB.SurrealDB -e --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        call :fail "winget failed to install SurrealDB. See https://surrealdb.com/install"
        endlocal
        exit /b 1
    )
) else (
    call :info "SurrealDB CLI detected."
)

call :info "Installing codegraph (this can take several minutes on the first build)..."
call :info "Feature flags: %FEATURE_FLAGS%"

cargo install --path crates/codegraph-mcp-server --bin codegraph %FEATURE_FLAGS% --force
if errorlevel 1 (
    call :fail "cargo install failed."
    endlocal
    exit /b 1
)

call :info "codegraph installed to %INSTALL_PATH%\codegraph.exe"
echo.
call :info "Next steps:"
echo   1. Start SurrealDB in a separate terminal (recommended via start-surrealdb.bat):
echo        start-surrealdb.bat
echo   2. Create %USERPROFILE%\.codegraph\.env with at minimum:
echo        CODEGRAPH_SURREALDB_URL=%SURR_URL%
echo        CODEGRAPH_SURREALDB_NAMESPACE=%SURR_NAMESPACE%
echo        CODEGRAPH_SURREALDB_DATABASE=%SURR_DATABASE%
echo        CODEGRAPH_SURREALDB_USER=root
echo        CODEGRAPH_SURREALDB_PASS=root
echo      Plus embedding/LLM provider vars (OPENAI_API_KEY, OLLAMA_URL, JINA_API_KEY, ...).
echo   3. Index this project:
echo        codegraph index . --force
echo   4. Start the MCP server in your preferred transport:
echo        codegraph start stdio
echo      or
echo        codegraph start http --port 3000

endlocal
exit /b 0

:info
echo [INFO] %~1
goto :eof

:warn
echo [WARN] %~1
goto :eof

:fail
echo [ERROR] %~1 1>&2
goto :eof

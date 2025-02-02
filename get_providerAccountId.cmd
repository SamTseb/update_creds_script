@echo off
setlocal enabledelayedexpansion

echo.
echo Getting Provider Account ID.
echo.

REM Read TOKEN
set "TOKEN_FILE=%~dp0token"
for /f "delims=" %%A in (%TOKEN_FILE%) do (
    set "TOKEN=%%A"
)

REM Make a POST request with a body and save the JSON to a variable
for /f "delims=" %%A in ('curl --silent --request GET \
  --url https://api.com/public/v1/environment \
  --header "Authorization: !TOKEN!"') do set JSON=%%A
  
REM echo/
REM echo %JSON%
REM echo/

REM Escape quotes
set JSON_ESCAPED=!JSON:"=\"!

REM Open the file for reading
set "CLOUDS_FILE=%~dp0clouds"

REM Create a file
set "PROVIDER_ACCOUNT_ID_FILE=%~dp0providerAccountIds"
if exist "%PROVIDER_ACCOUNT_ID_FILE%" (
    del "%PROVIDER_ACCOUNT_ID_FILE%"
) else (
    type nul > "%PROVIDER_ACCOUNT_ID_FILE%"
)

for /f "delims=" %%B in (!CLOUDS_FILE!) do (
	set "CLOUD_NAME=%%B"
	for /f "delims=" %%A in ('powershell -Command "$cloudname = """!CLOUD_NAME!"""; $data = ConvertFrom-Json -InputObject '!JSON_ESCAPED!'; $id = ($data | Where-Object { $_.cloudName -eq $cloudname }); $id.providerAccountId"') do (
		set "PROVIDER_ACCOUNT_ID=%%A"
		echo !PROVIDER_ACCOUNT_ID!>>"%PROVIDER_ACCOUNT_ID_FILE%"
	)
)

REM Output NEEDED_CLOUDS
echo/
echo === PROVIDER_ACCOUNT_IDS ===
type !PROVIDER_ACCOUNT_ID_FILE!
echo =======================

endlocal
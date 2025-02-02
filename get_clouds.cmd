@echo off
setlocal enabledelayedexpansion

echo.
echo Getting clouds.
echo.

REM Read TOKEN
set "TOKEN_FILE=%~dp0token"
for /f "delims=" %%A in (%TOKEN_FILE%) do (
    set "TOKEN=%%A"
)

REM  Send POST-request and save a JSON response
for /f "delims=" %%A in ('curl --silent --request GET \
  --url https://api.com/public/v1/environment \
  --header "Authorization: !TOKEN!"') do set JSON=%%A

REM Escape quotes
set JSON_ESCAPED=!JSON:"=\"!

REM Parse Json_ESCAPED using PowerShell
for /f "delims=" %%A in ('powershell -Command "$data = ConvertFrom-Json -InputObject '%JSON_ESCAPED%'; $cloudNames = $data | ForEach-Object { $_.cloudName }; $cloudNames -join ','"') do (
	set CLOUD_NAMES=%%A
)

REM Create a file
set "CLOUDS_FILE=%~dp0clouds"
if exist "%CLOUDS_FILE%" (
    del "%CLOUDS_FILE%"
) else (
    type nul > "%CLOUDS_FILE%"
)

echo/=======================
for %%A in (!CLOUD_NAMES!) do (
		set "NAME=%%A"
		for /L %%B in (0,0,1) do (
			set /p "CHOICE=Do you want to keep updated creds for cloud !NAME! (y/n) - "
			if /I "!CHOICE!"=="y" (
				echo !NAME!>>!CLOUDS_FILE!
				exit /b
			)
			if /I "!CHOICE!"=="n" (
				exit /b
			)
			echo Invalid input. Please enter y or n.
		)
		echo/=======================
)

REM Output NEEDED_CLOUDS
echo.
echo === NEEDED_CLOUDS ===
type !CLOUDS_FILE!
echo =======================


endlocal
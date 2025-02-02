@echo off
setlocal enabledelayedexpansion

echo.
echo Getting clouds.
echo.

REM Читаем JWT_TOKEN
set "TOKEN_FILE=%~dp0token"
for /f "delims=" %%A in (%TOKEN_FILE%) do (
    set "JWT_TOKEN=%%A"
)

:: Выполняем POST-запрос с телом и сохраняем JSON в переменную
for /f "delims=" %%A in ('curl --silent --request GET \
  --url https://api.cs.telekom.de/public/v1/environment \
  --header "Authorization: !JWT_TOKEN!"') do set JSON=%%A

REM Экранировать кавычки
set JSON_ESCAPED=!JSON:"=\"!

REM Парсим JSON_ESCAPED с помощью PowerShell
for /f "delims=" %%A in ('powershell -Command "$data = ConvertFrom-Json -InputObject '%JSON_ESCAPED%'; $cloudNames = $data | ForEach-Object { $_.cloudName }; $cloudNames -join ','"') do (
	set CLOUD_NAMES=%%A
)

REM Создаем файл
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

REM Для дебага: выводим NEEDED_CLOUDS
echo/
echo === NEEDED_CLOUDS ===
type !CLOUDS_FILE!
echo =======================


endlocal
@echo off
setlocal enabledelayedexpansion

echo.
echo Getting Provider Account ID.
echo.

REM Читаем JWT_TOKEN
set "TOKEN_FILE=%~dp0token"
for /f "delims=" %%A in (%TOKEN_FILE%) do (
    set "JWT_TOKEN=%%A"
)

REM Выполняем POST-запрос с телом и сохраняем JSON в переменную
for /f "delims=" %%A in ('curl --silent --request GET \
  --url https://api.cs.telekom.de/public/v1/environment \
  --header "Authorization: !JWT_TOKEN!"') do set JSON=%%A
  
REM echo/
REM echo %JSON%
REM echo/

REM Экранировать кавычки
set JSON_ESCAPED=!JSON:"=\"!

REM Берём файл на чтение
set "CLOUDS_FILE=%~dp0clouds"

REM Создаем файл
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

REM Выводим NEEDED_CLOUDS
echo/
echo === PROVIDER_ACCOUNT_IDS ===
type !PROVIDER_ACCOUNT_ID_FILE!
echo =======================

endlocal
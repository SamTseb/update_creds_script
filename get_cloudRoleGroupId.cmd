@echo off
setlocal enabledelayedexpansion

echo.
echo Getting Cloud Role Group ID.
echo.

REM Читаем JWT_TOKEN
set "TOKEN_FILE=%~dp0token"
for /f "delims=" %%A in (%TOKEN_FILE%) do (
    set "JWT_TOKEN=%%A"
)

REM Берём файл на чтение
set "PROVIDER_ACCOUNT_ID_FILE=%~dp0providerAccountIds"

REM Создаем файл
set "CLOUD_ROLE_GROUP_ID_FILE=%~dp0cloudRoleGroupIds"
if exist "%CLOUD_ROLE_GROUP_ID_FILE%" (
    del "%CLOUD_ROLE_GROUP_ID_FILE%"
) else (
    type nul > "%CLOUD_ROLE_GROUP_ID_FILE%"
)

for /f "delims=" %%B in (!PROVIDER_ACCOUNT_ID_FILE!) do (
	set "PROVIDER_ACCOUNT_ID=%%B"
	
	REM Выполняем POST-запрос с телом и сохраняем JSON в переменную
	for /f "delims=" %%C in ('curl --silent --request GET \
	  --url https://api.cs.telekom.de/public/v1/environment/!PROVIDER_ACCOUNT_ID!/role \
	  --header "Authorization: !JWT_TOKEN!"') do set JSON=%%C
	  
	REM echo/
	REM echo !JSON!
	REM echo/
	
	REM Экранировать кавычки
	set JSON_ESCAPED=!JSON:"=\"!
	
	for /f "delims=" %%A in ('powershell -Command "$data = ConvertFrom-Json -InputObject '!JSON_ESCAPED!'; $data.groupRoles.groups.cloudRoleGroupId"') do (
		set "CLOUD_ROLE_GROUP_ID=%%A"
		echo !CLOUD_ROLE_GROUP_ID!>>"%CLOUD_ROLE_GROUP_ID_FILE%"
	)
)

echo/
echo === PROVIDER_ACCOUNT_IDS ===
type !CLOUD_ROLE_GROUP_ID_FILE!
echo =======================

endlocal
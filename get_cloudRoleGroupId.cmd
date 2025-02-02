@echo off
setlocal enabledelayedexpansion

echo.
echo Getting Cloud Role Group ID.
echo.

REM Read TOKEN
set "TOKEN_FILE=%~dp0token"
for /f "delims=" %%A in (%TOKEN_FILE%) do (
    set "TOKEN=%%A"
)

REM Open the file for reading
set "PROVIDER_ACCOUNT_ID_FILE=%~dp0providerAccountIds"

REM Create a file
set "CLOUD_ROLE_GROUP_ID_FILE=%~dp0cloudRoleGroupIds"
if exist "%CLOUD_ROLE_GROUP_ID_FILE%" (
    del "%CLOUD_ROLE_GROUP_ID_FILE%"
) else (
    type nul > "%CLOUD_ROLE_GROUP_ID_FILE%"
)

for /f "delims=" %%B in (!PROVIDER_ACCOUNT_ID_FILE!) do (
	set "PROVIDER_ACCOUNT_ID=%%B"
	
	REM Make a POST request with a body and save the JSON to a variable
	for /f "delims=" %%C in ('curl --silent --request GET \
	  --url https://api.com/public/v1/environment/!PROVIDER_ACCOUNT_ID!/role \
	  --header "Authorization: !TOKEN!"') do set JSON=%%C
	  
	REM echo/
	REM echo !JSON!
	REM echo/
	
	REM Escape quotes
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
@echo off
setlocal enabledelayedexpansion

call %~dp0get_providerAccountId.cmd
call %~dp0get_cloudRoleGroupId.cmd

echo.
echo Updating credentials.
echo.

set "CREDS_FILE=%USERPROFILE%\.aws\credentials"

REM Читаем JWT_TOKEN
set "TOKEN_FILE=%~dp0token"
for /f "delims=" %%A in (%TOKEN_FILE%) do (
    set "JWT_TOKEN=%%A"
)

REM Берём файл на чтение
set "CLOUD_ROLE_GROUP_ID_FILE=%~dp0cloudRoleGroupIds"
REM Берём файл на чтение
set "CLOUD_FILE=%~dp0clouds"

set INDEX=0

for /f "delims=" %%B in (!CLOUD_ROLE_GROUP_ID_FILE!) do (
	set "CLOUD_ROLE_GROUP_ID=%%B"
	set /a INDEX+=1
	set INDEX_1=0
	for /f "delims=" %%A in (!CLOUD_FILE!) do (
		set /a INDEX_1+=1
		if !INDEX! equ !INDEX_1! (
			set "SECTION_NAME=%%A"
		)
	)
	set SECTION=[!SECTION_NAME!]
	
	REM Выполняем POST-запрос с телом и сохраняем JSON в переменную
	for /f "delims=" %%A in ('curl --silent --silent --request POST \
	  --url https://api.cs.telekom.de/public/v1/credentials \
	  --header "Authorization:!JWT_TOKEN! " --header "content-type: application/json" \
	  --data "{ \"generateLink\": false, \"cloudRoleGroupId\": !CLOUD_ROLE_GROUP_ID! }"') do set JSON=%%A
	  
	REM echo === JSON ===
	REM echo !JSON!
	REM echo =======================

	REM Экранировать кавычки
	set JSON_ESCAPED=!JSON:"=\"!
	
	REM echo === JSON_ESCAPED ===
	REM echo !JSON_ESCAPED!
	REM echo =======================

	REM Парсим JSON_ESCAPED с помощью PowerShell
	for /f "delims=" %%A in ('powershell -Command "$data = ConvertFrom-Json -InputObject '!JSON_ESCAPED!'; $data.sessionId"') do set AWS_ACCESS_KEY_ID_NEW=%%A
	for /f "delims=" %%A in ('powershell -Command "$data = ConvertFrom-Json -InputObject '!JSON_ESCAPED!'; $data.sessionKey"') do set AWS_SECRET_ACCESS_KEY_NEW=%%A
	for /f "delims=" %%A in ('powershell -Command "$data = ConvertFrom-Json -InputObject '!JSON_ESCAPED!'; $data.sessionToken"') do set AWS_SESSION_TOKEN_NEW=%%A
	
	REM echo === New values ===
	REM echo AWS_ACCESS_KEY_ID_NEW=!AWS_ACCESS_KEY_ID_NEW!
	REM echo AWS_SECRET_ACCESS_KEY_NEW=!AWS_SECRET_ACCESS_KEY_NEW!
	REM echo AWS_SESSION_TOKEN_NEW=!AWS_SESSION_TOKEN_NEW!
	REM echo =======================

	REM Создаем временный файл
	set "TEMP_FILE=!CREDS_FILE!.tmp"
	if exist "!TEMP_FILE!" del "!TEMP_FILE!"

	REM Флаги для определения нужного блока в файле
	set "IN_SECTION=0"
	set "LAST_LINE_WAS_EMPTY=1"

	REM Читаем creds построчно и заменяем нужные строки
	for /f "delims=" %%A in (!CREDS_FILE!) do (
		set "LINE=%%A"

		REM Если строка пуста - запомним
		if "!LINE!"=="" set "LAST_LINE_WAS_EMPTY=1"
		
		REM Если строка начинается с [, значит, это новая секция
		if "!LINE:~0,1!"=="[" (
			REM Добавляем пустую строку перед секцией
			if !LAST_LINE_WAS_EMPTY! == 0 (
				echo/>>"!TEMP_FILE!"
			)
			set "LAST_LINE_WAS_EMPTY=0"
			REM Определяем начало секции DTIT_DevT-Magic_Dev
			if "!LINE!"=="!SECTION!" (
				set "IN_SECTION=1"
			)
		)

		REM Если в секции - заменяем нужные строки
		if !IN_SECTION! == 1 (
			if "!LINE:aws_access_key_id=!" NEQ "!LINE!" set "LINE=aws_access_key_id=!AWS_ACCESS_KEY_ID_NEW!"
			if "!LINE:aws_secret_access_key=!" NEQ "!LINE!" set "LINE=aws_secret_access_key=!AWS_SECRET_ACCESS_KEY_NEW!"
			if "!LINE:aws_session_token=!" NEQ "!LINE!" set "LINE=aws_session_token=!AWS_SESSION_TOKEN_NEW!"
		)

		REM Определяем конец секции (следующая [секция])
		if "!LINE:~0,1!"=="[" if not "!LINE!"=="!SECTION!" set "IN_SECTION=0"

		echo/!LINE!>>"!TEMP_FILE!"
	)

	REM Заменяем старый файл новым
	move /y "!TEMP_FILE!" "!CREDS_FILE!" >nul
)

echo === New creds ===
type !CREDS_FILE!
echo =======================

endlocal
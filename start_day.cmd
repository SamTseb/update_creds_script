@echo off
setlocal enabledelayedexpansion

echo.
echo Hi %USERNAME%,
echo.

echo Please, put your JWT or leave it empty 
echo if you want to use the current one:
echo.
for /f "delims=" %%A in ('powershell -Command "$input = Read-Host; $input"') do set "JWT_TOKEN=%%A"
echo.

if not "!JWT_TOKEN!"=="" (
	echo Update Token.
	echo.

	REM REM Создаем файл
	set "TOKEN_FILE=%~dp0token"
	
	if exist !TOKEN_FILE! (
		del !TOKEN_FILE!
	) else (
		echo !JWT_TOKEN! > !TOKEN_FILE!
	)

	echo Token is updated.
) else (
	echo Continue with current JWT Token.
)

REM Уникальное имя задачи
set "TASK_NAME=UpdateCredentialsToday"
set "SCRIPT_PATH=%~dp0update_credentials.cmd"

REM Удаляем задачу, если она уже существует (на случай повторного запуска)
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

REM Создаём новую задачу с повторением каждые 3.5 часа
schtasks /create /tn "%TASK_NAME%" /tr "%SCRIPT_PATH%" /sc hourly /mo 3 /st 08:00 /sd %DATE% /f

REM Удаляем задачу после 23:00
schtasks /create /tn "Remove_%TASK_NAME%" /tr "schtasks /delete /tn %TASK_NAME% /f" /sc once /st 23:00 /sd %DATE% /f


echo The task "%TASK_NAME%" has been created. The script will be executed every 3.5 hours until 23:00.

echo.
echo Start update credentials script.
echo.

call "%SCRIPT_PATH%"

endlocal
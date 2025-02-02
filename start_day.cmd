@echo off
setlocal enabledelayedexpansion

echo.
echo Hi %USERNAME%,
echo.

echo Please, put your JWT or leave it empty 
echo if you want to use the current one:
echo.
for /f "delims=" %%A in ('powershell -Command "$input = Read-Host; $input"') do set "TOKEN=%%A"
echo.

if not "!TOKEN!"=="" (
	echo Update Token.
	echo.

	REM Create a token file
	set "TOKEN_FILE=%~dp0\data\token"
	
	if exist !TOKEN_FILE! (
		del !TOKEN_FILE!
	) else (
		echo !TOKEN! > !TOKEN_FILE!
	)

	echo Token is updated.
) else (
	echo Continue with current JWT Token.
)

REM Unique task name
set "TASK_NAME=UpdateCredentialsToday"
set "SCRIPT_PATH=%~dp0\data\update_credentials.cmd"

REM Delete the task if it already exists (in case of a rerun)
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

REM Create a new task with a repeat interval of every 3.5 hours
schtasks /create /tn "%TASK_NAME%" /tr "%SCRIPT_PATH%" /sc hourly /mo 3 /st 08:00 /sd %DATE% /f

REM Delete the task after 11:00 PM
schtasks /create /tn "Remove_%TASK_NAME%" /tr "schtasks /delete /tn %TASK_NAME% /f" /sc once /st 23:00 /sd %DATE% /f


echo The task "%TASK_NAME%" has been created. The script will be executed every 3.5 hours until 23:00.

echo.
echo Start update credentials script.
echo.

call "%SCRIPT_PATH%"

endlocal
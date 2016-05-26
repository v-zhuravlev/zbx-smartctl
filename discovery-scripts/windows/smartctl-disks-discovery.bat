@echo off
setlocal enabledelayedexpansion
set /a counter=0
set /a params=0
set smartctl_path=C:\usr\zabbix\smartmontools\bin\smartctl.exe

FOR /F "tokens=1" %%i IN ('!smartctl_path! --scan') DO (
	set /a params+=1
)

echo {"data":[
for /f "tokens=1 delims= " %%i in ('!smartctl_path! --scan') do (
	set /a counter+=1

	FOR /F "tokens=1" %%a IN ('!smartctl_path! -i %%i ^|find "SMART" ^| find /C "Available"') DO (
		set /a smart_enabled=%%a
	)

	if not !counter! EQU !params! (
		echo {"{#DISKNAME}":"%%i","{#SMART_ENABLED}":"!smart_enabled!"},
	) else (
		echo {"{#DISKNAME}":"%%i","{#SMART_ENABLED}":"!smart_enabled!"}
	)

)
echo ]}

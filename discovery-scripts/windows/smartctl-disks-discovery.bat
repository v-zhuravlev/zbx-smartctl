@echo off
setlocal enabledelayedexpansion

set smartctl_path=C:\usr\zabbix\smartmontools\bin\smartctl.exe
set serials=dummy_serial
set /a first=1

echo {"data":[
for /f "tokens=1 delims= " %%i in ('!smartctl_path! --scan') do (
	
    set duplicate=0
    for /F "tokens=3*" %%a in ('!smartctl_path! -i %%i ^| find "Serial Number"') do (
        set serial=%%a
    )

        rem duplicate disk entity, check by serial number
        for %%j in (!serials!) do (if %%j == !serial! (set /a duplicate+=1)) 
        set serials=%serials% !serial!

    
	FOR /F "tokens=1" %%a IN ('!smartctl_path! -i %%i ^|find "SMART" ^| find /C "Available"') DO (
		set /a smart_enabled=%%a
	)
    if not !duplicate! == 1 (
            if not !first! ==1 (
                echo ,
            )
            echo {"{#DISKNAME}":"%%i","{#SMART_ENABLED}":"!smart_enabled!"}
            set /a first=0
    )
)
echo ]}

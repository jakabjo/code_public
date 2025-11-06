@echo off
setlocal

:: Set the path to the PowerShell script
set "powershellScript=C:\path\to\your\chirper.ps1"

:: Set the path to the Startup folder
set "startupFolder=%AppData%\Microsoft\Windows\Start Menu\Programs\Startup\"

:: Create a shortcut to the PowerShell script
powershell -Command "$WScriptShell = New-Object -ComObject WScript.Shell; $Shortcut = $WScriptShell.CreateShortcut('%startupFolder%Chirp.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-File `"%powershellScript%`"'; $Shortcut.Save()"

:: Output a message indicating the shortcut has been created
echo Shortcut "Chirp" created in the Startup folder successfully.

endlocal
pause
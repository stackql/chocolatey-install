@echo off
echo.
echo    _____________  _______ ______    __ 
echo   / __/_  __/ _ ^|/ ___/ //_/ __ \  / / 
echo  _\ \  / / / __ / /__/ ,^< / /_/ / / /__
echo /___/ /_/ /_/ ^|_\___/_/^|_^|\___\_\/____/
echo.
echo Welcome to StackQL!
echo.
echo To run authenticated queries against a cloud or SaaS provider, set the environment variable STACKQL_AUTH before launching the stackql command shell
echo.
echo For more information, visit https://stackql.io/docs
echo.
pause
powershell.exe -noexit -command "$Auth = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'STACKQL_AUTH' -ErrorAction SilentlyContinue).STACKQL_AUTH; if(!$Auth){$Auth='{}'}; cd $HOME; & 'stackql.exe' shell --auth=$Auth"
pause
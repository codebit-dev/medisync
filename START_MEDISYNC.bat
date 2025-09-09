@echo off
echo ===============================================
echo     MEDISYNC - EHR Integration Platform
echo ===============================================
echo.

echo Starting Backend Server...
start "MEDISYNC Backend" cmd /k "cd /d D:\coding\Project\MEDISYNC && venv\Scripts\activate && python start_backend.py"

timeout /t 5 /nobreak > nul

echo Starting Frontend Application...
start "MEDISYNC Frontend" cmd /k "cd /d D:\coding\Project\MEDISYNC\medisync-frontend && npm start"

echo.
echo ===============================================
echo Services are starting...
echo.
echo Please wait 10-15 seconds for full initialization
echo.
echo Then access:
echo   Frontend: http://localhost:3000
echo   API Docs: http://localhost:5000/docs
echo.
echo Login with:
echo   Username: demo
echo   Password: demo123
echo ===============================================
echo.

timeout /t 10 /nobreak > nul
start http://localhost:3000

pause

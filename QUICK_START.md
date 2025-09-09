# MEDISYNC - Quick Start Guide

## 🚀 One-Click Start

### Windows Users:
**Double-click `START_MEDISYNC.bat`** to launch both backend and frontend automatically.

### Manual Start:

#### Backend (Terminal 1):
```bash
cd D:\coding\Project\MEDISYNC
.\venv\Scripts\activate
python start_backend.py
```

#### Frontend (Terminal 2):
```bash
cd D:\coding\Project\MEDISYNC\medisync-frontend
npm start
```

## 🌐 Access Points

Once both services are running:

- **Frontend Application**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **API Documentation**: http://localhost:5000/docs
- **Health Check**: http://localhost:5000/health

## 🔐 Login Credentials

- **Username**: `demo`
- **Password**: `demo123`

## ✅ Verify Services

Run this command to check if everything is working:
```powershell
.\verify_system.ps1
```

## 📝 Test Features

1. **Login**: Use demo credentials
2. **Dashboard**: View system statistics
3. **Code Search**: Search for NAMASTE or ICD-11 codes (works without login)
4. **Upload CSV**: Upload NAMASTE codes CSV file
5. **API Docs**: Explore and test API endpoints at http://localhost:5000/docs

## 🛠️ Troubleshooting

### If services don't start:

1. **Kill existing processes**:
```powershell
Get-Process | Where {$_.ProcessName -match "python|node"} | Stop-Process -Force
```

2. **Restart services**:
```powershell
.\START_MEDISYNC.bat
```

### If frontend shows errors:

1. **Reinstall dependencies**:
```bash
cd medisync-frontend
npm install --legacy-peer-deps
```

### If backend shows errors:

1. **Check Python environment**:
```bash
.\venv\Scripts\activate
pip install -r requirements.txt
```

## 📊 Sample Data

Upload the included `sample_namaste_codes.csv` file to populate the database with traditional medicine codes.

## 🔥 Features Available

- ✅ NAMASTE Code Management
- ✅ ICD-11 Integration (requires WHO API credentials)
- ✅ Code Search with Auto-complete
- ✅ FHIR R4 Compliant APIs
- ✅ OAuth 2.0 Authentication (Mock)
- ✅ Audit Logging
- ✅ Swagger API Documentation

## 📞 Support

For issues, check:
1. Backend logs in the terminal running Flask
2. Frontend logs in the browser console (F12)
3. API responses at http://localhost:5000/docs

---
**Happy coding with MEDISYNC!** 🏥💊

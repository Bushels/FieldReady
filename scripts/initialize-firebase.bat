@echo off
setlocal enabledelayedexpansion

REM FieldReady Firebase Project Initialization Script (Windows)
REM This script sets up the Firebase backend and validates the configuration

echo 🌾 Initializing FieldReady Firebase Project...

REM Function to check if a command exists
:check_command
where %1 >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ %1 is not installed. Please install it first.
    pause
    exit /b 1
) else (
    echo ✅ %1 is available
)
goto :eof

REM Check prerequisites
echo 📋 Checking prerequisites...

call :check_command firebase
call :check_command node
call :check_command npm

REM Check if Firebase is logged in
firebase projects:list >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️ You need to login to Firebase. Running firebase login...
    firebase login
)

REM Check if we're in a Firebase project directory
if not exist "firebase.json" (
    echo ❌ firebase.json not found. Make sure you're in the FieldReady project directory.
    pause
    exit /b 1
)

echo ✅ Prerequisites met

REM Install Cloud Functions dependencies
echo 📦 Installing Cloud Functions dependencies...

cd functions
if not exist "package.json" (
    echo ❌ functions\package.json not found
    pause
    exit /b 1
)

call npm install
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Failed to install Cloud Functions dependencies
    pause
    exit /b 1
)

echo ✅ Cloud Functions dependencies installed

REM Build TypeScript
echo 🔨 Building TypeScript...
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️ TypeScript build failed, but continuing...
)

cd ..

REM Validate Firebase configuration
echo 🔍 Validating Firebase configuration...

REM Check required files
if exist "firestore.rules" (
    echo ✅ Firestore rules found
) else (
    echo ❌ firestore.rules not found
    pause
    exit /b 1
)

if exist "firestore.indexes.json" (
    echo ✅ Firestore indexes configuration found
) else (
    echo ❌ firestore.indexes.json not found
    pause
    exit /b 1
)

if exist "storage.rules" (
    echo ✅ Storage rules found
) else (
    echo ❌ storage.rules not found
    pause
    exit /b 1
)

REM Create environment configuration if it doesn't exist
if not exist ".env.local" (
    echo ⚙️ Creating local environment configuration...
    
    (
        echo # Firebase Configuration
        echo NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key_here
        echo NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
        echo NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
        echo NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com
        echo NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
        echo NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
        echo.
        echo # Development Mode
        echo NEXT_PUBLIC_USE_FIREBASE_EMULATORS=true
        echo NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST=localhost:8080
        echo NEXT_PUBLIC_FUNCTIONS_EMULATOR_HOST=localhost:5001
        echo NEXT_PUBLIC_AUTH_EMULATOR_HOST=localhost:9099
        echo.
        echo # Environment
        echo NODE_ENV=development
    ) > .env.local
    
    echo ✅ Created .env.local template
    echo ⚠️ Please update .env.local with your actual Firebase configuration
) else (
    echo ✅ Environment configuration exists
)

REM Create development commands script
(
    echo @echo off
    echo echo 🔥 Starting FieldReady development environment...
    echo echo Starting Firebase emulators...
    echo start /B firebase emulators:start
    echo timeout /t 10 /nobreak ^>nul
    echo echo ✅ Development environment ready!
    echo echo 📊 Firebase Emulator UI: http://localhost:4000
    echo echo 🔧 Firestore: http://localhost:8080
    echo echo ⚡ Functions: http://localhost:5001
    echo echo 🔐 Auth: http://localhost:9099
    echo echo.
    echo echo Press any key to stop services and exit...
    echo pause ^>nul
    echo taskkill /f /im node.exe /fi "WINDOWTITLE eq Firebase*" ^>nul 2^>^&1
) > run-dev.bat

echo ✅ Created development startup script (run-dev.bat)

REM Create project documentation
(
    echo # FieldReady Firebase Project Setup
    echo.
    echo ## Quick Start
    echo 1. Update .env.local with your Firebase project configuration
    echo 2. Run run-dev.bat to start the development environment
    echo 3. Visit http://localhost:4000 for the Firebase Emulator UI
    echo.
    echo ## Development Commands
    echo - `firebase emulators:start` - Start all Firebase emulators
    echo - `firebase deploy --only functions` - Deploy Cloud Functions
    echo - `firebase firestore:rules:test` - Test security rules
    echo.
    echo ## Architecture
    echo - Firestore: Document database for combine specifications and user data
    echo - Cloud Functions: Server-side logic for normalization and insights
    echo - Authentication: User management with Firebase Auth
    echo - Storage: File uploads and cached data
    echo.
    echo ## Key Collections
    echo - combineSpecs: Master combine specifications
    echo - userCombines: User's personal equipment
    echo - combineInsights: Regional aggregated insights
    echo - auditLogs: PIPEDA compliance tracking
    echo.
    echo See PROJECT_SETUP.md for detailed documentation.
) > QUICK_START.md

echo ✅ Created quick start guide (QUICK_START.md)

REM Final validation
echo 🧪 Running final validation...

set "validation_passed=true"

if not exist "firebase.json" set "validation_passed=false" & echo ❌ firebase.json missing
if not exist "firestore.rules" set "validation_passed=false" & echo ❌ firestore.rules missing
if not exist "firestore.indexes.json" set "validation_passed=false" & echo ❌ firestore.indexes.json missing
if not exist "storage.rules" set "validation_passed=false" & echo ❌ storage.rules missing
if not exist "functions\package.json" set "validation_passed=false" & echo ❌ functions\package.json missing

if "!validation_passed!"=="false" (
    echo ❌ Validation failed
    pause
    exit /b 1
)

REM Success message
echo.
echo 🎉 FieldReady Firebase project initialization completed successfully!
echo.
echo 📋 Next Steps:
echo 1. Update .env.local with your Firebase project configuration
echo 2. Run run-dev.bat to start the development environment
echo 3. Visit http://localhost:4000 for the Firebase Emulator UI
echo 4. Review QUICK_START.md for immediate next steps
echo.
echo ⚠️ Remember to:
echo • Configure your Firebase project settings
echo • Set up authentication providers
echo • Review and customize security rules
echo • Test all functionality before deploying to production
echo.
echo 🌾 Happy farming with FieldReady!
echo.
pause
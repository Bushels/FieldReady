@echo off
REM FieldFirst Project Initialization Script for Windows
REM This script sets up the complete project structure for FieldFirst

echo Initializing FieldFirst Project Structure...

echo Creating directory structure...

REM Frontend directories
mkdir frontend\src\app 2>nul
mkdir frontend\src\components 2>nul
mkdir frontend\src\services 2>nul
mkdir frontend\src\hooks 2>nul
mkdir frontend\src\utils 2>nul
mkdir frontend\src\types 2>nul
mkdir frontend\src\app\fields 2>nul
mkdir frontend\src\app\harvest 2>nul
mkdir frontend\src\app\combines 2>nul
mkdir frontend\src\app\community 2>nul
mkdir frontend\src\app\alerts 2>nul
mkdir frontend\src\components\common 2>nul
mkdir frontend\src\components\weather 2>nul
mkdir frontend\src\components\fields 2>nul
mkdir frontend\src\components\alerts 2>nul
mkdir frontend\src\components\combines 2>nul
mkdir frontend\src\services\api 2>nul
mkdir frontend\src\services\weather 2>nul
mkdir frontend\src\services\fields 2>nul
mkdir frontend\src\services\combines 2>nul
mkdir frontend\src\services\alerts 2>nul
mkdir frontend\public\images 2>nul
mkdir frontend\tests\unit 2>nul
mkdir frontend\tests\integration 2>nul
mkdir frontend\tests\e2e 2>nul

REM Backend directories
mkdir backend\src\api 2>nul
mkdir backend\src\services 2>nul
mkdir backend\src\models 2>nul
mkdir backend\src\middleware 2>nul
mkdir backend\src\config 2>nul
mkdir backend\src\utils 2>nul
mkdir backend\src\api\auth 2>nul
mkdir backend\src\api\fields 2>nul
mkdir backend\src\api\weather 2>nul
mkdir backend\src\api\alerts 2>nul
mkdir backend\src\api\combines 2>nul
mkdir backend\src\api\community 2>nul
mkdir backend\src\services\weather 2>nul
mkdir backend\src\services\fields 2>nul
mkdir backend\src\services\alerts 2>nul
mkdir backend\src\services\combines 2>nul
mkdir backend\src\services\community 2>nul
mkdir backend\src\models\user 2>nul
mkdir backend\src\models\field 2>nul
mkdir backend\src\models\weather 2>nul
mkdir backend\src\models\combine 2>nul
mkdir backend\src\models\alert 2>nul
mkdir backend\tests\unit 2>nul
mkdir backend\tests\integration 2>nul
mkdir backend\scripts 2>nul

REM Database directories
mkdir database\migrations 2>nul
mkdir database\seeds 2>nul
mkdir database\schemas 2>nul

REM Documentation
mkdir docs\api 2>nul
mkdir docs\architecture 2>nul
mkdir docs\deployment 2>nul

REM Configuration files
mkdir config 2>nul

echo.
echo Project structure initialized successfully!
echo.
echo Next steps:
echo 1. Review the EXECUTION_PLAN.md for detailed implementation steps
echo 2. Run 'npm install' in frontend and backend directories
echo 3. Configure environment variables by copying .env.example to .env
echo 4. Start the development environment with docker-compose
echo.
echo Happy farming with FieldFirst!

pause
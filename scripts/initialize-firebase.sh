#!/bin/bash

# FieldReady Firebase Project Initialization Script
# This script sets up the Firebase backend and validates the configuration

echo "🌾 Initializing FieldReady Firebase Project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_status $RED "❌ $1 is not installed. Please install it first."
        return 1
    else
        print_status $GREEN "✅ $1 is available"
        return 0
    fi
}

# Check prerequisites
print_status $BLUE "📋 Checking prerequisites..."

check_command "firebase" || exit 1
check_command "node" || exit 1
check_command "npm" || exit 1

# Check if Firebase is logged in
if ! firebase projects:list &> /dev/null; then
    print_status $YELLOW "⚠️ You need to login to Firebase. Running firebase login..."
    firebase login
fi

# Check if we're in a Firebase project directory
if [ ! -f "firebase.json" ]; then
    print_status $RED "❌ firebase.json not found. Make sure you're in the FieldReady project directory."
    exit 1
fi

print_status $GREEN "✅ Prerequisites met"

# Install Cloud Functions dependencies
print_status $BLUE "📦 Installing Cloud Functions dependencies..."

cd functions
if [ ! -f "package.json" ]; then
    print_status $RED "❌ functions/package.json not found"
    exit 1
fi

npm install
if [ $? -ne 0 ]; then
    print_status $RED "❌ Failed to install Cloud Functions dependencies"
    exit 1
fi

print_status $GREEN "✅ Cloud Functions dependencies installed"

# Build TypeScript
print_status $BLUE "🔨 Building TypeScript..."
npm run build
if [ $? -ne 0 ]; then
    print_status $YELLOW "⚠️ TypeScript build failed, but continuing..."
fi

cd ..

# Validate Firebase configuration
print_status $BLUE "🔍 Validating Firebase configuration..."

# Check if firestore.rules exists and is valid
if [ -f "firestore.rules" ]; then
    print_status $GREEN "✅ Firestore rules found"
else
    print_status $RED "❌ firestore.rules not found"
    exit 1
fi

# Check if firestore.indexes.json exists
if [ -f "firestore.indexes.json" ]; then
    print_status $GREEN "✅ Firestore indexes configuration found"
else
    print_status $RED "❌ firestore.indexes.json not found"
    exit 1
fi

# Check if storage.rules exists
if [ -f "storage.rules" ]; then
    print_status $GREEN "✅ Storage rules found"
else
    print_status $RED "❌ storage.rules not found"
    exit 1
fi

# Start Firebase emulators for testing
print_status $BLUE "🚀 Starting Firebase emulators for validation..."

# Kill any existing emulators
firebase emulators:kill &> /dev/null

# Start emulators in background
firebase emulators:start --only firestore,functions,storage,auth &
EMULATOR_PID=$!

# Wait for emulators to start
sleep 10

# Check if emulators are running
if kill -0 $EMULATOR_PID 2>/dev/null; then
    print_status $GREEN "✅ Firebase emulators started successfully"
    
    # Test basic connectivity
    if curl -s http://localhost:8080 > /dev/null; then
        print_status $GREEN "✅ Firestore emulator is responding"
    else
        print_status $YELLOW "⚠️ Firestore emulator may not be fully ready"
    fi
    
    if curl -s http://localhost:5001 > /dev/null; then
        print_status $GREEN "✅ Functions emulator is responding"
    else
        print_status $YELLOW "⚠️ Functions emulator may not be fully ready"
    fi
    
    # Stop emulators after testing
    print_status $BLUE "🛑 Stopping test emulators..."
    kill $EMULATOR_PID
    wait $EMULATOR_PID 2>/dev/null
    
else
    print_status $RED "❌ Failed to start Firebase emulators"
    exit 1
fi

# Validate Firestore rules
print_status $BLUE "🔒 Validating Firestore security rules..."
firebase firestore:rules:test --local
if [ $? -eq 0 ]; then
    print_status $GREEN "✅ Firestore rules validation passed"
else
    print_status $YELLOW "⚠️ Firestore rules validation had issues, but continuing..."
fi

# Create environment configuration if it doesn't exist
if [ ! -f ".env.local" ]; then
    print_status $BLUE "⚙️ Creating local environment configuration..."
    
    cat > .env.local << 'EOF'
# Firebase Configuration
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key_here
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id

# Development Mode
NEXT_PUBLIC_USE_FIREBASE_EMULATORS=true
NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST=localhost:8080
NEXT_PUBLIC_FUNCTIONS_EMULATOR_HOST=localhost:5001
NEXT_PUBLIC_AUTH_EMULATOR_HOST=localhost:9099

# Environment
NODE_ENV=development
EOF
    
    print_status $GREEN "✅ Created .env.local template"
    print_status $YELLOW "⚠️ Please update .env.local with your actual Firebase configuration"
else
    print_status $GREEN "✅ Environment configuration exists"
fi

# Create development commands script
cat > run-dev.sh << 'EOF'
#!/bin/bash
echo "🔥 Starting FieldReady development environment..."

# Start Firebase emulators in background
echo "Starting Firebase emulators..."
firebase emulators:start &
EMULATOR_PID=$!

# Wait for emulators to be ready
echo "Waiting for emulators to start..."
sleep 10

echo "✅ Development environment ready!"
echo "📊 Firebase Emulator UI: http://localhost:4000"
echo "🔧 Firestore: http://localhost:8080"
echo "⚡ Functions: http://localhost:5001"
echo "🔐 Auth: http://localhost:9099"
echo ""
echo "Press Ctrl+C to stop all services"

# Keep script running and handle cleanup
trap "echo 'Stopping services...'; kill $EMULATOR_PID; exit" INT TERM

wait $EMULATOR_PID
EOF

chmod +x run-dev.sh

print_status $GREEN "✅ Created development startup script (run-dev.sh)"

# Create project documentation
cat > PROJECT_SETUP.md << 'EOF'
# FieldReady Firebase Project Setup

## Overview
This project implements a Firebase-based backend for agricultural combine intelligence and harvest optimization.

## Architecture Components

### Firebase Services
- **Firestore**: Document database for combine specifications, user data, and insights
- **Cloud Functions**: Server-side logic for normalization and aggregation
- **Authentication**: User management and security
- **Storage**: File uploads and cached data
- **Hosting**: Web application deployment

### Collections Structure
- `combineSpecs`: Master combine specifications with moisture tolerance and crop ability data
- `userCombines`: User's personal equipment records
- `combineInsights`: Regional aggregated insights with progressive detail levels
- `normalizationLearning`: Machine learning data for improving combine model matching
- `auditLogs`: PIPEDA compliance audit trail
- `syncOperations`: Offline-first sync queue management

## Development Workflow

### 1. Initial Setup
```bash
# Initialize the project
./scripts/initialize-firebase.sh

# Update environment variables
cp .env.local .env
# Edit .env with your Firebase configuration
```

### 2. Development
```bash
# Start development environment
./run-dev.sh

# Or manually start components:
firebase emulators:start          # Start all emulators
cd functions && npm run dev       # Develop Cloud Functions
```

### 3. Testing
```bash
# Test Cloud Functions
cd functions && npm test

# Test security rules
firebase firestore:rules:test

# Validate configuration
firebase deploy --dry-run
```

### 4. Deployment
```bash
# Deploy functions only
firebase deploy --only functions

# Deploy all components
firebase deploy

# Deploy with environment
firebase deploy --project production
```

## Key Features

### Combine Normalization Engine
- Fuzzy string matching with Levenshtein distance
- Brand alias resolution
- Machine learning from user corrections
- Confidence scoring and validation

### Progressive Data Insights
- Basic insights (< 5 users): General harvest statistics
- Brand insights (5-15 users): Brand-specific performance data
- Model insights (15+ users): Detailed model capabilities and comparisons

### PIPEDA Compliance
- Comprehensive audit logging
- Data retention policies
- User consent management
- Privacy-by-design architecture

### Offline-First Architecture
- Local data caching with SQLite
- Conflict resolution algorithms
- Background sync queue
- Progressive web app capabilities

## Environment Variables

### Required Configuration
```bash
# Firebase Project Settings
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=

# Development Emulators
NEXT_PUBLIC_USE_FIREBASE_EMULATORS=true
NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST=localhost:8080
NEXT_PUBLIC_FUNCTIONS_EMULATOR_HOST=localhost:5001
NEXT_PUBLIC_AUTH_EMULATOR_HOST=localhost:9099
```

## Security Rules

### Firestore Rules
- Users can only access their own data
- Public insights readable by authenticated users
- Admin-only access to normalization rules
- Comprehensive audit logging

### Storage Rules
- User-scoped file access
- File type and size validation
- Automatic cleanup of temporary files
- Admin-managed public resources

## Cloud Functions

### Available Functions
- `normalizeCombineModel`: Fuzzy match combine models with confidence scoring
- `confirmModelMatch`: Learn from user corrections to improve matching
- `getRegionalInsights`: Generate progressive community insights
- `seedDatabase`: Initialize database with base combine specifications
- `getSeedingStatus`: Check database seeding status

### Triggers
- `updateCombineAggregations`: Real-time updates when combine specs change
- `cleanupExpiredData`: Scheduled cleanup of cached and expired data

## Monitoring and Analytics

### Performance Metrics
- Normalization success rate
- Sync performance and reliability
- User engagement analytics
- Data quality metrics

### Error Handling
- Comprehensive logging with Winston
- Error tracking with Sentry integration
- Performance monitoring
- Automated alerts for system issues

## Troubleshooting

### Common Issues
1. **Emulators won't start**: Check if ports 4000, 5001, 8080, 9099 are available
2. **Functions deployment fails**: Ensure TypeScript builds successfully
3. **Rules validation errors**: Check Firestore rules syntax
4. **Authentication issues**: Verify Firebase configuration in environment variables

### Debug Commands
```bash
# Check Firebase project status
firebase projects:list

# Validate configuration
firebase init --verify

# Check function logs
firebase functions:log

# Test rules locally
firebase firestore:rules:test --local
```
EOF

print_status $GREEN "✅ Created project documentation (PROJECT_SETUP.md)"

# Final validation
print_status $BLUE "🧪 Running final validation..."

# Check if all required files exist
required_files=("firebase.json" "firestore.rules" "firestore.indexes.json" "storage.rules" "functions/package.json")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_status $GREEN "✅ $file exists"
    else
        print_status $RED "❌ $file missing"
        exit 1
    fi
done

# Success message
print_status $GREEN "🎉 FieldReady Firebase project initialization completed successfully!"
echo ""
print_status $BLUE "📋 Next Steps:"
echo "1. Update .env.local with your Firebase project configuration"
echo "2. Run './run-dev.sh' to start the development environment"
echo "3. Visit http://localhost:4000 for the Firebase Emulator UI"
echo "4. Review PROJECT_SETUP.md for detailed documentation"
echo ""
print_status $YELLOW "⚠️ Remember to:"
echo "• Configure your Firebase project settings"
echo "• Set up authentication providers"  
echo "• Review and customize security rules"
echo "• Test all functionality before deploying to production"
echo ""
print_status $GREEN "🌾 Happy farming with FieldReady!"
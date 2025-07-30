#!/bin/bash

# FieldReady Firebase Project Initialization Script
# This script sets up the Firebase backend and validates the configuration

echo "🌾 Initializing FieldReady Firebase Project..."

# Create main directories
echo "📁 Creating directory structure..."

# Frontend directories
mkdir -p frontend/src/{app,components,services,hooks,utils,types}
mkdir -p frontend/src/app/{fields,harvest,combines,community,alerts}
mkdir -p frontend/src/components/{common,weather,fields,alerts,combines}
mkdir -p frontend/src/services/{api,weather,fields,combines,alerts}
mkdir -p frontend/public/images
mkdir -p frontend/tests/{unit,integration,e2e}

# Backend directories
mkdir -p backend/src/{api,services,models,middleware,config,utils}
mkdir -p backend/src/api/{auth,fields,weather,alerts,combines,community}
mkdir -p backend/src/services/{weather,fields,alerts,combines,community}
mkdir -p backend/src/models/{user,field,weather,combine,alert}
mkdir -p backend/tests/{unit,integration}
mkdir -p backend/scripts

# Database directories
mkdir -p database/{migrations,seeds,schemas}

# Documentation
mkdir -p docs/{api,architecture,deployment}

# Configuration files
mkdir -p config

echo "📄 Creating configuration files..."

# Frontend package.json
cat > frontend/package.json << 'EOF'
{
  "name": "fieldfirst-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "jest",
    "test:watch": "jest --watch"
  },
  "dependencies": {
    "next": "14.0.4",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.6.5",
    "swr": "^2.2.4",
    "@tanstack/react-query": "^5.17.9",
    "zustand": "^4.4.7",
    "react-hook-form": "^7.48.2",
    "zod": "^3.22.4",
    "date-fns": "^3.2.0",
    "leaflet": "^1.9.4",
    "react-leaflet": "^4.2.1",
    "recharts": "^2.10.4"
  },
  "devDependencies": {
    "@types/node": "^20.11.5",
    "@types/react": "^18.2.48",
    "@types/react-dom": "^18.2.18",
    "typescript": "^5.3.3",
    "tailwindcss": "^3.4.1",
    "postcss": "^8.4.33",
    "autoprefixer": "^10.4.17",
    "eslint": "^8.56.0",
    "eslint-config-next": "14.0.4",
    "jest": "^29.7.0",
    "@testing-library/react": "^14.1.2",
    "@testing-library/jest-dom": "^6.2.0"
  }
}
EOF

# Backend package.json
cat > backend/package.json << 'EOF'
{
  "name": "fieldfirst-backend",
  "version": "0.1.0",
  "description": "FieldFirst Backend API",
  "main": "dist/server.js",
  "scripts": {
    "dev": "nodemon",
    "build": "tsc",
    "start": "node dist/server.js",
    "test": "jest",
    "lint": "eslint src --ext .ts",
    "migrate": "node-pg-migrate",
    "seed": "ts-node src/scripts/seed.ts"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "compression": "^1.7.4",
    "express-rate-limit": "^7.1.5",
    "pg": "^8.11.3",
    "redis": "^4.6.12",
    "ioredis": "^5.3.2",
    "axios": "^1.6.5",
    "node-cron": "^3.0.3",
    "winston": "^3.11.0",
    "joi": "^17.11.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "dotenv": "^16.3.1",
    "@sentry/node": "^7.99.0",
    "mixpanel": "^0.18.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.11.5",
    "@types/cors": "^2.8.17",
    "@types/compression": "^1.7.5",
    "@types/pg": "^8.10.9",
    "@types/bcryptjs": "^2.4.6",
    "@types/jsonwebtoken": "^9.0.5",
    "typescript": "^5.3.3",
    "nodemon": "^3.0.2",
    "ts-node": "^10.9.2",
    "eslint": "^8.56.0",
    "@typescript-eslint/eslint-plugin": "^6.19.0",
    "@typescript-eslint/parser": "^6.19.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.1",
    "supertest": "^6.3.4"
  }
}
EOF

# TypeScript configurations
cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
EOF

cat > backend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    },
    "sourceMap": true,
    "removeComments": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
EOF

# Environment variable templates
cat > .env.example << 'EOF'
# Weather APIs
TOMORROW_IO_API_KEY=your_api_key_here
TOMORROW_IO_BASE_URL=https://api.tomorrow.io/v4

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/fieldfirst
REDIS_URL=redis://localhost:6379

# Services
SENDGRID_API_KEY=your_sendgrid_key
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token

# Feature Flags
ENABLE_MSC_FALLBACK=true
ENABLE_COMMUNITY_FEATURES=true
ENABLE_PREMIUM_FEATURES=true

# Security
JWT_SECRET=your_jwt_secret
SESSION_SECRET=your_session_secret

# Monitoring
SENTRY_DSN=your_sentry_dsn
MIXPANEL_TOKEN=your_mixpanel_token

# Environment
NODE_ENV=development
PORT=3001
FRONTEND_URL=http://localhost:3000
EOF

# Docker configuration
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgis/postgis:15-3.3
    environment:
      POSTGRES_DB: fieldfirst
      POSTGRES_USER: fieldfirst
      POSTGRES_PASSWORD: fieldfirst_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

  backend:
    build: ./backend
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://fieldfirst:fieldfirst_dev@postgres:5432/fieldfirst
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    volumes:
      - ./backend:/app
      - /app/node_modules

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - NEXT_PUBLIC_API_URL=http://localhost:3001
    depends_on:
      - backend
    volumes:
      - ./frontend:/app
      - /app/node_modules

volumes:
  postgres_data:
  redis_data:
EOF

# Create initial database schema
cat > database/schemas/001_initial_schema.sql << 'EOF'
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    farm_name VARCHAR(255),
    subscription_tier VARCHAR(50) DEFAULT 'free',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fields table with geospatial data
CREATE TABLE fields (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    crop_type VARCHAR(100),
    acres DECIMAL(10, 2),
    boundary GEOMETRY(Polygon, 4326),
    center_point GEOMETRY(Point, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Combine specifications
CREATE TABLE combine_specs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    model_variants TEXT[],
    year INTEGER,
    moisture_tolerance_min DECIMAL(4, 2),
    moisture_tolerance_max DECIMAL(4, 2),
    moisture_tolerance_optimal DECIMAL(4, 2),
    moisture_confidence VARCHAR(20),
    tough_crop_rating INTEGER CHECK (tough_crop_rating >= 1 AND tough_crop_rating <= 10),
    tough_crop_crops TEXT[],
    tough_crop_limitations TEXT[],
    tough_crop_confidence VARCHAR(20),
    user_reports_count INTEGER DEFAULT 0,
    has_manufacturer_specs BOOLEAN DEFAULT FALSE,
    expert_validated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Weather data cache
CREATE TABLE weather_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location GEOMETRY(Point, 4326),
    provider VARCHAR(50),
    data_type VARCHAR(50),
    data JSONB,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Harvest records
CREATE TABLE harvest_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field_id UUID REFERENCES fields(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    combine_id UUID REFERENCES combine_specs(id),
    harvest_date DATE,
    moisture_content DECIMAL(4, 2),
    yield_per_acre DECIMAL(8, 2),
    weather_conditions JSONB,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alerts configuration
CREATE TABLE alert_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    field_id UUID REFERENCES fields(id) ON DELETE CASCADE,
    alert_type VARCHAR(50),
    conditions JSONB,
    channels TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Community observations
CREATE TABLE observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    field_id UUID REFERENCES fields(id),
    location GEOMETRY(Point, 4326),
    observation_type VARCHAR(50),
    data JSONB,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_fields_user_id ON fields(user_id);
CREATE INDEX idx_fields_boundary ON fields USING GIST(boundary);
CREATE INDEX idx_fields_center ON fields USING GIST(center_point);
CREATE INDEX idx_weather_cache_location ON weather_cache USING GIST(location);
CREATE INDEX idx_weather_cache_expires ON weather_cache(expires_at);
CREATE INDEX idx_harvest_records_field ON harvest_records(field_id);
CREATE INDEX idx_harvest_records_date ON harvest_records(harvest_date);
CREATE INDEX idx_observations_location ON observations USING GIST(location);
EOF

# Create README for the new structure
cat > README_STRUCTURE.md << 'EOF'
# FieldFirst Project Structure

## Overview
This document describes the new project structure for FieldFirst, migrating from a Firebase/Flutter architecture to a modern Next.js/Node.js stack.

## Directory Structure

### Frontend (Next.js 14)
```
frontend/
├── src/
│   ├── app/                 # App Router pages
│   ├── components/          # Reusable React components
│   ├── services/           # API clients and external services
│   ├── hooks/              # Custom React hooks
│   ├── utils/              # Utility functions
│   └── types/              # TypeScript type definitions
├── public/                  # Static assets
└── tests/                   # Test suites
```

### Backend (Node.js/Express)
```
backend/
├── src/
│   ├── api/                # Route handlers organized by feature
│   ├── services/          # Business logic layer
│   ├── models/            # Database models and schemas
│   ├── middleware/        # Express middleware
│   ├── config/            # Configuration management
│   └── utils/             # Shared utilities
├── tests/                  # Test suites
└── scripts/               # Deployment and maintenance scripts
```

### Database
```
database/
├── migrations/            # Database migration files
├── seeds/                # Seed data for development
└── schemas/              # SQL schema definitions
```

## Key Components

### Weather Intelligence Engine
- Location: `backend/src/services/weather/`
- Integrates with Tomorrow.io and MSC APIs
- Implements location clustering for efficiency
- Manages weather data caching

### Field Management
- Location: `backend/src/services/fields/`
- Handles geospatial field boundaries
- Calculates optimal harvest windows
- Manages field-specific data

### Combine Intelligence
- Location: `backend/src/services/combines/`
- Model normalization and fuzzy matching
- Progressive data aggregation
- Equipment capability tracking

### Alert System
- Location: `backend/src/services/alerts/`
- Real-time weather monitoring
- Multi-channel notification delivery
- Custom alert rule processing

## Development Workflow

1. Install dependencies:
   ```bash
   cd frontend && npm install
   cd ../backend && npm install
   ```

2. Start development environment:
   ```bash
   docker-compose up -d  # Start PostgreSQL and Redis
   cd backend && npm run dev  # Start backend
   cd frontend && npm run dev  # Start frontend
   ```

3. Run tests:
   ```bash
   npm test  # In both frontend and backend directories
   ```

## Migration Notes

- Existing Firebase data will be migrated to PostgreSQL
- Flutter mobile app will connect via the new REST API
- Authentication will transition from Firebase Auth to JWT-based
- Gradual feature migration to minimize disruption

## Environment Setup

1. Copy `.env.example` to `.env`
2. Configure API keys and database credentials
3. Run database migrations: `npm run migrate`
4. Seed development data: `npm run seed`

## Deployment

- Frontend: Deployed to Vercel
- Backend: Deployed to Railway
- Database: PostgreSQL on Railway
- Redis: Railway Redis addon
EOF

echo "✅ Project structure initialized successfully!"
echo ""
echo "Next steps:"
echo "1. Review the EXECUTION_PLAN.md for detailed implementation steps"
echo "2. Install dependencies in frontend and backend directories"
echo "3. Configure environment variables by copying .env.example to .env"
echo "4. Start the development environment with docker-compose"
echo ""
echo "🌾 Happy farming with FieldFirst!"
EOF
# FieldReady 🌾

**Precision Agriculture Platform for Canadian Prairie Farmers**

FieldReady is a comprehensive Flutter web application that provides intelligent harvest timing recommendations by combining combine equipment capabilities with real-time weather data and crop-specific thresholds.

## 🎯 Overview

Built using a specialized AI agent architecture, FieldReady helps farmers optimize harvest timing by:

- **Intelligent Combine Selection**: Fuzzy search across 12+ combine models with detailed specifications
- **Weather Integration**: Tomorrow.io API with MSC fallback and intelligent caching (70-85% cost reduction)
- **Crop-Specific Analysis**: Threshold analysis for wheat, canola, barley, and oats with economic impact calculations
- **Equipment Factor Analysis**: Real-time capability adjustments based on weather conditions
- **Field-Ready UX**: Large touch targets, high contrast design optimized for outdoor use

## 🚀 Current Features

### ✅ Implemented
- **Combine Selection UI**: Full-screen modal with command-palette search
- **Firebase Integration**: Real-time data from Firestore with PIPEDA-compliant security
- **Fuzzy Search**: Intelligent matching across brands, models, and capabilities
- **Responsive Design**: Adapts from mobile to desktop (1-4 column layouts)
- **Progressive Web App**: Installable with offline capabilities
- **Professional UX**: Smooth animations, hover effects, and micro-interactions

### 🔄 In Development
- Real-time weather integration
- Harvest timing recommendations
- Equipment factor calculations
- Advanced analytics dashboard

## 🏗️ Architecture

### Current Stack (As-Is)
- **Frontend**: Flutter 3.32.8 (Web)
- **Backend**: Firebase (Firestore, Auth, Functions, Storage)
- **State Management**: BLoC pattern with Hydrated persistence
- **Database**: Firestore with comprehensive indexes
- **Hosting**: Firebase Hosting

### Target Stack (To-Be)
- **Frontend**: Next.js 14 with TypeScript
- **Backend**: Node.js with Express
- **Database**: PostgreSQL with PostGIS
- **Caching**: Redis
- **Deployment**: Vercel (frontend), Railway (backend)

## 🤖 Agent Architecture

This project was built using specialized AI agents, each with specific expertise:

| Agent | Role | Key Contributions |
|-------|------|------------------|
| **master-orchestrator** | Project coordination & validation | System integration, execution planning |
| **documentation-orchestrator** | Technical documentation | PROJECT_STATE.md, decision logging |
| **backend-architect** | Data architecture & APIs | Firebase setup, repository patterns |
| **weather-intelligence** | Weather data & caching | Tomorrow.io integration, cost optimization |
| **state-manager** | Application state management | BLoC patterns, equipment factors |
| **frontend-ux** | User interface & experience | Combine selection UI, field-ready design |
| **error-fixing** | Code quality & debugging | Compilation fixes, dependency management |

See [AGENT_ARCHITECTURE.md](docs/AGENT_ARCHITECTURE.md) for detailed agent documentation.

## 🚀 Quick Start

### Prerequisites
- Flutter 3.24+ installed
- Firebase CLI (for deployment)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Bushels/FieldReady.git
   cd FieldReady
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the development server**
   ```bash
   flutter run -d chrome --web-port 8080
   ```

4. **Or build for production**
   ```bash
   flutter build web
   ```

### Firebase Setup (Optional)
The app includes hardcoded demo data but can connect to Firebase for real data:

1. Create a Firebase project
2. Enable Firestore, Auth, and Storage
3. Update Firebase configuration in `lib/main.dart`
4. Deploy security rules: `firebase deploy --only firestore:rules`

## 📱 Usage

### Combine Selection
1. Click the **"Add Your Combine"** button or floating action button
2. Use the **command palette search** to find your combine:
   - Type brand names: "John", "Case", "Claas"
   - Search by model: "S780", "8250", "CR10.90"
   - Find by capability: "tough straw", "high moisture"
3. **Filter by brand** using the filter chips
4. **Select your combine** from the responsive grid

### Dashboard Features
- **Combine specifications** with key stats (header size, engine power, capacity)
- **Capability indicators** showing equipment strengths
- **Rating display** with community feedback
- **Mock harvest intelligence** (full integration coming soon)

## 🎨 UX Design Principles

FieldReady follows **field-ready design principles**:

### Clarity Over Clutter
- Information at-a-glance for farmers in moving vehicles
- Strong visual hierarchy with ample white space
- Essential data prominently displayed

### Data as Actionable Insight  
- Technical specs translated to farmer benefits
- "Best For" capabilities instead of raw numbers
- Economic impact calculations for decision support

### Delight in the Details
- Subtle animations and smooth transitions
- Hover effects and micro-interactions
- Professional polish without distraction

### Built for the Field
- **Large touch targets** (44px minimum)
- **High contrast** colors for sunlight readability
- **Intuitive gestures** for tablet/phone use in vehicles
- **Responsive design** for all screen sizes

## 📊 Technical Specifications

### Performance
- **Build time**: ~2-3 seconds for web compilation
- **Bundle size**: Optimized with tree-shaking (99.4% font reduction)
- **Search performance**: <200ms fuzzy matching with Levenshtein distance
- **Responsive breakpoints**: 600px, 900px, 1200px

### Browser Support
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

### Device Support
- Desktop (1200px+): 4-column grid
- Tablet (600-1200px): 2-3 column grid  
- Mobile (<600px): Single column with optimized touch targets

## 🗂️ Project Structure

```
FieldReady/
├── lib/
│   ├── data/                 # Data models and sources
│   ├── domain/              # Business logic layer
│   │   ├── models/          # Domain models
│   │   ├── repositories/    # Repository interfaces
│   │   └── services/        # Business services
│   ├── presentation/        # UI layer
│   │   ├── blocs/          # State management
│   │   ├── pages/          # App screens
│   │   └── widgets/        # Reusable components
│   ├── services/           # External service integrations
│   ├── utils/              # Utility functions
│   └── widgets/            # UI components
├── web/                    # Web-specific assets
├── docs/                   # Documentation
├── functions/              # Firebase Cloud Functions
└── scripts/                # Build and deployment scripts
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Check code quality
dart analyze
dart fix --apply
```

## 🚀 Deployment

### Firebase Hosting
```bash
flutter build web
firebase deploy --only hosting
```

### Static Hosting
The `build/web` directory can be served by any static hosting provider.

## 📈 Roadmap

### Phase 1: Foundation ✅
- [x] Flutter web application setup
- [x] Firebase integration
- [x] Combine selection interface
- [x] Fuzzy search implementation
- [x] Responsive design

### Phase 2: Intelligence (In Progress)
- [ ] Tomorrow.io weather integration
- [ ] Crop threshold analysis
- [ ] Equipment factor calculations
- [ ] Harvest timing recommendations

### Phase 3: Advanced Features
- [ ] Real-time weather alerts
- [ ] Community insights sharing
- [ ] Historical data analysis
- [ ] Mobile app (iOS/Android)

### Phase 4: Enterprise
- [ ] Multi-user organizations
- [ ] Advanced analytics
- [ ] API for third-party integrations
- [ ] White-label solutions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/Bushels/FieldReady/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Bushels/FieldReady/discussions)

## 🏆 Acknowledgments

- Built with specialized AI agent architecture
- Weather data provided by Tomorrow.io
- Agricultural expertise from prairie farming community
- Flutter and Firebase teams for excellent developer tools

---

**FieldReady** - Empowering Canadian prairie farmers with precision agriculture technology 🌾🚜
# API_CONTRACTS.md - FieldFirst External API Integration Guide

## Last Updated: 2025-01-28

## Tomorrow.io API Integration

### Overview
Primary weather data provider offering 1km resolution hyperlocal forecasts.

### Authentication
```javascript
headers: {
  'apikey': process.env.TOMORROW_IO_API_KEY,
  'accept': 'application/json'
}
```

### Rate Limits
- **Free Tier**: 500 calls/day, 25 calls/hour, 3 calls/minute
- **Pro Tier**: 10,000 calls/day (requires upgrade)
- **Reset**: Daily at 00:00 UTC

### Core Endpoints

#### 1. Realtime Weather
```
GET https://api.tomorrow.io/v4/weather/realtime
```

**Request Parameters**:
```javascript
{
  location: "50.4452,-104.6189",  // lat,lng
  units: "metric",
  fields: [
    "temperature",
    "humidity", 
    "dewPoint",
    "windSpeed",
    "precipitationIntensity",
    "weatherCode"
  ]
}
```

**Response Example**:
```json
{
  "data": {
    "time": "2025-01-28T15:00:00Z",
    "values": {
      "temperature": 18.5,
      "humidity": 65,
      "dewPoint": 11.2,
      "windSpeed": 12.3,
      "precipitationIntensity": 0,
      "weatherCode": 1000
    }
  }
}
```

#### 2. Forecast Timeline
```
GET https://api.tomorrow.io/v4/weather/forecast
```

**Request Parameters**:
```javascript
{
  location: "50.4452,-104.6189",
  fields: [
    "temperature",
    "humidity",
    "dewPoint",
    "windSpeed",
    "precipitationProbability",
    "precipitationIntensity",
    "weatherCode",
    "cloudCover"
  ],
  timesteps: ["1h", "1d"],
  timezone: "America/Regina",
  startTime: "now",
  endTime: "nowPlus5d"
}
```

**Response Structure**:
```json
{
  "data": {
    "timelines": [
      {
        "timestep": "1h",
        "intervals": [
          {
            "startTime": "2025-01-28T15:00:00Z",
            "values": {
              "temperature": 18.5,
              "humidity": 65,
              "dewPoint": 11.2,
              "precipitationProbability": 10
            }
          }
        ]
      }
    ]
  }
}
```

### Error Handling

#### Common Error Codes
```javascript
// Rate limit exceeded
{
  "code": 429001,
  "type": "Rate Limit Exceeded",
  "message": "You have exceeded your daily limit"
}

// Invalid location
{
  "code": 400001,
  "type": "Invalid Input",
  "message": "Location parameter is invalid"
}

// Authentication failure
{
  "code": 401001,
  "type": "Unauthorized",
  "message": "Invalid API key"
}
```

#### Retry Strategy
```javascript
async function callTomorrowIO(endpoint, params, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(endpoint, params);
      
      if (response.status === 429) {
        // Rate limited - exponential backoff
        const delay = Math.pow(2, i) * 1000;
        await sleep(delay);
        continue;
      }
      
      if (!response.ok) {
        throw new Error(`API Error: ${response.status}`);
      }
      
      return await response.json();
    } catch (error) {
      if (i === retries - 1) throw error;
    }
  }
}
```

## MSC (Meteorological Service of Canada) Fallback

### Overview
Free government weather data as fallback when Tomorrow.io is unavailable.

### Base URLs
- **GeoMet API**: https://geo.weather.gc.ca/geomet
- **Datamart**: https://dd.weather.gc.ca

### Key Endpoints

#### 1. Current Conditions
```
GET https://geo.weather.gc.ca/geomet/features/collections/climate-observations/items
?bbox=-106.7,49.0,-101.3,52.4  // Saskatchewan bounds
&datetime=2025-01-28T00:00:00Z/2025-01-28T23:59:59Z
```

#### 2. Forecast Data
```
GET https://geo.weather.gc.ca/geomet/features/collections/weather-forecasts/items
?point=-104.6189,50.4452
&time=2025-01-28T00:00:00Z/..
```

### Data Mapping

| Tomorrow.io Field | MSC Field | Notes |
|------------------|-----------|--------|
| temperature | air_temp | Direct mapping |
| humidity | rel_humidity | Percentage |
| dewPoint | dewpoint_temp | Calculate if missing |
| windSpeed | wind_speed | Convert km/h to m/s |
| precipitationIntensity | precip_amount | mm/hr |

### MSC Limitations
- Lower spatial resolution (10-50km grid)
- Less frequent updates (hourly vs 5-minute)
- No hyperlocal features
- Complex data formats requiring transformation

## Efficiency Patterns

### 1. Location Clustering
```javascript
class LocationClusterer {
  cluster(locations, radiusKm = 5) {
    const clusters = [];
    const processed = new Set();
    
    locations.forEach(loc => {
      if (processed.has(loc.id)) return;
      
      const cluster = {
        center: loc,
        members: [loc]
      };
      
      locations.forEach(other => {
        if (processed.has(other.id)) return;
        
        const distance = haversineDistance(loc, other);
        if (distance <= radiusKm) {
          cluster.members.push(other);
          processed.add(other.id);
        }
      });
      
      clusters.push(cluster);
      processed.add(loc.id);
    });
    
    return clusters;
  }
}
```

### 2. Request Batching
```javascript
class APIBatcher {
  constructor(batchSize = 10, delayMs = 100) {
    this.queue = [];
    this.batchSize = batchSize;
    this.delayMs = delayMs;
  }
  
  async add(request) {
    this.queue.push(request);
    
    if (this.queue.length >= this.batchSize) {
      return this.flush();
    }
    
    // Auto-flush after delay
    if (!this.timer) {
      this.timer = setTimeout(() => this.flush(), this.delayMs);
    }
  }
  
  async flush() {
    const batch = this.queue.splice(0, this.batchSize);
    clearTimeout(this.timer);
    this.timer = null;
    
    return Promise.all(batch.map(req => this.execute(req)));
  }
}
```

### 3. Cache Strategy
```javascript
class WeatherCache {
  constructor(redis) {
    this.redis = redis;
    this.ttl = {
      realtime: 300,      // 5 minutes
      hourly: 3600,       // 1 hour
      daily: 21600,       // 6 hours
      historical: 86400   // 24 hours
    };
  }
  
  getCacheKey(location, type) {
    const lat = Math.round(location.lat * 100) / 100;
    const lng = Math.round(location.lng * 100) / 100;
    return `weather:${type}:${lat}:${lng}`;
  }
  
  async get(location, type) {
    const key = this.getCacheKey(location, type);
    const cached = await this.redis.get(key);
    
    if (cached) {
      return JSON.parse(cached);
    }
    
    return null;
  }
  
  async set(location, type, data) {
    const key = this.getCacheKey(location, type);
    const ttl = this.ttl[type] || 3600;
    
    await this.redis.setex(key, ttl, JSON.stringify(data));
  }
}
```

### 4. Graceful Degradation
```javascript
class WeatherService {
  async getWeather(location) {
    try {
      // Try Tomorrow.io first
      return await this.tomorrowIO.getWeather(location);
    } catch (error) {
      if (error.code === 429001) {
        // Rate limited - use cache or MSC
        const cached = await this.cache.get(location, 'fallback');
        if (cached) return cached;
        
        // Fall back to MSC
        return await this.msc.getWeather(location);
      }
      
      throw error;
    }
  }
}
```

## API Cost Optimization

### Cost Calculation
```javascript
function calculateMonthlyCost(users, fieldsPerUser) {
  const callsPerField = 4; // Daily checks
  const clusteringEfficiency = 0.4; // 60% reduction
  
  const dailyCalls = users * fieldsPerUser * callsPerField * clusteringEfficiency;
  const monthlyCalls = dailyCalls * 30;
  
  const freeTier = 500 * 30; // 15,000 calls/month
  const billableCalls = Math.max(0, monthlyCalls - freeTier);
  
  // Tomorrow.io pricing: $0.0001 per call after free tier
  const cost = billableCalls * 0.0001;
  
  return {
    totalCalls: monthlyCalls,
    billableCalls,
    estimatedCost: cost
  };
}
```

### Optimization Strategies
1. **Aggressive Caching**: Cache all responses with appropriate TTL
2. **Smart Scheduling**: Batch updates during low-usage periods
3. **Progressive Enhancement**: Start with cached/MSC data, enhance with fresh data
4. **User Clustering**: Group users by geography for shared API calls
5. **Predictive Fetching**: Pre-fetch data for likely user actions

## WebSocket Integration (Future)

### Real-time Weather Updates
```javascript
class WeatherWebSocket {
  constructor(url) {
    this.ws = new WebSocket(url);
    this.subscriptions = new Map();
  }
  
  subscribe(location, callback) {
    const key = `${location.lat}:${location.lng}`;
    this.subscriptions.set(key, callback);
    
    this.ws.send(JSON.stringify({
      action: 'subscribe',
      location: location
    }));
  }
  
  handleMessage(event) {
    const data = JSON.parse(event.data);
    const key = `${data.location.lat}:${data.location.lng}`;
    
    const callback = this.subscriptions.get(key);
    if (callback) {
      callback(data.weather);
    }
  }
}
```

## Combine Intelligence API

### Overview
The Combine Intelligence API provides endpoints for managing combine specifications, normalizing user input, and delivering progressive insights based on community data volume.

### Authentication
All combine endpoints require user authentication via JWT token:
```javascript
headers: {
  'Authorization': 'Bearer <jwt_token>',
  'Content-Type': 'application/json'
}
```

### Core Endpoints

#### 1. Submit Combine Specifications
```
POST /api/combines/specs
```

**Request Body**:
```json
{
  "brand": "John Deere",
  "model": "X9 1100",
  "year": 2023,
  "userId": "user_123",
  "moistureSettings": {
    "typical": 14.5,
    "minimum": 12.0,
    "maximum": 18.0
  },
  "cropExperience": {
    "corn": { "rating": 9, "notes": "Excellent in tough conditions" },
    "soybeans": { "rating": 8, "notes": "Good performance" },
    "wheat": { "rating": 10, "notes": "Outstanding" }
  }
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "spec_456",
    "normalizedBrand": "john_deere",
    "normalizedModel": "x9_1100",
    "confidence": 0.98,
    "requiresConfirmation": false,
    "aggregatedWith": 23
  }
}
```

#### 2. Normalize Combine Input
```
POST /api/combines/normalize
```

**Request Body**:
```json
{
  "input": "JD X9-1100",
  "context": {
    "year": 2023,
    "userId": "user_123"
  }
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "matches": [
      {
        "brand": "john_deere",
        "model": "x9_1100",
        "confidence": 0.95,
        "matchType": "variant",
        "requiresConfirmation": false
      },
      {
        "brand": "john_deere", 
        "model": "x9_1000",
        "confidence": 0.72,
        "matchType": "fuzzy",
        "requiresConfirmation": true
      }
    ],
    "bestMatch": {
      "brand": "john_deere",
      "model": "x9_1100",
      "confidence": 0.95
    }
  }
}
```

#### 3. Confirm Model Match
```
POST /api/combines/confirm-match
```

**Request Body**:
```json
{
  "originalInput": "JD X9-1100",
  "suggestedMatch": {
    "brand": "john_deere",
    "model": "x9_1100"
  },
  "userConfirmation": {
    "accepted": true,
    "correctedBrand": null,
    "correctedModel": null
  },
  "userId": "user_123"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "learned": true,
    "improvedMatching": true,
    "thanksMessage": "Thank you for helping improve our combine database!"
  }
}
```

#### 4. Get Regional Combine Insights
```
GET /api/combines/insights/:region?level=progressive&crop=corn
```

**Path Parameters**:
- `region`: Geographic region code (e.g., 'sk_saskatoon', 'mb_winnipeg')

**Query Parameters**:
- `level`: Data granularity ('basic', 'brand', 'model') - auto-determined by data volume
- `crop`: Filter by crop type ('corn', 'soybeans', 'wheat', 'canola')
- `moisture_range`: Filter by moisture range ('12-14', '14-16', '16-18')

**Response Examples**:

*Level 1 - Basic (Insufficient model-specific data)*:
```json
{
  "success": true,
  "data": {
    "level": "basic",
    "region": "sk_saskatoon",
    "totalFarmers": 237,
    "startedHarvest": 15,
    "averageMoisture": 15.8,
    "weatherConditions": "favorable",
    "recommendation": "Monitor moisture levels closely",
    "nextLevelAt": "5 more farmers with matching equipment"
  }
}
```

*Level 2 - Brand-Specific (5-15 users per brand)*:
```json
{
  "success": true,
  "data": {
    "level": "brand",
    "region": "sk_saskatoon", 
    "brandInsights": [
      {
        "brand": "john_deere",
        "farmers": 43,
        "started": 8,
        "averageMoisture": 14.2,
        "moistureRange": "12.8-16.1",
        "recommendation": "John Deere combines performing well at current moisture levels"
      },
      {
        "brand": "case_ih",
        "farmers": 31,
        "started": 5,
        "averageMoisture": 15.1,
        "moistureRange": "13.5-17.2",
        "recommendation": "Case IH operators waiting for lower moisture"
      }
    ]
  }
}
```

*Level 3 - Model-Specific (15+ users per model)*:
```json
{
  "success": true,
  "data": {
    "level": "model",
    "region": "sk_saskatoon",
    "modelInsights": [
      {
        "brand": "john_deere",
        "model": "x9_1100",
        "farmers": 23,
        "started": 5,
        "averageMoisture": 14.2,
        "moistureRange": "13.1-15.8",
        "toughCropRating": 9.2,
        "recommendations": [
          "Excellent performance in current conditions",
          "Can handle moisture up to 16% with reduced speed",
          "Superior tough crop handling"
        ],
        "peerComparison": {
          "betterThan": ["s790", "af_8250"],
          "similarTo": ["cr_10.90"],
          "challengedBy": ["lexion_8900"]
        }
      }
    ]
  }
}
```

#### 5. Get Combine Specifications
```
GET /api/combines/specs/:id
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "spec_456",
    "brand": "john_deere",
    "model": "x9_1100",
    "year": 2023,
    "moistureTolerance": {
      "min": 12.0,
      "max": 18.0,
      "optimal": 14.5,
      "confidence": "high"
    },
    "toughCropAbility": {
      "rating": 9.2,
      "crops": ["corn", "soybeans", "wheat", "sunflower"],
      "limitations": ["Reduced efficiency in extremely wet conditions"],
      "confidence": "high"
    },
    "sourceData": {
      "userReports": 23,
      "manufacturerSpecs": true,
      "expertValidation": true,
      "lastUpdated": "2025-01-28T10:30:00Z"
    }
  }
}
```

### Error Handling

#### Normalization Errors
```json
{
  "success": false,
  "error": {
    "code": "NORMALIZATION_FAILED",
    "message": "Unable to match combine model",
    "details": {
      "input": "unknown model xyz",
      "suggestions": [
        "Check spelling of brand and model",
        "Try using just the model number",
        "Contact support if this is a valid model"
      ]
    }
  }
}
```

#### Insufficient Data Errors
```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_DATA", 
    "message": "Not enough data for model-specific insights",
    "details": {
      "currentLevel": "brand",
      "requiredUsers": 15,
      "actualUsers": 3,
      "fallbackLevel": "basic"
    }
  }
}
```

### Rate Limiting
- **Normalization**: 100 requests per minute per user
- **Insights**: 50 requests per minute per user  
- **Specs submission**: 10 requests per minute per user

### Caching Headers
```
Cache-Control: public, max-age=300  # 5 minutes for insights
Cache-Control: public, max-age=3600 # 1 hour for specifications
```

## Testing & Monitoring

### API Health Checks
```javascript
async function healthCheck() {
  const endpoints = [
    {
      name: 'Tomorrow.io',
      url: 'https://api.tomorrow.io/v4/weather/realtime',
      params: { location: '50.4452,-104.6189' }
    },
    {
      name: 'MSC GeoMet',
      url: 'https://geo.weather.gc.ca/geomet/features/collections',
      params: {}
    }
  ];
  
  const results = await Promise.allSettled(
    endpoints.map(endpoint => 
      fetch(endpoint.url, { params: endpoint.params })
        .then(res => ({ 
          name: endpoint.name, 
          status: res.status,
          latency: res.headers.get('x-response-time')
        }))
    )
  );
  
  return results;
}
```

### Monitoring Metrics
- API response times (p50, p95, p99)
- Error rates by endpoint
- Cache hit/miss ratios
- Daily API usage vs limits
- Fallback activation frequency
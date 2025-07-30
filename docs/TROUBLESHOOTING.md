# TROUBLESHOOTING.md - FieldFirst Common Issues & Solutions

## Last Updated: 2025-01-28

## Quick Reference
- [API Rate Limiting](#api-rate-limiting)
- [Weather Data Issues](#weather-data-issues)
- [Database Problems](#database-problems)
- [Authentication Errors](#authentication-errors)
- [Performance Issues](#performance-issues)
- [Mobile App Problems](#mobile-app-problems)
- [Alert Delivery Failures](#alert-delivery-failures)
- [Combine Intelligence Issues](#combine-intelligence-issues)

---

## API Rate Limiting

### Issue: Tomorrow.io 429 Error - Rate Limit Exceeded
**Symptoms**:
- Error code 429001
- Message: "You have exceeded your daily limit"
- Weather data stops updating

**Root Cause**:
- Exceeded 500 daily API calls on free tier
- Burst limit of 3 calls/minute exceeded
- Multiple users in same geographic area

**Solution**:
```javascript
// Implement exponential backoff
async function retryWithBackoff(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (error.status === 429 && i < maxRetries - 1) {
        const delay = Math.pow(2, i) * 1000 + Math.random() * 1000;
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      throw error;
    }
  }
}

// Check rate limit headers
const remaining = response.headers.get('X-RateLimit-Remaining');
const reset = response.headers.get('X-RateLimit-Reset');
```

**Prevention**:
1. Enable location clustering (5km radius)
2. Implement request queuing
3. Use Redis to track API usage
4. Set up MSC fallback

**Code Changes**:
- `src/services/weather/RateLimiter.ts` - Add rate limit tracking
- `src/services/weather/TomorrowIOClient.ts` - Add retry logic

---

## Weather Data Issues

### Issue: Missing Dew Point Data
**Symptoms**:
- Dew point shows as null or undefined
- Harvest window calculations fail
- Alert thresholds not triggered

**Root Cause**:
- Tomorrow.io doesn't always return dew point
- MSC uses different field names
- Calculation fallback not implemented

**Solution**:
```javascript
// Calculate dew point from temperature and humidity
function calculateDewPoint(temp, humidity) {
  const a = 17.271;
  const b = 237.7;
  const gamma = (a * temp / (b + temp)) + Math.log(humidity / 100);
  return (b * gamma) / (a - gamma);
}

// Weather data normalizer
function normalizeWeatherData(data, source) {
  if (source === 'tomorrow.io') {
    return {
      temperature: data.values.temperature,
      humidity: data.values.humidity,
      dewPoint: data.values.dewPoint || calculateDewPoint(
        data.values.temperature,
        data.values.humidity
      )
    };
  } else if (source === 'msc') {
    return {
      temperature: data.air_temp,
      humidity: data.rel_humidity,
      dewPoint: data.dewpoint_temp || calculateDewPoint(
        data.air_temp,
        data.rel_humidity
      )
    };
  }
}
```

**Prevention**:
1. Always calculate missing values
2. Validate data completeness
3. Log missing fields for monitoring

---

### Issue: Inconsistent Location Data
**Symptoms**:
- Weather data for wrong location
- Fields appear to move on map
- Duplicate API calls for same location

**Root Cause**:
- Floating point precision issues
- Coordinate format inconsistencies
- Missing coordinate validation

**Solution**:
```javascript
// Standardize coordinates
function normalizeCoordinates(lat, lng) {
  return {
    lat: Math.round(lat * 10000) / 10000,  // 4 decimal places
    lng: Math.round(lng * 10000) / 10000
  };
}

// Validate coordinate bounds for Canadian prairies
function validateCoordinates(lat, lng) {
  const bounds = {
    north: 60.0,
    south: 49.0,
    east: -95.0,
    west: -115.0
  };
  
  if (lat < bounds.south || lat > bounds.north) {
    throw new Error(`Latitude ${lat} outside service area`);
  }
  
  if (lng < bounds.west || lng > bounds.east) {
    throw new Error(`Longitude ${lng} outside service area`);
  }
}
```

---

## Database Problems

### Issue: PostGIS Extension Not Found
**Symptoms**:
- Error: "function ST_DWithin does not exist"
- Field boundary queries fail
- Location clustering doesn't work

**Root Cause**:
- PostGIS extension not installed
- Wrong database permissions
- Extension in wrong schema

**Solution**:
```sql
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Verify installation
SELECT PostGIS_Version();

-- Grant permissions
GRANT USAGE ON SCHEMA public TO fieldfirst_user;
GRANT CREATE ON SCHEMA public TO fieldfirst_user;
```

**Prevention**:
1. Add to database migration files
2. Check extensions in health endpoint
3. Document in setup instructions

---

### Issue: Connection Pool Exhausted
**Symptoms**:
- "too many connections" error
- Slow API responses
- Random timeouts

**Root Cause**:
- No connection pooling configured
- Connections not released
- Database connection leaks

**Solution**:
```javascript
// Configure connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                    // Maximum connections
  idleTimeoutMillis: 30000,   // Close idle connections
  connectionTimeoutMillis: 2000,
});

// Always release connections
async function queryDatabase(sql, params) {
  const client = await pool.connect();
  try {
    return await client.query(sql, params);
  } finally {
    client.release();
  }
}

// Monitor pool health
setInterval(() => {
  console.log({
    total: pool.totalCount,
    idle: pool.idleCount,
    waiting: pool.waitingCount
  });
}, 60000);
```

---

## Authentication Errors

### Issue: JWT Token Expired During Long Session
**Symptoms**:
- User logged out unexpectedly
- 401 errors after period of activity
- "Invalid token" messages

**Root Cause**:
- Token expiry not handled
- No refresh token mechanism
- Clock skew between servers

**Solution**:
```javascript
// Implement token refresh
class AuthService {
  async refreshToken(oldToken) {
    const decoded = jwt.decode(oldToken);
    
    // Check if token is about to expire (5 min buffer)
    const expiresIn = decoded.exp * 1000 - Date.now();
    if (expiresIn > 300000) return oldToken;
    
    // Issue new token
    const user = await User.findById(decoded.userId);
    return this.generateToken(user);
  }
  
  // Auto-refresh middleware
  async autoRefresh(req, res, next) {
    if (req.headers.authorization) {
      const token = req.headers.authorization.split(' ')[1];
      const newToken = await this.refreshToken(token);
      
      if (newToken !== token) {
        res.setHeader('X-New-Token', newToken);
      }
    }
    next();
  }
}
```

---

## Performance Issues

### Issue: Slow Field List Loading
**Symptoms**:
- Field list takes >3 seconds to load
- Database queries timing out
- High memory usage

**Root Cause**:
- Missing database indexes
- Loading all field data at once
- No pagination implemented

**Solution**:
```sql
-- Add missing indexes
CREATE INDEX idx_fields_user_id ON fields(user_id);
CREATE INDEX idx_fields_created_at ON fields(created_at DESC);
CREATE INDEX idx_field_boundaries_geom ON field_boundaries USING GIST(geometry);

-- Optimize field query
WITH user_fields AS (
  SELECT 
    f.id, 
    f.name, 
    f.crop_type,
    ST_AsGeoJSON(fb.geometry) as boundary,
    COUNT(o.id) as observation_count
  FROM fields f
  LEFT JOIN field_boundaries fb ON f.id = fb.field_id
  LEFT JOIN observations o ON f.id = o.field_id
  WHERE f.user_id = $1
  GROUP BY f.id, fb.geometry
  ORDER BY f.created_at DESC
  LIMIT 20 OFFSET $2
)
SELECT * FROM user_fields;
```

**Prevention**:
1. Run EXPLAIN ANALYZE on slow queries
2. Implement query result caching
3. Add database monitoring

---

### Issue: Weather Map Rendering Lag
**Symptoms**:
- Map tiles load slowly
- Browser becomes unresponsive
- High CPU usage

**Root Cause**:
- Rendering too many markers
- No marker clustering
- Large GeoJSON polygons

**Solution**:
```javascript
// Implement marker clustering
import MarkerClusterer from '@googlemaps/markerclusterer';

const clusterer = new MarkerClusterer({
  map,
  markers,
  algorithm: new SuperClusterAlgorithm({
    radius: 100,
    maxZoom: 14
  })
});

// Simplify polygons for display
function simplifyPolygon(geojson, tolerance = 0.0001) {
  const simplified = turf.simplify(geojson, {
    tolerance: tolerance,
    highQuality: true
  });
  return simplified;
}

// Implement viewport culling
function getVisibleFields(fields, bounds) {
  return fields.filter(field => {
    const point = turf.point([field.lng, field.lat]);
    return turf.booleanPointInPolygon(point, bounds);
  });
}
```

---

## Mobile App Problems

### Issue: Location Services Not Working
**Symptoms**:
- "Location access denied" error
- GPS coordinates show 0,0
- Auto-detect location fails

**Root Cause**:
- Missing permissions
- HTTPS not enabled
- Browser security restrictions

**Solution**:
```javascript
// Comprehensive location handler
async function getCurrentLocation() {
  // Check if geolocation is supported
  if (!navigator.geolocation) {
    throw new Error('Geolocation not supported');
  }
  
  // Check permissions
  const permission = await navigator.permissions.query({ 
    name: 'geolocation' 
  });
  
  if (permission.state === 'denied') {
    throw new Error('Location access denied. Please enable in settings.');
  }
  
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(
      position => resolve({
        lat: position.coords.latitude,
        lng: position.coords.longitude,
        accuracy: position.coords.accuracy
      }),
      error => {
        switch(error.code) {
          case error.PERMISSION_DENIED:
            reject(new Error('Location permission denied'));
            break;
          case error.POSITION_UNAVAILABLE:
            reject(new Error('Location unavailable'));
            break;
          case error.TIMEOUT:
            reject(new Error('Location request timed out'));
            break;
        }
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    );
  });
}
```

---

## Alert Delivery Failures

### Issue: SMS Alerts Not Received
**Symptoms**:
- Email alerts work but SMS don't
- Twilio webhook errors
- "Invalid phone number" errors

**Root Cause**:
- Phone number format issues
- Twilio account restrictions
- Carrier filtering

**Solution**:
```javascript
// Phone number validation and formatting
const phoneUtil = require('google-libphonenumber').PhoneNumberUtil.getInstance();

function formatPhoneNumber(number, countryCode = 'CA') {
  try {
    const parsed = phoneUtil.parse(number, countryCode);
    
    if (!phoneUtil.isValidNumber(parsed)) {
      throw new Error('Invalid phone number');
    }
    
    // Format for Twilio (E.164)
    return phoneUtil.format(parsed, 
      PhoneNumberFormat.E164
    );
  } catch (error) {
    throw new Error(`Phone validation failed: ${error.message}`);
  }
}

// Implement SMS retry with fallback
async function sendAlert(user, message) {
  const methods = [
    { type: 'sms', send: sendSMS },
    { type: 'email', send: sendEmail },
    { type: 'push', send: sendPush }
  ];
  
  for (const method of methods) {
    if (user.preferences[method.type]) {
      try {
        await method.send(user, message);
        return { success: true, method: method.type };
      } catch (error) {
        console.error(`${method.type} failed:`, error);
        continue;
      }
    }
  }
  
  throw new Error('All delivery methods failed');
}
```

---

## Common Configuration Errors

### Issue: Environment Variables Not Loading
**Symptoms**:
- "API key is undefined" errors
- Database connection fails
- Services not starting

**Root Cause**:
- .env file in wrong location
- dotenv not configured
- Variable name mismatches

**Solution**:
```javascript
// Validate required environment variables
const required = [
  'DATABASE_URL',
  'TOMORROW_IO_API_KEY',
  'JWT_SECRET',
  'REDIS_URL'
];

function validateEnv() {
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    throw new Error(
      `Missing environment variables: ${missing.join(', ')}\n` +
      'Please check your .env file'
    );
  }
}

// Load with error handling
require('dotenv').config({ 
  path: path.resolve(__dirname, '.env') 
});

validateEnv();
```

---

## Debugging Tools & Commands

### Database Queries
```bash
# Check slow queries
psql $DATABASE_URL -c "
  SELECT query, calls, mean_exec_time 
  FROM pg_stat_statements 
  ORDER BY mean_exec_time DESC 
  LIMIT 10;"

# Monitor connections
psql $DATABASE_URL -c "
  SELECT count(*) as connections, 
         state 
  FROM pg_stat_activity 
  GROUP BY state;"
```

### API Monitoring
```bash
# Test Tomorrow.io endpoint
curl -X GET "https://api.tomorrow.io/v4/weather/realtime" \
  -H "apikey: $TOMORROW_IO_API_KEY" \
  -G --data-urlencode "location=50.4452,-104.6189" \
  -w "\nTime: %{time_total}s\n"

# Check rate limit headers
curl -I "https://api.tomorrow.io/v4/weather/realtime" \
  -H "apikey: $TOMORROW_IO_API_KEY" \
  -G --data-urlencode "location=50.4452,-104.6189" | \
  grep -i "ratelimit"
```

### Cache Debugging
```bash
# Redis connection test
redis-cli ping

# Check cache keys
redis-cli keys "weather:*"

# Monitor cache operations
redis-cli monitor
```

---

## Emergency Procedures

### Complete API Failure
1. Enable MSC fallback immediately
2. Increase cache TTL to 24 hours
3. Notify users of degraded accuracy
4. Monitor Tomorrow.io status page

### Database Outage
1. Switch to read-only mode
2. Serve cached data only
3. Queue write operations
4. Implement data reconciliation

### High Traffic Event
1. Enable Cloudflare DDoS protection
2. Increase cache aggressiveness
3. Disable non-essential features
4. Scale read replicas

---

## Combine Intelligence Issues

### Issue: Combine Model Not Recognized
**Symptoms**:
- "Unable to match combine model" error
- User input returns no suggestions
- Confidence scores consistently below 0.6

**Root Cause**:
- New or uncommon combine model not in database
- User input has excessive typos or formatting issues
- Brand aliases not configured

**Solution**:
```javascript
// Add unknown model to learning database
async function handleUnknownModel(userInput, userId) {
  // Log for manual review
  await logUnknownModel({
    input: userInput,
    userId: userId,
    timestamp: new Date(),
    needsReview: true
  });
  
  // Provide fallback suggestions
  const suggestions = await getFallbackSuggestions(userInput);
  
  return {
    success: false,
    error: 'MODEL_NOT_RECOGNIZED',
    suggestions: suggestions,
    supportContact: 'help@fieldfirst.ca'
  };
}

// Update model variants database
async function addModelVariant(canonical, newVariant) {
  await db.query(`
    INSERT INTO model_variants (variant, canonical_brand, canonical_model, source)
    VALUES ($1, $2, $3, 'manual')
    ON CONFLICT (variant, canonical_brand) DO NOTHING
  `, [newVariant, canonical.brand, canonical.model]);
}
```

**Prevention**:
1. Regular review of unknown model logs
2. User feedback collection for missed models
3. Integration with manufacturer databases
4. Community crowdsourcing of model variants

---

### Issue: Low Confidence Model Matches
**Symptoms**:
- Confidence scores between 0.6-0.8
- Frequent user confirmation requests
- Users rejecting suggested matches

**Root Cause**:
- Fuzzy matching algorithm too aggressive
- Insufficient training data for specific models
- Brand aliases incomplete

**Solution**:
```javascript
// Improve confidence scoring
class ImprovedConfidenceCalculator {
  calculateConfidence(factors) {
    // Weight manufacturer validation higher
    if (factors.manufacturerValidated) {
      factors.baseConfidence += 0.2;
    }
    
    // Penalize very different lengths
    const lengthDiff = Math.abs(factors.inputLength - factors.canonicalLength);
    if (lengthDiff > 5) {
      factors.baseConfidence -= 0.1;
    }
    
    // Boost confidence for common patterns
    if (this.hasCommonPattern(factors.input)) {
      factors.baseConfidence += 0.1;
    }
    
    return Math.min(Math.max(factors.baseConfidence, 0), 1);
  }
  
  hasCommonPattern(input) {
    const patterns = [
      /^[a-z]+\s*\d+$/i,    // Brand + numbers
      /^[a-z]\d+$/i,        // Single letter + numbers
      /^\d+[a-z]?$/i        // Numbers + optional letter
    ];
    
    return patterns.some(pattern => pattern.test(input.trim()));
  }
}
```

**Prevention**:
1. Regular confidence threshold tuning
2. A/B testing of matching algorithms
3. User feedback loop improvements
4. Expanded training dataset

---

### Issue: Data Aggregation Problems with Insufficient Users
**Symptoms**:
- "Insufficient data" errors in insights API
- UI shows basic level when users expect detailed insights
- Inconsistent data aggregation levels

**Root Cause**:
- Not enough users per combine model in region
- Geographic clustering too restrictive
- Data threshold too high for rural areas

**Solution**:
```javascript
// Implement fallback aggregation strategy
class FlexibleAggregator {
  async getInsights(region, combineFilter) {
    let insights = await this.getModelSpecificInsights(region, combineFilter);
    
    if (insights.userCount < 5) {
      // Fall back to brand level
      insights = await this.getBrandInsights(region, combineFilter);
      
      if (insights.userCount < 10) {
        // Fall back to regional level
        insights = await this.getRegionalInsights(region);
        
        if (insights.userCount < 20) {
          // Fall back to provincial level
          insights = await this.getProvincialInsights(region);
        }
      }
    }
    
    // Always indicate data limitations
    insights.dataLimitations = this.getDataLimitations(insights);
    
    return insights;
  }
  
  getDataLimitations(insights) {
    const limitations = [];
    
    if (insights.userCount < 5) {
      limitations.push('Limited local data - insights may be less accurate');
    }
    
    if (insights.level !== 'model') {
      limitations.push(`Showing ${insights.level}-level data - more farmers needed for model-specific insights`);
    }
    
    return limitations;
  }
}
```

**Prevention**:
1. Adjust thresholds based on rural vs urban areas
2. Expand geographic clustering radius when needed
3. Implement predictive modeling for sparse data
4. Encourage user participation through incentives

---

### Issue: Brand Normalization Failures
**Symptoms**:
- Common brands not recognized (JD, Case, etc.)
- Inconsistent brand naming in database
- Duplicate entries for same brand

**Root Cause**:
- Incomplete brand aliases mapping
- Case sensitivity issues
- Regional spelling variations

**Solution**:
```javascript
// Comprehensive brand normalization
class BrandNormalizer {
  constructor() {
    this.aliases = new Map([
      // John Deere variants
      ['jd', 'john_deere'],
      ['j.d.', 'john_deere'],
      ['johndeere', 'john_deere'],
      ['john-deere', 'john_deere'],
      ['deere', 'john_deere'],
      
      // Case IH variants  
      ['caseih', 'case_ih'],
      ['case-ih', 'case_ih'],
      ['case ih', 'case_ih'],
      ['cnh', 'case_ih'],
      ['international', 'case_ih'],
      
      // Add regional variations
      ['jean-deere', 'john_deere'], // French
      ['yan-deere', 'john_deere']   // Common mispronunciation
    ]);
  }
  
  normalize(input) {
    const cleaned = input.toLowerCase()
      .replace(/[^\w\s]/g, ' ')  // Replace punctuation with spaces
      .replace(/\s+/g, ' ')      // Normalize whitespace
      .trim();
    
    // Check exact matches first
    if (this.aliases.has(cleaned)) {
      return {
        canonical: this.aliases.get(cleaned),
        confidence: 1.0,
        method: 'exact_alias'
      };
    }
    
    // Try fuzzy matching
    return this.fuzzyMatch(cleaned);
  }
  
  fuzzyMatch(input) {
    let bestMatch = { canonical: input, confidence: 0.5, method: 'no_match' };
    
    for (const [alias, canonical] of this.aliases) {
      const distance = this.levenshteinDistance(input, alias);
      const maxLen = Math.max(input.length, alias.length);
      const confidence = 1 - (distance / maxLen);
      
      if (confidence > bestMatch.confidence && confidence > 0.7) {
        bestMatch = { canonical, confidence, method: 'fuzzy_alias' };
      }
    }
    
    return bestMatch;
  }
}
```

**Prevention**:
1. Regular audit of brand normalization accuracy
2. Community feedback on brand recognition
3. Integration with industry databases
4. Automated detection of new brand variants

---

### Issue: User Confirmation Flow Breaking
**Symptoms**:
- Users stuck on combine confirmation screen
- Confirmation never completes
- Database not updated after confirmation

**Root Cause**:
- Race conditions in confirmation API
- Frontend state management issues
- Database transaction failures

**Solution**:
```javascript
// Robust confirmation handling
class ConfirmationHandler {
  async handleConfirmation(confirmationId, userResponse) {
    const transaction = await this.db.beginTransaction();
    
    try {
      // Lock the confirmation record
      const confirmation = await this.db.query(`
        SELECT * FROM combine_confirmations 
        WHERE id = $1 AND status = 'pending'
        FOR UPDATE
      `, [confirmationId]);
      
      if (!confirmation.rows[0]) {
        throw new Error('Confirmation already processed or not found');
      }
      
      // Update confirmation status
      await this.db.query(`
        UPDATE combine_confirmations 
        SET status = 'completed', 
            user_response = $2,
            completed_at = NOW()
        WHERE id = $1
      `, [confirmationId, userResponse]);
      
      // Learn from the response
      if (!userResponse.accepted) {
        await this.learnFromCorrection(confirmation.rows[0], userResponse);
      }
      
      // Update user's combine specs
      await this.updateUserCombineSpecs(confirmation.rows[0], userResponse);
      
      await transaction.commit();
      
      return { success: true, learned: true };
      
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }
  
  // Prevent confirmation timeout
  async extendConfirmationTimeout(confirmationId) {
    await this.db.query(`
      UPDATE combine_confirmations 
      SET expires_at = NOW() + INTERVAL '30 minutes'
      WHERE id = $1 AND status = 'pending'
    `, [confirmationId]);
  }
}
```

**Prevention**:
1. Implement confirmation timeouts with extensions
2. Add database constraints to prevent duplicates
3. Use optimistic locking for race condition prevention
4. Add comprehensive error handling and logging

---

### Issue: Performance Degradation with Large Model Database
**Symptoms**:
- Slow combine model matching (>2 seconds)
- Database queries timing out
- High CPU usage during normalization

**Root Cause**:
- Full table scans on model variants
- Missing database indexes
- Inefficient fuzzy matching algorithm

**Solution**:
```sql
-- Add performance indexes
CREATE INDEX CONCURRENTLY idx_model_variants_fuzzy 
  ON model_variants USING gin(variant gin_trgm_ops);

CREATE INDEX CONCURRENTLY idx_combine_specs_search
  ON combine_specs USING gin((brand || ' ' || model) gin_trgm_ops);

-- Optimize variant lookup
CREATE MATERIALIZED VIEW mv_model_lookup AS
SELECT 
  variant,
  canonical_brand,
  canonical_model,
  confidence,
  similarity(variant, $1) as sim_score
FROM model_variants
WHERE similarity(variant, $1) > 0.3
ORDER BY sim_score DESC
LIMIT 10;

-- Refresh periodically
CREATE INDEX ON mv_model_lookup (sim_score DESC);
```

```javascript
// Implement caching layer
class CachedModelMatcher {
  constructor() {
    this.cache = new LRUCache({ max: 1000, ttl: 1000 * 60 * 60 }); // 1 hour
  }
  
  async findMatch(input) {
    const cacheKey = this.normalizeInput(input);
    
    // Check cache first
    const cached = this.cache.get(cacheKey);
    if (cached) {
      return { ...cached, fromCache: true };
    }
    
    // Perform expensive matching
    const result = await this.expensiveMatch(input);
    
    // Cache successful matches
    if (result.confidence > 0.8) {
      this.cache.set(cacheKey, result);
    }
    
    return result;
  }
}
```

**Prevention**:
1. Regular database maintenance and reindexing
2. Query performance monitoring
3. Implement progressive loading for large datasets
4. Use connection pooling and query optimization

---

## Monitoring Checklist

### Daily Checks
- [ ] API usage vs limits
- [ ] Error rate trends
- [ ] Cache hit ratios
- [ ] Database connection count
- [ ] Alert delivery success rate
- [ ] Combine model match success rate
- [ ] User confirmation response rate
- [ ] Unknown model entries requiring review

### Weekly Reviews
- [ ] Performance metrics (p95 latency)
- [ ] User-reported issues
- [ ] Cost optimization opportunities
- [ ] Security alerts
- [ ] Dependency updates
- [ ] Combine database accuracy audit
- [ ] Brand normalization effectiveness
- [ ] Regional data coverage analysis
- [ ] User feedback on combine matching
# Firebase Authentication Setup for FieldReady

## Overview

This document outlines the Firebase Authentication configuration for the FieldReady agricultural combine intelligence system. The authentication system is designed with privacy compliance (PIPEDA) in mind and supports multiple authentication methods.

## Authentication Methods

### 1. Email/Password Authentication
- **Primary method** for most users
- Includes email verification
- Password reset functionality
- Account recovery options

### 2. Google Sign-In
- **Recommended** for ease of use
- OAuth 2.0 integration
- Automatic profile information import
- Seamless cross-device experience

### 3. Phone Authentication (Optional)
- SMS-based verification
- Useful for rural users with limited internet
- Backup authentication method
- Regional phone number support

## Configuration Steps

### 1. Firebase Console Setup

1. **Navigate to Authentication in Firebase Console**
   - Go to https://console.firebase.google.com
   - Select your FieldReady project
   - Click on "Authentication" in the left sidebar

2. **Configure Sign-in Methods**
   ```
   Email/Password: ✅ Enabled
   - Email link (passwordless): Optional
   - Email verification: ✅ Required
   
   Google: ✅ Enabled
   - Web SDK configuration: Auto-configured
   - Support email: your-support@email.com
   
   Phone: ⚠️ Optional (for rural connectivity backup)
   - Test phone numbers: Configure for development
   ```

3. **Set Up Authorized Domains**
   ```
   Production: your-domain.com
   Development: localhost
   Staging: staging.your-domain.com
   ```

### 2. Security Rules Integration

The authentication system integrates with our Firestore security rules:

```javascript
// Helper function in firestore.rules
function isAuthenticated() {
  return request.auth != null;
}

function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}

function isAdmin() {
  return isAuthenticated() && 
         request.auth.token.admin == true;
}
```

### 3. Custom Claims for Admin Users

Admin users require custom claims for elevated permissions:

```javascript
// Cloud Function to set admin claims
exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  // Verify current user is already an admin
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can grant admin privileges'
    );
  }

  await admin.auth().setCustomUserClaims(data.userId, {
    admin: true
  });

  return { success: true };
});
```

## User Data Model

### User Profile Structure

```typescript
interface UserProfile {
  uid: string;                    // Firebase Auth UID
  email: string;                  // Primary email address
  displayName?: string;           // User's display name
  farmName?: string;             // Name of their farming operation
  region?: string;               // Geographic region for insights
  phoneNumber?: string;          // Optional phone for SMS alerts
  profilePicture?: string;       // Profile image URL
  preferences: {
    units: 'metric' | 'imperial'; // Measurement preferences
    notifications: {
      email: boolean;             // Email notifications enabled
      push: boolean;              // Push notifications enabled
      sms: boolean;               // SMS notifications enabled
    };
    privacy: {
      shareData: boolean;         // Allow data in community insights
      shareLocation: boolean;     // Share regional information
      marketingEmails: boolean;   // Marketing communication consent
    };
  };
  subscription: {
    tier: 'free' | 'premium';     // Subscription level
    expiresAt?: Date;             // Premium expiration
  };
  createdAt: Date;
  updatedAt: Date;
  lastLoginAt?: Date;
}
```

### Privacy Compliance (PIPEDA)

1. **Data Minimization**
   - Only collect necessary user information
   - Optional fields clearly marked
   - Purpose-specific data collection

2. **Consent Management**
   - Explicit consent for data sharing
   - Granular privacy controls
   - Easy consent withdrawal

3. **Data Retention**
   - Automatic account deletion after inactivity
   - User-initiated data export
   - Secure data deletion processes

## Frontend Integration

### React/Next.js Setup

```typescript
// firebase/config.ts
import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator } from 'firebase/auth';

const firebaseConfig = {
  // Your Firebase configuration
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

// Connect to emulator in development
if (process.env.NODE_ENV === 'development') {
  connectAuthEmulator(auth, 'http://localhost:9099');
}
```

### Authentication Hook

```typescript
// hooks/useAuth.ts
import { useAuthState } from 'react-firebase-hooks/auth';
import { auth } from '../firebase/config';

export const useAuth = () => {
  const [user, loading, error] = useAuthState(auth);
  
  return {
    user,
    loading,
    error,
    isAuthenticated: !!user,
    isAdmin: user?.getIdTokenResult()?.claims?.admin || false
  };
};
```

## Flutter Integration

### Firebase Auth Setup

```dart
// lib/services/auth_service.dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword(
    String email, 
    String password
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }
  
  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = 
        await googleUser?.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    
    return await _auth.signInWithCredential(credential);
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
```

## Security Best Practices

### 1. Password Requirements
- Minimum 8 characters
- Mix of uppercase, lowercase, numbers
- Optional special characters
- Password strength indicator

### 2. Email Verification
- Required for all new accounts
- Automated verification emails
- Clear verification instructions
- Resend verification option

### 3. Account Recovery
- Secure password reset flow
- Multiple verification methods
- Account lockout protection
- Suspicious activity monitoring

### 4. Session Management
- Automatic token refresh
- Session timeout configuration
- Multi-device session handling
- Secure logout on all devices

## Testing Configuration

### Development Setup

```bash
# Start Firebase Auth emulator
firebase emulators:start --only auth

# Configure test users
firebase auth:import test-users.json --project your-project-id
```

### Test User Data

```json
{
  "users": [
    {
      "localId": "test-admin-uid",
      "email": "admin@test.com",
      "emailVerified": true,
      "displayName": "Test Admin",
      "customAttributes": "{\"admin\":true}"
    },
    {
      "localId": "test-user-uid", 
      "email": "user@test.com",
      "emailVerified": true,
      "displayName": "Test User"
    }
  ]
}
```

## Monitoring and Analytics

### 1. Authentication Metrics
- Sign-up conversion rates
- Login success/failure rates
- Password reset frequency
- Multi-factor adoption

### 2. Security Monitoring
- Failed login attempts
- Suspicious login patterns
- Account takeover attempts
- Geographic anomalies

### 3. User Engagement
- Session duration
- Feature usage by auth method
- Retention by registration method
- Churn analysis

## Deployment Checklist

### Production Readiness

- [ ] Email/password authentication configured
- [ ] Google Sign-In properly set up with production keys
- [ ] Custom domains authorized
- [ ] Email templates customized with branding
- [ ] SMTP provider configured for emails
- [ ] Rate limiting configured
- [ ] Admin claims setup process documented
- [ ] Privacy policy and terms of service linked
- [ ] PIPEDA compliance audit completed
- [ ] Multi-factor authentication configured (if required)
- [ ] Account deletion process tested
- [ ] Data export functionality verified

### Security Validation

- [ ] Security rules tested with authenticated users
- [ ] Custom claims properly validated
- [ ] Session management working correctly
- [ ] Password reset flow tested
- [ ] Email verification required and working
- [ ] Account lockout protection enabled
- [ ] Monitoring and alerting configured

## Support and Troubleshooting

### Common Issues

1. **Email Verification Not Sent**
   - Check SMTP configuration
   - Verify authorized sender domain
   - Check spam folders
   - Verify email template configuration

2. **Google Sign-In Fails**
   - Verify OAuth 2.0 client configuration
   - Check authorized domains
   - Verify API keys and secrets
   - Test with different browsers

3. **Custom Claims Not Working**
   - Verify claims are set correctly
   - Check token refresh timing
   - Validate security rules syntax
   - Test with Firebase emulator

### Debug Commands

```bash
# Check Firebase configuration
firebase projects:list

# Test authentication locally
firebase emulators:start --only auth

# Validate security rules
firebase firestore:rules:test --local

# Check user authentication status
firebase auth:export --project your-project-id
```

## Next Steps

1. **Configure your Firebase project** with the authentication methods above
2. **Test the authentication flow** using the Firebase emulator
3. **Implement the frontend integration** based on your chosen framework
4. **Set up monitoring and analytics** for authentication metrics
5. **Complete security testing** before production deployment

For implementation support, refer to the main project documentation or contact the development team.
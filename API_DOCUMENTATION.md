# MeasureBowl API Documentation

## Overview

The MeasureBowl API provides endpoints for managing lawn bowls measurements, tournaments, and user settings. The API follows RESTful principles and uses JSON for data exchange.

## Base URL

```
https://api.measurebowl.com
```

## Authentication

The API uses JWT tokens for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

For sensitive endpoints, an API key is also required:

```
x-api-key: <your-api-key>
```

## Rate Limiting

- **Limit**: 100 requests per 15 minutes per IP
- **Headers**: Rate limit information is included in response headers
- **Exceeded**: Returns 429 status code with retry-after information

## Error Handling

All errors follow a consistent format:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": "Additional error details (optional)"
}
```

## Endpoints

### Measurements

#### Create Measurement

**POST** `/api/measurements`

Creates a new measurement with bowl data.

**Headers:**
- `Authorization: Bearer <token>` (optional)
- `x-api-key: <api-key>` (required)

**Request Body:**
```json
{
  "imageData": "base64_encoded_image_data",
  "jackPosition": "{\"x\": 100, \"y\": 150, \"radius\": 25}",
  "bowlCount": 2,
  "bowls": [
    {
      "color": "red",
      "position": "{\"x\": 120, \"y\": 160, \"radius\": 30}",
      "distanceFromJack": 15.5,
      "rank": 1
    }
  ]
}
```

**Response:**
```json
{
  "measurement": {
    "id": "uuid",
    "timestamp": "2024-01-15T10:30:00Z",
    "imageData": "base64_encoded_image_data",
    "jackPosition": "{\"x\": 100, \"y\": 150, \"radius\": 25}",
    "bowlCount": 2,
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  },
  "bowls": [
    {
      "id": "uuid",
      "measurementId": "uuid",
      "color": "red",
      "position": "{\"x\": 120, \"y\": 160, \"radius\": 30}",
      "distanceFromJack": 15.5,
      "rank": 1,
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Validation Rules:**
- `imageData`: Required, base64 encoded image
- `jackPosition`: Required, valid JSON string with x, y, radius
- `bowlCount`: Required, non-negative integer
- `bowls`: Optional array of bowl objects

#### Get All Measurements

**GET** `/api/measurements`

Retrieves all measurements for the authenticated user.

**Headers:**
- `Authorization: Bearer <token>` (optional)

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10, max: 100)
- `sort`: Sort order - `asc` or `desc` (default: desc)
- `sortBy`: Sort field (default: createdAt)

**Response:**
```json
[
  {
    "id": "uuid",
    "timestamp": "2024-01-15T10:30:00Z",
    "imageData": "base64_encoded_image_data",
    "jackPosition": "{\"x\": 100, \"y\": 150, \"radius\": 25}",
    "bowlCount": 2,
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  }
]
```

#### Get Measurement by ID

**GET** `/api/measurements/:id`

Retrieves a specific measurement with its bowl data.

**Headers:**
- `Authorization: Bearer <token>` (optional)

**Path Parameters:**
- `id`: Measurement UUID

**Response:**
```json
{
  "measurement": {
    "id": "uuid",
    "timestamp": "2024-01-15T10:30:00Z",
    "imageData": "base64_encoded_image_data",
    "jackPosition": "{\"x\": 100, \"y\": 150, \"radius\": 25}",
    "bowlCount": 2,
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  },
  "bowls": [
    {
      "id": "uuid",
      "measurementId": "uuid",
      "color": "red",
      "position": "{\"x\": 120, \"y\": 160, \"radius\": 30}",
      "distanceFromJack": 15.5,
      "rank": 1,
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

#### Get Bowls for Measurement

**GET** `/api/measurements/:id/bowls`

Retrieves bowl data for a specific measurement.

**Headers:**
- `Authorization: Bearer <token>` (optional)

**Path Parameters:**
- `id`: Measurement UUID

**Response:**
```json
[
  {
    "id": "uuid",
    "measurementId": "uuid",
    "color": "red",
    "position": "{\"x\": 120, \"y\": 160, \"radius\": 30}",
    "distanceFromJack": 15.5,
    "rank": 1,
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  }
]
```

### Tournaments

#### Get Tournaments

**GET** `/api/tournaments`

Retrieves list of available tournaments.

**Response:**
```json
[
  {
    "id": "1",
    "name": "Spring Championship",
    "description": "Annual spring tournament for all skill levels",
    "startDate": "2024-03-15T09:00:00Z",
    "endDate": "2024-03-17T17:00:00Z",
    "location": "Central Lawn Bowls Club",
    "maxParticipants": 32,
    "currentParticipants": 18,
    "status": "upcoming",
    "category": "singles",
    "entryFee": 25
  }
]
```

### Settings

#### Get User Settings

**GET** `/api/settings`

Retrieves user settings (requires authentication).

**Headers:**
- `Authorization: Bearer <token>` (required)
- `x-api-key: <api-key>` (required)

**Response:**
```json
{
  "id": "user-1",
  "user": {
    "name": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890"
  },
  "notifications": {
    "email": true,
    "push": true,
    "measurementReminders": false,
    "tournamentUpdates": true
  },
  "measurement": {
    "defaultUnit": "cm",
    "autoSave": true,
    "highAccuracy": false,
    "showGrid": true
  },
  "privacy": {
    "shareData": false,
    "analytics": true,
    "locationServices": false
  }
}
```

#### Update User Settings

**PUT** `/api/settings`

Updates user settings (requires authentication).

**Headers:**
- `Authorization: Bearer <token>` (required)
- `x-api-key: <api-key>` (required)

**Request Body:**
```json
{
  "notifications": {
    "email": false,
    "push": true
  },
  "measurement": {
    "defaultUnit": "mm",
    "highAccuracy": true
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Settings updated successfully",
  "settings": {
    // Updated settings object
  }
}
```

#### Reset Settings

**POST** `/api/settings/reset`

Resets user settings to defaults (requires authentication).

**Headers:**
- `Authorization: Bearer <token>` (required)
- `x-api-key: <api-key>` (required)

**Response:**
```json
{
  "success": true,
  "message": "Settings reset to defaults",
  "settings": {
    // Default settings object
  }
}
```

## Error Codes

| Code | Description |
|------|-------------|
| `MISSING_TOKEN` | Authorization token is required |
| `INVALID_TOKEN` | Authorization token is invalid or expired |
| `NOT_AUTHENTICATED` | User is not authenticated |
| `INSUFFICIENT_PERMISSIONS` | User lacks required permissions |
| `MISSING_API_KEY` | API key is required |
| `INVALID_API_KEY` | API key is invalid |
| `VALIDATION_ERROR` | Request data validation failed |
| `RATE_LIMIT_EXCEEDED` | Rate limit exceeded |
| `INVALID_INPUT` | Potentially malicious input detected |
| `XSS_DETECTED` | Cross-site scripting attempt detected |

## Security Features

### Input Validation
- All input is sanitized to prevent XSS attacks
- SQL injection prevention
- File upload validation
- Request size limits

### Authentication
- JWT token-based authentication
- API key validation for sensitive endpoints
- Rate limiting to prevent abuse

### CORS
- Cross-origin requests are properly handled
- Security headers are included in responses

## SDKs and Libraries

### JavaScript/TypeScript
```bash
npm install @measurebowl/api-client
```

```typescript
import { MeasureBowlAPI } from '@measurebowl/api-client';

const api = new MeasureBowlAPI({
  baseURL: 'https://api.measurebowl.com',
  apiKey: 'your-api-key'
});

// Create measurement
const measurement = await api.measurements.create({
  imageData: 'base64data',
  jackPosition: '{"x": 100, "y": 150, "radius": 25}',
  bowlCount: 2,
  bowls: [...]
});
```

### Flutter/Dart
```yaml
dependencies:
  measurebowl_api: ^1.0.0
```

```dart
import 'package:measurebowl_api/measurebowl_api.dart';

final api = MeasureBowlAPI(
  baseURL: 'https://api.measurebowl.com',
  apiKey: 'your-api-key',
);

// Create measurement
final measurement = await api.measurements.create(
  MeasurementRequest(
    imageData: 'base64data',
    jackPosition: '{"x": 100, "y": 150, "radius": 25}',
    bowlCount: 2,
    bowls: [...],
  ),
);
```

## Support

For API support, please contact:
- Email: api-support@measurebowl.com
- Documentation: https://docs.measurebowl.com
- Status Page: https://status.measurebowl.com

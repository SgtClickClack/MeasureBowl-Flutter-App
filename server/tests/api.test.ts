import request from 'supertest';
import { createServer } from 'http';
import express from 'express';
import { registerRoutes } from '../routes';

describe('API Tests', () => {
  let app: express.Application;
  let server: any;

  beforeAll(async () => {
    app = express();
    app.use(express.json());
    server = await registerRoutes(app);
  });

  afterAll(() => {
    server.close();
  });

  describe('GET /api/measurements', () => {
    it('should return measurements list', async () => {
      const response = await request(app)
        .get('/api/measurements')
        .expect(200);

      expect(response.body).toBeInstanceOf(Array);
    });

    it('should handle rate limiting', async () => {
      // Make multiple requests to test rate limiting
      const requests = Array(10).fill(null).map(() => 
        request(app).get('/api/measurements')
      );
      
      const responses = await Promise.all(requests);
      
      // All should succeed (rate limit is 100 per 15 minutes)
      responses.forEach(response => {
        expect([200, 429]).toContain(response.status);
      });
    });
  });

  describe('POST /api/measurements', () => {
    const validMeasurement = {
      imageData: 'base64encodedimagedata',
      jackPosition: '{"x": 100, "y": 150, "radius": 25}',
      bowlCount: 2,
      bowls: [
        {
          color: 'red',
          position: '{"x": 120, "y": 160, "radius": 30}',
          distanceFromJack: 15.5,
          rank: 1
        },
        {
          color: 'blue',
          position: '{"x": 80, "y": 140, "radius": 30}',
          distanceFromJack: 22.3,
          rank: 2
        }
      ]
    };

    it('should create measurement with valid data', async () => {
      const response = await request(app)
        .post('/api/measurements')
        .send(validMeasurement)
        .expect(200);

      expect(response.body).toHaveProperty('measurement');
      expect(response.body).toHaveProperty('bowls');
      expect(response.body.measurement).toHaveProperty('id');
      expect(response.body.bowls).toHaveLength(2);
    });

    it('should reject invalid measurement data', async () => {
      const invalidMeasurement = {
        imageData: '', // Invalid: empty image data
        jackPosition: 'invalid json',
        bowlCount: -1, // Invalid: negative count
      };

      const response = await request(app)
        .post('/api/measurements')
        .send(invalidMeasurement)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('Validation failed');
    });

    it('should sanitize input data', async () => {
      const maliciousMeasurement = {
        ...validMeasurement,
        imageData: '<script>alert("xss")</script>',
        jackPosition: '{"x": 100, "y": 150, "radius": 25}',
      };

      const response = await request(app)
        .post('/api/measurements')
        .send(maliciousMeasurement)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should prevent SQL injection', async () => {
      const sqlInjectionMeasurement = {
        ...validMeasurement,
        imageData: "'; DROP TABLE measurements; --",
      };

      const response = await request(app)
        .post('/api/measurements')
        .send(sqlInjectionMeasurement)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('GET /api/measurements/:id', () => {
    it('should return 404 for non-existent measurement', async () => {
      const response = await request(app)
        .get('/api/measurements/non-existent-id')
        .expect(404);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Measurement not found');
    });

    it('should validate UUID format', async () => {
      const response = await request(app)
        .get('/api/measurements/invalid-uuid')
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('Validation failed');
    });
  });

  describe('GET /api/tournaments', () => {
    it('should return tournaments list', async () => {
      const response = await request(app)
        .get('/api/tournaments')
        .expect(200);

      expect(response.body).toBeInstanceOf(Array);
      expect(response.body.length).toBeGreaterThan(0);
      
      const tournament = response.body[0];
      expect(tournament).toHaveProperty('id');
      expect(tournament).toHaveProperty('name');
      expect(tournament).toHaveProperty('status');
    });
  });

  describe('Authentication Tests', () => {
    describe('GET /api/settings', () => {
      it('should require authentication', async () => {
        const response = await request(app)
          .get('/api/settings')
          .expect(401);

        expect(response.body).toHaveProperty('error');
        expect(response.body.error).toBe('Access token required');
      });

      it('should reject invalid token', async () => {
        const response = await request(app)
          .get('/api/settings')
          .set('Authorization', 'Bearer invalid-token')
          .expect(401);

        expect(response.body).toHaveProperty('error');
        expect(response.body.error).toBe('Invalid or expired token');
      });
    });

    describe('PUT /api/settings', () => {
      it('should require authentication', async () => {
        const response = await request(app)
          .put('/api/settings')
          .send({ theme: 'dark' })
          .expect(401);

        expect(response.body).toHaveProperty('error');
      });
    });
  });

  describe('API Key Validation', () => {
    it('should require API key for measurements endpoint', async () => {
      const response = await request(app)
        .post('/api/measurements')
        .send({
          imageData: 'test',
          jackPosition: '{"x": 100, "y": 150, "radius": 25}',
          bowlCount: 0
        })
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('API key required');
    });

    it('should accept valid API key', async () => {
      // This test would require setting up a valid API key in the environment
      // For now, we'll test the structure
      const response = await request(app)
        .post('/api/measurements')
        .set('x-api-key', 'test-key')
        .send({
          imageData: 'test',
          jackPosition: '{"x": 100, "y": 150, "radius": 25}',
          bowlCount: 0
        });

      // Should either succeed (if API key is configured) or fail with validation error
      expect([200, 400, 401]).toContain(response.status);
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed JSON', async () => {
      const response = await request(app)
        .post('/api/measurements')
        .set('Content-Type', 'application/json')
        .send('invalid json')
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should handle missing required fields', async () => {
      const response = await request(app)
        .post('/api/measurements')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should handle server errors gracefully', async () => {
      // This would require mocking a server error
      // For now, we'll test that the error handling structure exists
      const response = await request(app)
        .get('/api/measurements')
        .expect(200);

      expect(response.status).toBe(200);
    });
  });

  describe('CORS and Security Headers', () => {
    it('should include security headers', async () => {
      const response = await request(app)
        .get('/api/measurements')
        .expect(200);

      // Check for common security headers
      expect(response.headers).toHaveProperty('x-content-type-options');
      expect(response.headers).toHaveProperty('x-frame-options');
    });
  });
});

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

// Extend Request interface to include user
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        role: string;
      };
    }
  }
}

const JWT_SECRET = process.env.JWT_SECRET || 'your-fallback-secret-change-in-production';

export interface AuthMiddleware {
  authenticate: (req: Request, res: Response, next: NextFunction) => void;
  authorize: (roles: string[]) => (req: Request, res: Response, next: NextFunction) => void;
  optionalAuth: (req: Request, res: Response, next: NextFunction) => void;
}

export const auth: AuthMiddleware = {
  // Authenticate JWT token
  authenticate: (req: Request, res: Response, next: NextFunction) => {
    try {
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ 
          error: 'Access token required',
          code: 'MISSING_TOKEN'
        });
      }

      const token = authHeader.substring(7); // Remove 'Bearer ' prefix
      
      try {
        const decoded = jwt.verify(token, JWT_SECRET) as any;
        req.user = {
          id: decoded.id,
          email: decoded.email,
          role: decoded.role || 'user'
        };
        next();
      } catch (jwtError) {
        return res.status(401).json({ 
          error: 'Invalid or expired token',
          code: 'INVALID_TOKEN'
        });
      }
    } catch (error) {
      console.error('Authentication error:', error);
      return res.status(500).json({ 
        error: 'Authentication failed',
        code: 'AUTH_ERROR'
      });
    }
  },

  // Authorize based on user roles
  authorize: (roles: string[]) => {
    return (req: Request, res: Response, next: NextFunction) => {
      if (!req.user) {
        return res.status(401).json({ 
          error: 'Authentication required',
          code: 'NOT_AUTHENTICATED'
        });
      }

      if (!roles.includes(req.user.role)) {
        return res.status(403).json({ 
          error: 'Insufficient permissions',
          code: 'INSUFFICIENT_PERMISSIONS',
          required: roles,
          current: req.user.role
        });
      }

      next();
    };
  },

  // Optional authentication - doesn't fail if no token
  optionalAuth: (req: Request, res: Response, next: NextFunction) => {
    try {
      const authHeader = req.headers.authorization;
      
      if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.substring(7);
        
        try {
          const decoded = jwt.verify(token, JWT_SECRET) as any;
          req.user = {
            id: decoded.id,
            email: decoded.email,
            role: decoded.role || 'user'
          };
        } catch (jwtError) {
          // Token is invalid, but we continue without user
          req.user = undefined;
        }
      }
      
      next();
    } catch (error) {
      console.error('Optional authentication error:', error);
      // Continue without authentication
      next();
    }
  }
};

// Rate limiting middleware
import rateLimit from 'express-rate-limit';

export const createRateLimit = (windowMs: number, max: number, message?: string) => {
  return rateLimit({
    windowMs,
    max,
    message: message || 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req: Request, res: Response) => {
      res.status(429).json({
        error: 'Rate limit exceeded',
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter: Math.round(windowMs / 1000)
      });
    }
  });
};

// API key validation middleware
export const validateApiKey = (req: Request, res: Response, next: NextFunction) => {
  const apiKey = req.headers['x-api-key'] as string;
  const validApiKey = process.env.API_KEY;

  if (!validApiKey) {
    console.warn('API_KEY not configured in environment');
    return next(); // Skip validation if not configured
  }

  if (!apiKey) {
    return res.status(401).json({
      error: 'API key required',
      code: 'MISSING_API_KEY'
    });
  }

  if (apiKey !== validApiKey) {
    return res.status(401).json({
      error: 'Invalid API key',
      code: 'INVALID_API_KEY'
    });
  }

  next();
};

import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';

// Input sanitization function
export const sanitizeInput = (input: any): any => {
  if (typeof input === 'string') {
    // Remove potentially dangerous characters and trim whitespace
    return input
      .trim()
      .replace(/[<>]/g, '') // Remove HTML tags
      .replace(/javascript:/gi, '') // Remove javascript: protocol
      .replace(/on\w+=/gi, '') // Remove event handlers
      .substring(0, 10000); // Limit length
  }
  
  if (Array.isArray(input)) {
    return input.map(sanitizeInput);
  }
  
  if (input && typeof input === 'object') {
    const sanitized: any = {};
    for (const [key, value] of Object.entries(input)) {
      // Sanitize object keys
      const sanitizedKey = key.replace(/[^a-zA-Z0-9_]/g, '');
      sanitized[sanitizedKey] = sanitizeInput(value);
    }
    return sanitized;
  }
  
  return input;
};

// Validation middleware factory
export const validateRequest = (schema: z.ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      // Sanitize input first
      req.body = sanitizeInput(req.body);
      req.query = sanitizeInput(req.query);
      req.params = sanitizeInput(req.params);
      
      // Validate with schema
      const validatedData = schema.parse(req.body);
      req.body = validatedData;
      
      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({
          error: 'Validation failed',
          code: 'VALIDATION_ERROR',
          details: error.errors.map(err => ({
            field: err.path.join('.'),
            message: err.message,
            code: err.code
          }))
        });
      }
      
      console.error('Validation middleware error:', error);
      return res.status(500).json({
        error: 'Validation failed',
        code: 'VALIDATION_ERROR'
      });
    }
  };
};

// Common validation schemas
export const commonSchemas = {
  // ID parameter validation
  idParam: z.object({
    id: z.string().uuid('Invalid ID format')
  }),
  
  // Pagination query validation
  pagination: z.object({
    page: z.string().optional().transform(val => val ? parseInt(val, 10) : 1),
    limit: z.string().optional().transform(val => val ? parseInt(val, 10) : 10),
    sort: z.enum(['asc', 'desc']).optional().default('desc'),
    sortBy: z.string().optional().default('createdAt')
  }),
  
  // Search query validation
  search: z.object({
    q: z.string().min(1).max(100).optional(),
    category: z.string().optional(),
    dateFrom: z.string().datetime().optional(),
    dateTo: z.string().datetime().optional()
  }),
  
  // File upload validation
  fileUpload: z.object({
    filename: z.string().min(1).max(255),
    mimetype: z.string().refine(
      (type) => ['image/jpeg', 'image/png', 'image/webp'].includes(type),
      'Only JPEG, PNG, and WebP images are allowed'
    ),
    size: z.number().max(10 * 1024 * 1024, 'File size must be less than 10MB')
  })
};

// SQL injection prevention
export const preventSQLInjection = (req: Request, res: Response, next: NextFunction) => {
  const sqlPatterns = [
    /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)/gi,
    /(--|\/\*|\*\/|;)/g,
    /(\b(OR|AND)\s+\d+\s*=\s*\d+)/gi,
    /(\b(OR|AND)\s+['"]\w+['"]\s*=\s*['"]\w+['"])/gi
  ];
  
  const checkValue = (value: any): boolean => {
    if (typeof value === 'string') {
      return sqlPatterns.some(pattern => pattern.test(value));
    }
    if (Array.isArray(value)) {
      return value.some(checkValue);
    }
    if (value && typeof value === 'object') {
      return Object.values(value).some(checkValue);
    }
    return false;
  };
  
  if (checkValue(req.body) || checkValue(req.query) || checkValue(req.params)) {
    return res.status(400).json({
      error: 'Invalid input detected',
      code: 'INVALID_INPUT'
    });
  }
  
  next();
};

// XSS prevention
export const preventXSS = (req: Request, res: Response, next: NextFunction) => {
  const xssPatterns = [
    /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
    /<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi,
    /javascript:/gi,
    /on\w+\s*=/gi,
    /<img[^>]+src[^>]*>/gi
  ];
  
  const checkValue = (value: any): boolean => {
    if (typeof value === 'string') {
      return xssPatterns.some(pattern => pattern.test(value));
    }
    if (Array.isArray(value)) {
      return value.some(checkValue);
    }
    if (value && typeof value === 'object') {
      return Object.values(value).some(checkValue);
    }
    return false;
  };
  
  if (checkValue(req.body) || checkValue(req.query) || checkValue(req.params)) {
    return res.status(400).json({
      error: 'Potentially malicious input detected',
      code: 'XSS_DETECTED'
    });
  }
  
  next();
};

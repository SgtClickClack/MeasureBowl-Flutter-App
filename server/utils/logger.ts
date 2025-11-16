import { Request, Response } from 'express';

export enum LogLevel {
  ERROR = 0,
  WARN = 1,
  INFO = 2,
  DEBUG = 3
}

class Logger {
  private level: LogLevel;
  private isProduction: boolean;

  constructor() {
    this.isProduction = process.env.NODE_ENV === 'production';
    this.level = this.isProduction ? LogLevel.INFO : LogLevel.DEBUG;
  }

  private formatMessage(level: string, message: string, meta?: any): string {
    const timestamp = new Date().toISOString();
    const metaStr = meta ? ` ${JSON.stringify(meta)}` : '';
    return `[${timestamp}] ${level}: ${message}${metaStr}`;
  }

  private shouldLog(level: LogLevel): boolean {
    return level <= this.level;
  }

  error(message: string, meta?: any): void {
    if (this.shouldLog(LogLevel.ERROR)) {
      console.error(this.formatMessage('ERROR', message, meta));
    }
  }

  warn(message: string, meta?: any): void {
    if (this.shouldLog(LogLevel.WARN)) {
      console.warn(this.formatMessage('WARN', message, meta));
    }
  }

  info(message: string, meta?: any): void {
    if (this.shouldLog(LogLevel.INFO)) {
      console.info(this.formatMessage('INFO', message, meta));
    }
  }

  debug(message: string, meta?: any): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      console.debug(this.formatMessage('DEBUG', message, meta));
    }
  }

  // Request logging middleware
  requestLogger() {
    return (req: Request, res: Response, next: any) => {
      const start = Date.now();
      const originalSend = res.send;

      res.send = function(body) {
        const duration = Date.now() - start;
        const logData = {
          method: req.method,
          url: req.url,
          statusCode: res.statusCode,
          duration: `${duration}ms`,
          userAgent: req.get('User-Agent'),
          ip: req.ip
        };

        if (res.statusCode >= 500) {
          logger.error('Server error', logData);
        } else if (res.statusCode >= 400) {
          logger.warn('Client error', logData);
        } else {
          logger.info('Request completed', logData);
        }

        return originalSend.call(this, body);
      };

      next();
    };
  }

  // Set log level dynamically
  setLevel(level: LogLevel): void {
    this.level = level;
  }

  // Get current log level
  getLevel(): LogLevel {
    return this.level;
  }
}

export const logger = new Logger();

// Flutter/Dart logging utilities
export const createFlutterLogger = () => {
  const isDebug = process.env.OPENCV_DEBUG === 'true';
  const logLevel = process.env.OPENCV_LOG_LEVEL || 'error';

  return {
    debug: (message: string, meta?: any) => {
      if (isDebug && logLevel === 'debug') {
        console.debug(`[Flutter] ${message}`, meta);
      }
    },
    info: (message: string, meta?: any) => {
      if (['debug', 'info'].includes(logLevel)) {
        console.info(`[Flutter] ${message}`, meta);
      }
    },
    warn: (message: string, meta?: any) => {
      if (['debug', 'info', 'warn'].includes(logLevel)) {
        console.warn(`[Flutter] ${message}`, meta);
      }
    },
    error: (message: string, meta?: any) => {
      console.error(`[Flutter] ${message}`, meta);
    }
  };
};

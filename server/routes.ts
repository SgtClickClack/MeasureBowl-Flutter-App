import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { insertMeasurementSchema, insertBowlMeasurementSchema } from "@shared/schema";
import { z } from "zod";
import { auth, createRateLimit, validateApiKey } from "./middleware/auth";
import { validateRequest, preventSQLInjection, preventXSS, commonSchemas } from "./middleware/validation";
import { logger } from "./utils/logger";

export async function registerRoutes(app: Express): Promise<Server> {
  // Apply rate limiting to all API routes
  const apiRateLimit = createRateLimit(15 * 60 * 1000, 100, 'Too many API requests, please try again later.');
  app.use('/api', apiRateLimit);
  
  // Apply security middleware to all API routes
  app.use('/api', preventSQLInjection);
  app.use('/api', preventXSS);
  
  // Apply API key validation to sensitive endpoints
  app.use('/api/measurements', validateApiKey);
  app.use('/api/settings', validateApiKey);
  
  // Save measurement with bowl data
  app.post("/api/measurements", 
    auth.optionalAuth, 
    validateRequest(insertMeasurementSchema.extend({
      bowls: z.array(insertBowlMeasurementSchema.omit({ measurementId: true })).optional()
    })),
    async (req, res) => {
    try {
      const measurementData = insertMeasurementSchema.parse(req.body);
      const bowlsData = z.array(insertBowlMeasurementSchema.omit({ measurementId: true })).parse(req.body.bowls || []);

      // Create the measurement
      const measurement = await storage.createMeasurement(measurementData);

      // Create bowl measurements
      const bowlMeasurements = await Promise.all(
        bowlsData.map(bowlData => 
          storage.createBowlMeasurement({
            ...bowlData,
            measurementId: measurement.id
          })
        )
      );

      res.json({ 
        measurement, 
        bowls: bowlMeasurements 
      });
    } catch (error) {
      logger.error("Error creating measurement", { error: error instanceof Error ? error.message : error });
      res.status(400).json({ 
        error: error instanceof Error ? error.message : "Invalid measurement data" 
      });
    }
  });

  // Get all measurements
  app.get("/api/measurements", auth.optionalAuth, async (req, res) => {
    try {
      const measurements = await storage.getAllMeasurements();
      res.json(measurements);
    } catch (error) {
      logger.error("Error fetching measurements", { error: error instanceof Error ? error.message : error });
      res.status(500).json({ 
        error: "Failed to fetch measurements" 
      });
    }
  });

  // Get specific measurement with bowls
  app.get("/api/measurements/:id", 
    auth.optionalAuth, 
    validateRequest(commonSchemas.idParam),
    async (req, res) => {
    try {
      const { id } = req.params;
      const measurement = await storage.getMeasurement(id);
      
      if (!measurement) {
        return res.status(404).json({ error: "Measurement not found" });
      }

      const bowls = await storage.getBowlMeasurementsByMeasurementId(id);
      
      res.json({ 
        measurement, 
        bowls 
      });
    } catch (error) {
      logger.error("Error fetching measurement", { error: error instanceof Error ? error.message : error, measurementId: req.params.id });
      res.status(500).json({ 
        error: "Failed to fetch measurement" 
      });
    }
  });

  // Get bowls for a specific measurement
  app.get("/api/measurements/:id/bowls", 
    auth.optionalAuth, 
    validateRequest(commonSchemas.idParam),
    async (req, res) => {
    try {
      const { id } = req.params;
      const bowls = await storage.getBowlMeasurementsByMeasurementId(id);
      res.json(bowls);
    } catch (error) {
      logger.error("Error fetching bowl measurements", { error: error instanceof Error ? error.message : error, measurementId: req.params.id });
      res.status(500).json({ 
        error: "Failed to fetch bowl measurements" 
      });
    }
  });

  // Tournaments API endpoints
  app.get("/api/tournaments", async (req, res) => {
    try {
      // Mock tournament data for now
      const tournaments = [
        {
          id: "1",
          name: "Spring Championship",
          description: "Annual spring tournament for all skill levels",
          startDate: "2024-03-15T09:00:00Z",
          endDate: "2024-03-17T17:00:00Z",
          location: "Central Lawn Bowls Club",
          maxParticipants: 32,
          currentParticipants: 18,
          status: "upcoming",
          category: "singles",
          entryFee: 25
        },
        {
          id: "2",
          name: "Summer Pairs Tournament",
          description: "Competitive pairs tournament in the summer",
          startDate: "2024-06-20T10:00:00Z",
          endDate: "2024-06-22T16:00:00Z",
          location: "Riverside Bowls Club",
          maxParticipants: 24,
          currentParticipants: 24,
          status: "active",
          category: "pairs",
          entryFee: 40
        },
        {
          id: "3",
          name: "Winter Fours Championship",
          description: "Premier fours competition",
          startDate: "2024-01-10T09:00:00Z",
          endDate: "2024-01-12T17:00:00Z",
          location: "Elite Bowls Center",
          maxParticipants: 16,
          currentParticipants: 16,
          status: "completed",
          category: "fours",
          entryFee: 80
        }
      ];
      res.json(tournaments);
    } catch (error) {
      logger.error("Error fetching tournaments", { error: error instanceof Error ? error.message : error });
      res.status(500).json({ 
        error: "Failed to fetch tournaments" 
      });
    }
  });

  // Settings API endpoints
  app.get("/api/settings", auth.authenticate, async (req, res) => {
    try {
      // Mock settings data for now
      const settings = {
        id: "user-1",
        user: {
          name: "John Doe",
          email: "john.doe@example.com",
          phone: "+1234567890"
        },
        notifications: {
          email: true,
          push: true,
          measurementReminders: false,
          tournamentUpdates: true
        },
        measurement: {
          defaultUnit: "cm",
          autoSave: true,
          highAccuracy: false,
          showGrid: true
        },
        privacy: {
          shareData: false,
          analytics: true,
          locationServices: false
        }
      };
      res.json(settings);
    } catch (error) {
      logger.error("Error fetching settings", { error: error instanceof Error ? error.message : error, userId: req.user?.id });
      res.status(500).json({ 
        error: "Failed to fetch settings" 
      });
    }
  });

  app.put("/api/settings", auth.authenticate, async (req, res) => {
    try {
      // Mock settings update
      const updatedSettings = req.body;
      logger.info("Settings updated", { userId: req.user?.id, settings: Object.keys(updatedSettings) });
      res.json({ 
        success: true, 
        message: "Settings updated successfully",
        settings: updatedSettings
      });
    } catch (error) {
      logger.error("Error updating settings", { error: error instanceof Error ? error.message : error, userId: req.user?.id });
      res.status(500).json({ 
        error: "Failed to update settings" 
      });
    }
  });

  app.post("/api/settings/reset", auth.authenticate, async (req, res) => {
    try {
      // Mock settings reset
      const defaultSettings = {
        id: "user-1",
        user: {
          name: "",
          email: "",
          phone: ""
        },
        notifications: {
          email: true,
          push: true,
          measurementReminders: false,
          tournamentUpdates: true
        },
        measurement: {
          defaultUnit: "cm",
          autoSave: true,
          highAccuracy: false,
          showGrid: true
        },
        privacy: {
          shareData: false,
          analytics: true,
          locationServices: false
        }
      };
      res.json({ 
        success: true, 
        message: "Settings reset to defaults",
        settings: defaultSettings
      });
    } catch (error) {
      logger.error("Error resetting settings", { error: error instanceof Error ? error.message : error, userId: req.user?.id });
      res.status(500).json({ 
        error: "Failed to reset settings" 
      });
    }
  });

  const httpServer = createServer(app);
  return httpServer;
}

import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { insertMeasurementSchema, insertBowlMeasurementSchema } from "@shared/schema";
import { z } from "zod";

export async function registerRoutes(app: Express): Promise<Server> {
  // Save measurement with bowl data
  app.post("/api/measurements", async (req, res) => {
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
      console.error("Error creating measurement:", error);
      res.status(400).json({ 
        error: error instanceof Error ? error.message : "Invalid measurement data" 
      });
    }
  });

  // Get all measurements
  app.get("/api/measurements", async (req, res) => {
    try {
      const measurements = await storage.getAllMeasurements();
      res.json(measurements);
    } catch (error) {
      console.error("Error fetching measurements:", error);
      res.status(500).json({ 
        error: "Failed to fetch measurements" 
      });
    }
  });

  // Get specific measurement with bowls
  app.get("/api/measurements/:id", async (req, res) => {
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
      console.error("Error fetching measurement:", error);
      res.status(500).json({ 
        error: "Failed to fetch measurement" 
      });
    }
  });

  // Get bowls for a specific measurement
  app.get("/api/measurements/:id/bowls", async (req, res) => {
    try {
      const { id } = req.params;
      const bowls = await storage.getBowlMeasurementsByMeasurementId(id);
      res.json(bowls);
    } catch (error) {
      console.error("Error fetching bowl measurements:", error);
      res.status(500).json({ 
        error: "Failed to fetch bowl measurements" 
      });
    }
  });

  const httpServer = createServer(app);
  return httpServer;
}

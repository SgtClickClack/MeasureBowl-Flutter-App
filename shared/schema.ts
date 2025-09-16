import { sql, relations } from "drizzle-orm";
import { pgTable, text, varchar, real, timestamp, integer } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const measurements = pgTable("measurements", {
  id: varchar("id").primaryKey().default(sql`gen_random_uuid()`),
  imageData: text("image_data").notNull(), // Base64 encoded image
  timestamp: timestamp("timestamp").defaultNow().notNull(),
  jackPosition: text("jack_position").notNull(), // JSON string {x, y, radius}
  bowlCount: integer("bowl_count").notNull().default(0),
});

export const bowlMeasurements = pgTable("bowl_measurements", {
  id: varchar("id").primaryKey().default(sql`gen_random_uuid()`),
  measurementId: varchar("measurement_id").notNull().references(() => measurements.id, { onDelete: "cascade" }),
  color: text("color").notNull(),
  position: text("position").notNull(), // JSON string {x, y, radius}
  distanceFromJack: real("distance_from_jack").notNull(), // in centimeters
  rank: integer("rank").notNull(),
});

export const measurementsRelations = relations(measurements, ({ many }) => ({
  bowls: many(bowlMeasurements),
}));

export const bowlMeasurementsRelations = relations(bowlMeasurements, ({ one }) => ({
  measurement: one(measurements, {
    fields: [bowlMeasurements.measurementId],
    references: [measurements.id],
  }),
}));

export const insertMeasurementSchema = createInsertSchema(measurements).pick({
  imageData: true,
  jackPosition: true,
  bowlCount: true,
});

export const insertBowlMeasurementSchema = createInsertSchema(bowlMeasurements).pick({
  measurementId: true,
  color: true,
  position: true,
  distanceFromJack: true,
  rank: true,
});

export type InsertMeasurement = z.infer<typeof insertMeasurementSchema>;
export type Measurement = typeof measurements.$inferSelect;
export type InsertBowlMeasurement = z.infer<typeof insertBowlMeasurementSchema>;
export type BowlMeasurement = typeof bowlMeasurements.$inferSelect;

// Frontend types
export const measurementResultSchema = z.object({
  id: z.string(),
  imageData: z.string(),
  timestamp: z.date(),
  jackPosition: z.object({
    x: z.number(),
    y: z.number(),
    radius: z.number(),
  }),
  bowls: z.array(z.object({
    id: z.string(),
    color: z.string(),
    position: z.object({
      x: z.number(),
      y: z.number(),
      radius: z.number(),
    }),
    distanceFromJack: z.number(),
    rank: z.number(),
  })),
});

export type MeasurementResult = z.infer<typeof measurementResultSchema>;

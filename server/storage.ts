import { type Measurement, type BowlMeasurement, type InsertMeasurement, type InsertBowlMeasurement, measurements, bowlMeasurements } from "@shared/schema";
import { db } from "./db";
import { eq, desc } from "drizzle-orm";

export interface IStorage {
  // Measurement operations
  createMeasurement(measurement: InsertMeasurement): Promise<Measurement>;
  getMeasurement(id: string): Promise<Measurement | undefined>;
  getAllMeasurements(): Promise<Measurement[]>;
  
  // Bowl measurement operations
  createBowlMeasurement(bowlMeasurement: InsertBowlMeasurement): Promise<BowlMeasurement>;
  getBowlMeasurementsByMeasurementId(measurementId: string): Promise<BowlMeasurement[]>;
}

export class DatabaseStorage implements IStorage {
  async createMeasurement(insertMeasurement: InsertMeasurement): Promise<Measurement> {
    const [measurement] = await db
      .insert(measurements)
      .values({
        ...insertMeasurement,
        bowlCount: insertMeasurement.bowlCount ?? 0
      })
      .returning();
    return measurement;
  }

  async getMeasurement(id: string): Promise<Measurement | undefined> {
    const [measurement] = await db
      .select()
      .from(measurements)
      .where(eq(measurements.id, id));
    return measurement || undefined;
  }

  async getAllMeasurements(): Promise<Measurement[]> {
    return await db
      .select()
      .from(measurements)
      .orderBy(desc(measurements.timestamp));
  }

  async createBowlMeasurement(insertBowlMeasurement: InsertBowlMeasurement): Promise<BowlMeasurement> {
    const [bowlMeasurement] = await db
      .insert(bowlMeasurements)
      .values(insertBowlMeasurement)
      .returning();
    return bowlMeasurement;
  }

  async getBowlMeasurementsByMeasurementId(measurementId: string): Promise<BowlMeasurement[]> {
    return await db
      .select()
      .from(bowlMeasurements)
      .where(eq(bowlMeasurements.measurementId, measurementId))
      .orderBy(bowlMeasurements.rank);
  }
}

export const storage = new DatabaseStorage();

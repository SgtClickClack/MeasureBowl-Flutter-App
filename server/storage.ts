import { type Measurement, type BowlMeasurement, type InsertMeasurement, type InsertBowlMeasurement } from "@shared/schema";
import { randomUUID } from "crypto";

export interface IStorage {
  // Measurement operations
  createMeasurement(measurement: InsertMeasurement): Promise<Measurement>;
  getMeasurement(id: string): Promise<Measurement | undefined>;
  getAllMeasurements(): Promise<Measurement[]>;
  
  // Bowl measurement operations
  createBowlMeasurement(bowlMeasurement: InsertBowlMeasurement): Promise<BowlMeasurement>;
  getBowlMeasurementsByMeasurementId(measurementId: string): Promise<BowlMeasurement[]>;
}

export class MemStorage implements IStorage {
  private measurements: Map<string, Measurement>;
  private bowlMeasurements: Map<string, BowlMeasurement>;

  constructor() {
    this.measurements = new Map();
    this.bowlMeasurements = new Map();
  }

  async createMeasurement(insertMeasurement: InsertMeasurement): Promise<Measurement> {
    const id = randomUUID();
    const measurement: Measurement = { 
      ...insertMeasurement, 
      id,
      timestamp: new Date(),
      bowlCount: insertMeasurement.bowlCount ?? 0
    };
    this.measurements.set(id, measurement);
    return measurement;
  }

  async getMeasurement(id: string): Promise<Measurement | undefined> {
    return this.measurements.get(id);
  }

  async getAllMeasurements(): Promise<Measurement[]> {
    return Array.from(this.measurements.values())
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  }

  async createBowlMeasurement(insertBowlMeasurement: InsertBowlMeasurement): Promise<BowlMeasurement> {
    const id = randomUUID();
    const bowlMeasurement: BowlMeasurement = { ...insertBowlMeasurement, id };
    this.bowlMeasurements.set(id, bowlMeasurement);
    return bowlMeasurement;
  }

  async getBowlMeasurementsByMeasurementId(measurementId: string): Promise<BowlMeasurement[]> {
    return Array.from(this.bowlMeasurements.values())
      .filter(bowl => bowl.measurementId === measurementId)
      .sort((a, b) => a.rank - b.rank);
  }
}

export const storage = new MemStorage();

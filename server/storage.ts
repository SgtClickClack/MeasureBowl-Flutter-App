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

export class MockStorage implements IStorage {
  private measurements: Measurement[] = [
    {
      id: 'mock-1',
      timestamp: new Date('2024-01-15T10:30:00Z'),
      imageData: 'mock-image-data-1',
      jackPosition: 'center',
      bowlCount: 4,
      createdAt: new Date('2024-01-15T10:30:00Z'),
      updatedAt: new Date('2024-01-15T10:30:00Z')
    },
    {
      id: 'mock-2',
      timestamp: new Date('2024-01-16T14:20:00Z'),
      imageData: 'mock-image-data-2',
      jackPosition: 'left',
      bowlCount: 6,
      createdAt: new Date('2024-01-16T14:20:00Z'),
      updatedAt: new Date('2024-01-16T14:20:00Z')
    }
  ];
  private bowlMeasurements: BowlMeasurement[] = [
    {
      id: 'bowl-1',
      measurementId: 'mock-1',
      color: 'black',
      position: 'top-left',
      distanceFromJack: 15.5,
      rank: 1,
      createdAt: new Date('2024-01-15T10:30:00Z'),
      updatedAt: new Date('2024-01-15T10:30:00Z')
    },
    {
      id: 'bowl-2',
      measurementId: 'mock-1',
      color: 'brown',
      position: 'top-right',
      distanceFromJack: 22.3,
      rank: 2,
      createdAt: new Date('2024-01-15T10:30:00Z'),
      updatedAt: new Date('2024-01-15T10:30:00Z')
    },
    {
      id: 'bowl-3',
      measurementId: 'mock-2',
      color: 'blue',
      position: 'center',
      distanceFromJack: 8.7,
      rank: 1,
      createdAt: new Date('2024-01-16T14:20:00Z'),
      updatedAt: new Date('2024-01-16T14:20:00Z')
    }
  ];

  async createMeasurement(insertMeasurement: InsertMeasurement): Promise<Measurement> {
    const measurement: Measurement = {
      id: `mock-${Date.now()}`,
      timestamp: new Date(),
      imageData: insertMeasurement.imageData || '',
      jackPosition: insertMeasurement.jackPosition || '',
      bowlCount: insertMeasurement.bowlCount || 0,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    this.measurements.push(measurement);
    return measurement;
  }

  async getMeasurement(id: string): Promise<Measurement | undefined> {
    return this.measurements.find(m => m.id === id);
  }

  async getAllMeasurements(): Promise<Measurement[]> {
    return [...this.measurements].sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  }

  async createBowlMeasurement(insertBowlMeasurement: InsertBowlMeasurement): Promise<BowlMeasurement> {
    const bowlMeasurement: BowlMeasurement = {
      id: `bowl-${Date.now()}`,
      measurementId: insertBowlMeasurement.measurementId,
      color: insertBowlMeasurement.color || 'unknown',
      position: insertBowlMeasurement.position || '',
      distanceFromJack: insertBowlMeasurement.distanceFromJack || 0,
      rank: insertBowlMeasurement.rank || 1,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    this.bowlMeasurements.push(bowlMeasurement);
    return bowlMeasurement;
  }

  async getBowlMeasurementsByMeasurementId(measurementId: string): Promise<BowlMeasurement[]> {
    return this.bowlMeasurements
      .filter(bm => bm.measurementId === measurementId)
      .sort((a, b) => a.rank - b.rank);
  }
}

// Use mock storage for development/testing
export const storage = process.env.NODE_ENV === 'development' || !process.env.DATABASE_URL?.includes('postgresql://') 
  ? new MockStorage() 
  : new DatabaseStorage();

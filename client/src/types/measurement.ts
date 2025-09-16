export interface Position {
  x: number;
  y: number;
  radius: number;
}

export interface DetectedBowl {
  id: string;
  color: string;
  position: Position;
  distanceFromJack: number;
  rank: number;
}

export interface MeasurementData {
  id: string;
  imageData: string;
  timestamp: Date;
  jackPosition: Position;
  bowls: DetectedBowl[];
}

export interface ProcessingStep {
  name: string;
  status: 'pending' | 'processing' | 'complete' | 'error';
  message?: string;
}

export type AppView = 'camera' | 'processing' | 'results' | 'fallback';

export interface CameraState {
  isInitialized: boolean;
  hasPermission: boolean;
  error: string | null;
  stream: MediaStream | null;
}

export interface OpenCVState {
  isLoaded: boolean;
  isProcessing: boolean;
  error: string | null;
}

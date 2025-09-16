import { Position, DetectedBowl, MeasurementData } from '@/types/measurement';

// Jack diameter in millimeters (standard lawn bowls jack)
const JACK_DIAMETER_MM = 63.5;

export interface DetectionResult {
  jack: Position | null;
  bowls: Array<{
    position: Position;
    color: string;
  }>;
  error?: string;
}

export function processImageWithOpenCV(imageData: string): Promise<DetectionResult> {
  return new Promise((resolve) => {
    if (!window.cv || !window.cv.Mat) {
      resolve({ jack: null, bowls: [], error: 'OpenCV not loaded' });
      return;
    }

    try {
      // Create image from base64 data
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        
        if (!ctx) {
          resolve({ jack: null, bowls: [], error: 'Failed to create canvas context' });
          return;
        }

        ctx.drawImage(img, 0, 0);
        
        // Convert to OpenCV Mat
        const src = window.cv.imread(canvas);
        const gray = new window.cv.Mat();
        const circles = new window.cv.Mat();

        // Convert to grayscale
        window.cv.cvtColor(src, gray, window.cv.COLOR_RGBA2GRAY);

        // Apply Gaussian blur to reduce noise
        const blurred = new window.cv.Mat();
        window.cv.GaussianBlur(gray, blurred, new window.cv.Size(9, 9), 2, 2);

        // Detect circles using HoughCircles
        window.cv.HoughCircles(
          blurred,
          circles,
          window.cv.HOUGH_GRADIENT,
          1,
          gray.rows / 16, // min distance between centers
          100, // param1 (higher threshold for edge detection)
          30,  // param2 (accumulator threshold for center detection)
          10,  // min radius
          50   // max radius
        );

        const detectedObjects: Array<{ position: Position; isWhite: boolean }> = [];

        // Process detected circles
        for (let i = 0; i < circles.cols; ++i) {
          const x = circles.data32F[i * 3];
          const y = circles.data32F[i * 3 + 1];
          const radius = circles.data32F[i * 3 + 2];

          // Analyze color at the center of the circle
          const centerColor = getPixelColor(src, Math.round(x), Math.round(y));
          const isWhite = isWhiteish(centerColor);

          detectedObjects.push({
            position: { x, y, radius },
            isWhite
          });
        }

        // Find jack (smallest white circle) and bowls
        const whiteCandidates = detectedObjects.filter(obj => obj.isWhite);
        const coloredCandidates = detectedObjects.filter(obj => !obj.isWhite);

        // Jack is typically the smallest white object
        const jack = whiteCandidates.length > 0 
          ? whiteCandidates.reduce((smallest, current) => 
              current.position.radius < smallest.position.radius ? current : smallest
            ).position
          : null;

        // Identify bowl colors and positions
        const bowls = coloredCandidates.map((candidate, index) => ({
          position: candidate.position,
          color: identifyBowlColor(src, candidate.position)
        }));

        // Clean up
        src.delete();
        gray.delete();
        blurred.delete();
        circles.delete();

        resolve({ jack, bowls });
      };

      img.onerror = () => {
        resolve({ jack: null, bowls: [], error: 'Failed to load image' });
      };

      img.src = imageData;
    } catch (error) {
      resolve({ 
        jack: null, 
        bowls: [], 
        error: error instanceof Error ? error.message : 'Processing failed' 
      });
    }
  });
}

function getPixelColor(mat: any, x: number, y: number): [number, number, number] {
  const pixel = mat.ucharPtr(y, x);
  return [pixel[0], pixel[1], pixel[2]];
}

function isWhiteish([r, g, b]: [number, number, number]): boolean {
  // Check if the color is predominantly white/light
  const average = (r + g + b) / 3;
  const threshold = 180; // Adjust this threshold as needed
  return average > threshold && Math.abs(r - g) < 30 && Math.abs(g - b) < 30;
}

function identifyBowlColor(mat: any, position: Position): string {
  const { x, y } = position;
  const [r, g, b] = getPixelColor(mat, Math.round(x), Math.round(y));

  // Simple color classification
  if (r > 150 && g < 100 && b < 100) return 'Red';
  if (r > 150 && g > 150 && b < 100) return 'Yellow';
  if (r < 100 && g > 100 && b < 100) return 'Green';
  if (r < 100 && g < 100 && b > 150) return 'Blue';
  if (r < 80 && g < 80 && b < 80) return 'Black';
  
  return 'Unknown';
}

export function calculateDistances(
  jack: Position, 
  bowls: Array<{ position: Position; color: string }>
): DetectedBowl[] {
  if (!jack) return [];

  // Calculate scale: pixels per millimeter based on jack size
  const pixelsPerMM = (jack.radius * 2) / JACK_DIAMETER_MM;

  return bowls.map((bowl, index) => {
    const dx = bowl.position.x - jack.x;
    const dy = bowl.position.y - jack.y;
    
    // Distance between circle edges, not centers
    const centerDistance = Math.sqrt(dx * dx + dy * dy);
    const edgeDistance = Math.max(0, centerDistance - jack.radius - bowl.position.radius);
    
    // Convert to millimeters, then to centimeters
    const distanceInMM = edgeDistance / pixelsPerMM;
    const distanceInCM = distanceInMM / 10;

    return {
      id: `bowl-${index}`,
      color: bowl.color,
      position: bowl.position,
      distanceFromJack: Math.round(distanceInCM * 10) / 10, // Round to 1 decimal
      rank: 0 // Will be set after sorting
    };
  }).sort((a, b) => a.distanceFromJack - b.distanceFromJack)
    .map((bowl, index) => ({ ...bowl, rank: index + 1 }));
}

export function calculateManualDistances(
  jack: { x: number; y: number; radius: number },
  bowls: Array<{ x: number; y: number; color: string; radius: number }>
): DetectedBowl[] {
  // Calculate scale: pixels per millimeter based on jack size
  const pixelsPerMM = (jack.radius * 2) / JACK_DIAMETER_MM;

  return bowls.map((bowl, index) => {
    const dx = bowl.x - jack.x;
    const dy = bowl.y - jack.y;
    
    // Distance between circle edges, not centers
    const centerDistance = Math.sqrt(dx * dx + dy * dy);
    const edgeDistance = Math.max(0, centerDistance - jack.radius - bowl.radius);
    
    // Convert to millimeters, then to centimeters
    const distanceInMM = edgeDistance / pixelsPerMM;
    const distanceInCM = distanceInMM / 10;

    return {
      id: `manual-bowl-${index}`,
      color: bowl.color,
      position: { x: bowl.x, y: bowl.y, radius: bowl.radius },
      distanceFromJack: Math.round(distanceInCM * 10) / 10, // Round to 1 decimal
      rank: 0 // Will be set after sorting
    };
  }).sort((a, b) => a.distanceFromJack - b.distanceFromJack)
    .map((bowl, index) => ({ ...bowl, rank: index + 1 }));
}

export async function processMeasurement(imageData: string): Promise<MeasurementData | null> {
  const detection = await processImageWithOpenCV(imageData);
  
  if (!detection.jack || detection.bowls.length === 0) {
    return null;
  }

  const bowls = calculateDistances(detection.jack, detection.bowls);

  return {
    id: `measurement-${Date.now()}`,
    imageData,
    timestamp: new Date(),
    jackPosition: detection.jack,
    bowls
  };
}

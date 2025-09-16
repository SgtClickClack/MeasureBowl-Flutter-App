import { useState } from 'react';
import { CameraView } from '@/components/camera-view';
import { ProcessingView } from '@/components/processing-view';
import { ResultsView } from '@/components/results-view';
import { FallbackView } from '@/components/fallback-view';
import { processMeasurement } from '@/lib/opencv-utils';
import { AppView, MeasurementData } from '@/types/measurement';
import { useToast } from '@/hooks/use-toast';

export default function Home() {
  const [currentView, setCurrentView] = useState<AppView>('camera');
  const [capturedImage, setCapturedImage] = useState<string>('');
  const [measurementData, setMeasurementData] = useState<MeasurementData | null>(null);
  const { toast } = useToast();

  const handleCapture = async (imageData: string) => {
    setCapturedImage(imageData);
    setCurrentView('processing');

    try {
      // Process the image with OpenCV
      const result = await processMeasurement(imageData);
      
      if (result) {
        setMeasurementData(result);
        setCurrentView('results');
      } else {
        // Fallback to manual identification
        setCurrentView('fallback');
        toast({
          title: "Manual Identification Required",
          description: "Automatic detection failed. Please identify objects manually.",
          variant: "default",
        });
      }
    } catch (error) {
      console.error('Processing error:', error);
      setCurrentView('fallback');
      toast({
        title: "Processing Error",
        description: "Failed to process image automatically. Please try manual identification.",
        variant: "destructive",
      });
    }
  };

  const handleProcessingComplete = () => {
    if (measurementData) {
      setCurrentView('results');
    }
  };

  const handleProcessingError = (error: string) => {
    console.error('Processing error:', error);
    setCurrentView('fallback');
    toast({
      title: "Processing Failed",
      description: error,
      variant: "destructive",
    });
  };

  const handleMeasureAgain = () => {
    setCurrentView('camera');
    setCapturedImage('');
    setMeasurementData(null);
  };

  const handleFallbackCancel = () => {
    setCurrentView('camera');
    setCapturedImage('');
  };

  const handleEnterManual = () => {
    setCurrentView('fallback');
    setCapturedImage('data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k='); // Minimal placeholder image
  };

  const handleManualComplete = (
    jackPosition: { x: number; y: number },
    bowlPositions: Array<{ x: number; y: number; color: string }>
  ) => {
    // Create measurement data from manual identification
    const manualData: MeasurementData = {
      id: `manual-${Date.now()}`,
      imageData: capturedImage,
      timestamp: new Date(),
      jackPosition: { ...jackPosition, radius: 15 },
      bowls: bowlPositions.map((bowl, index) => ({
        id: `manual-bowl-${index}`,
        color: bowl.color,
        position: { ...bowl, radius: 20 },
        distanceFromJack: Math.random() * 20 + 5, // Placeholder calculation
        rank: index + 1,
      })).sort((a, b) => a.distanceFromJack - b.distanceFromJack)
        .map((bowl, index) => ({ ...bowl, rank: index + 1 })),
    };

    setMeasurementData(manualData);
    setCurrentView('results');
    toast({
      title: "Manual Identification Complete",
      description: "Successfully identified bowls and jack manually.",
      variant: "default",
    });
  };

  const renderCurrentView = () => {
    switch (currentView) {
      case 'camera':
        return <CameraView onCapture={handleCapture} onEnterManual={handleEnterManual} />;
      case 'processing':
        return (
          <ProcessingView 
            onComplete={handleProcessingComplete}
            onError={handleProcessingError}
          />
        );
      case 'results':
        return measurementData ? (
          <ResultsView 
            measurementData={measurementData}
            onMeasureAgain={handleMeasureAgain}
          />
        ) : null;
      case 'fallback':
        return (
          <FallbackView
            imageData={capturedImage}
            onCancel={handleFallbackCancel}
            onManualComplete={handleManualComplete}
          />
        );
      default:
        return <CameraView onCapture={handleCapture} onEnterManual={handleEnterManual} />;
    }
  };

  return (
    <div className="relative min-h-screen flex flex-col bg-background text-foreground">
      {renderCurrentView()}
    </div>
  );
}

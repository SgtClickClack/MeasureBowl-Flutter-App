import { useState } from 'react';
import { processMeasurement, calculateManualDistances } from '@/lib/opencv-utils';
import { AppView, MeasurementData } from '@/types/measurement';
import { useToast } from '@/hooks/use-toast';
import { apiRequest, queryClient } from '@/lib/queryClient';

export function useMeasurementFlow() {
  const [currentView, setCurrentView] = useState<AppView>('camera');
  const [capturedImage, setCapturedImage] = useState<string>('');
  const [measurementData, setMeasurementData] = useState<MeasurementData | null>(null);
  const { toast } = useToast();

  const handleCapture = (imageData: string) => {
    setCapturedImage(imageData);
    setCurrentView('processing');
  };

  const handleProcessingComplete = async (result: MeasurementData) => {
    setMeasurementData(result);
    setCurrentView('results');
    
    // Save measurement to database
    try {
      await saveMeasurementToDatabase(result);
      toast({
        title: "Measurement Saved",
        description: "Your measurement has been saved to history.",
        variant: "default",
      });
    } catch (error) {
      console.error('Failed to save measurement:', error);
      toast({
        title: "Save Failed",
        description: "Could not save measurement to history.",
        variant: "destructive",
      });
    }
  };

  const handleProcessingError = (error: string) => {
    console.error('Processing error:', error);
    setCurrentView('fallback');
    toast({
      title: "Processing Failed",
      description: "Automatic detection failed. Please identify objects manually.",
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

  const saveMeasurementToDatabase = async (data: MeasurementData) => {
    const measurementPayload = {
      imageData: data.imageData,
      jackPosition: JSON.stringify(data.jackPosition),
      bowlCount: data.bowls.length,
      bowls: data.bowls.map(bowl => ({
        color: bowl.color,
        position: JSON.stringify(bowl.position),
        distanceFromJack: bowl.distanceFromJack,
        rank: bowl.rank
      }))
    };
    
    await apiRequest('POST', '/api/measurements', measurementPayload);
    queryClient.invalidateQueries({ queryKey: ['/api/measurements'] });
  };

  const handleManualComplete = async (
    jackPosition: { x: number; y: number; radius: number },
    bowlPositions: Array<{ x: number; y: number; color: string; radius: number }>
  ) => {
    const jack = jackPosition;
    const bowls = bowlPositions;
    
    const calculatedBowls = calculateManualDistances(jack, bowls);
    
    const manualData: MeasurementData = {
      id: `manual-${Date.now()}`,
      imageData: capturedImage,
      timestamp: new Date(),
      jackPosition: jack,
      bowls: calculatedBowls,
    };

    setMeasurementData(manualData);
    setCurrentView('results');
    
    try {
      await saveMeasurementToDatabase(manualData);
      toast({
        title: "Manual Identification Complete",
        description: "Successfully calculated distances and saved to history.",
        variant: "default",
      });
    } catch (error) {
      console.error('Failed to save measurement:', error);
      toast({
        title: "Calculation Complete",
        description: "Distances calculated but could not save to history.",
        variant: "default",
      });
    }
  };

  return {
    currentView,
    capturedImage,
    measurementData,
    handleCapture,
    handleProcessingComplete,
    handleProcessingError,
    handleMeasureAgain,
    handleFallbackCancel,
    handleEnterManual,
    handleManualComplete,
  };
}

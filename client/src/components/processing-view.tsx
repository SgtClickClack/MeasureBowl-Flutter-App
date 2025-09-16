import { useState, useEffect } from 'react';
import { Brain, Check, Clock, Loader2 } from 'lucide-react';
import { ProcessingStep, MeasurementData } from '@/types/measurement';
import { processMeasurement } from '@/lib/opencv-utils';

interface ProcessingViewProps {
  imageData: string;
  onComplete: (result: MeasurementData) => void;
  onError: (error: string) => void;
}

export function ProcessingView({ imageData, onComplete, onError }: ProcessingViewProps) {
  const [steps, setSteps] = useState<ProcessingStep[]>([
    { name: 'Circle Detection', status: 'processing', message: 'Detecting circular objects...' },
    { name: 'Bowl Recognition', status: 'pending', message: 'Identifying bowls and jack...' },
    { name: 'Distance Calculation', status: 'pending', message: 'Calculating measurements...' }
  ]);

  useEffect(() => {
    const processImage = async () => {
      try {
        // Step 1: Circle Detection
        setSteps(prev => prev.map((step, index) => 
          index === 0 
            ? { ...step, status: 'processing', message: 'Detecting circular objects...' }
            : step
        ));
        
        await new Promise(resolve => setTimeout(resolve, 500)); // Brief delay for UI feedback
        
        // Step 2: Start actual OpenCV processing
        setSteps(prev => prev.map((step, index) => 
          index === 0 
            ? { ...step, status: 'complete', message: 'Circles detected successfully' }
            : index === 1
            ? { ...step, status: 'processing', message: 'Analyzing bowl positions...' }
            : step
        ));
        
        const result = await processMeasurement(imageData);
        
        // Step 3: Distance Calculation
        setSteps(prev => prev.map((step, index) => 
          index === 1 
            ? { ...step, status: 'complete', message: 'Bowls and jack identified' }
            : index === 2
            ? { ...step, status: 'processing', message: 'Computing distances...' }
            : step
        ));
        
        await new Promise(resolve => setTimeout(resolve, 500)); // Brief delay for UI feedback
        
        setSteps(prev => prev.map((step, index) => 
          index === 2 
            ? { ...step, status: 'complete', message: 'Measurements complete' }
            : step
        ));
        
        if (result) {
          setTimeout(() => {
            onComplete(result);
          }, 500);
        } else {
          onError('Failed to detect jack and bowls automatically');
        }
      } catch (error) {
        console.error('OpenCV processing error:', error);
        onError(error instanceof Error ? error.message : 'Processing failed');
      }
    };

    processImage();
  }, [imageData, onComplete, onError]);

  const getStepIcon = (step: ProcessingStep) => {
    switch (step.status) {
      case 'complete':
        return <Check className="w-4 h-4 text-success" />;
      case 'processing':
        return <Loader2 className="w-4 h-4 text-primary animate-spin" />;
      default:
        return <Clock className="w-4 h-4 text-muted-foreground" />;
    }
  };

  return (
    <div className="flex-1 bg-background">
      <div className="flex flex-col items-center justify-center min-h-screen px-6">
        <div className="text-center space-y-6">
          <div className="relative">
            <div className="w-24 h-24 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto"></div>
            <Brain className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 text-2xl text-primary" />
          </div>
          
          <div>
            <h2 className="text-2xl font-bold text-foreground mb-2">Analyzing Image</h2>
            <p className="text-muted-foreground text-lg">
              Detecting jack and bowls...
            </p>
          </div>
          
          <div className="bg-card border border-border rounded-lg p-4 max-w-sm">
            <div className="text-sm text-muted-foreground space-y-3">
              {steps.map((step, index) => (
                <div 
                  key={index} 
                  className="flex items-center justify-between"
                  data-testid={`processing-step-${index}`}
                >
                  <span className="text-foreground">{step.name}</span>
                  {getStepIcon(step)}
                </div>
              ))}
            </div>
          </div>
          
          <div className="text-xs text-muted-foreground max-w-xs">
            {steps.find(step => step.status === 'processing')?.message || 'Processing complete'}
          </div>
        </div>
      </div>
    </div>
  );
}

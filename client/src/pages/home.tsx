import { CameraView } from '@/components/camera-view';
import { ProcessingView } from '@/components/processing-view';
import { ResultsView } from '@/components/results-view';
import { FallbackView } from '@/components/fallback-view';
import { useMeasurementFlow } from '@/hooks/use-measurement-flow';

export default function Home() {
  const {
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
  } = useMeasurementFlow();

  const renderCurrentView = () => {
    switch (currentView) {
      case 'camera':
        return <CameraView onCapture={handleCapture} onEnterManual={handleEnterManual} />;
      case 'processing':
        return (
          <ProcessingView 
            imageData={capturedImage}
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
    <div data-testid="home-page" className="relative min-h-screen flex flex-col bg-background text-foreground">
      {renderCurrentView()}
    </div>
  );
}

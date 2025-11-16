import { useState, useEffect, useRef } from 'react';
import { Camera, Settings, HelpCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useCamera } from '@/hooks/use-camera';
import { useOpenCV } from '@/hooks/use-opencv';

interface CameraViewProps {
  onCapture: (imageData: string) => void;
  onEnterManual?: () => void;
}

export function CameraView({ onCapture, onEnterManual }: CameraViewProps) {
  const { cameraState, videoRef, initializeCamera, captureImage } = useCamera();
  const { openCVState } = useOpenCV();
  const [isCapturing, setIsCapturing] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    initializeCamera();
  }, []);

  const handleMeasure = async () => {
    if (!openCVState.isLoaded) {
      alert('Computer vision library is still loading. Please wait a moment.');
      return;
    }

    setIsCapturing(true);
    const imageData = captureImage();
    
    if (imageData) {
      onCapture(imageData);
    } else {
      alert('Failed to capture image. Please try again.');
      setIsCapturing(false);
    }
  };

  if (cameraState.error) {
    return (
      <div data-testid="camera-view" className="flex-1 flex items-center justify-center bg-secondary camera-viewfinder">
        <div className="text-center space-y-4 p-6 bg-background/80 backdrop-blur-sm rounded-lg max-w-sm mx-4">
          <Camera className="mx-auto h-12 w-12 text-destructive" />
          <div>
            <h3 className="text-lg font-semibold text-foreground mb-2">Camera Access Required</h3>
            <p className="text-muted-foreground text-base leading-relaxed mb-4">
              {cameraState.error}
            </p>
            <div className="space-y-3">
              <Button 
                onClick={initializeCamera}
                className="w-full"
                data-testid="retry-camera-button"
              >
                Try Again
              </Button>
              
              <Button 
                onClick={() => fileInputRef.current?.click()}
                variant="secondary"
                className="w-full"
                data-testid="upload-photo-button"
              >
                Upload Photo Instead
              </Button>
              
              {onEnterManual && (
                <Button 
                  onClick={onEnterManual}
                  variant="outline"
                  className="w-full"
                  data-testid="enter-manual-button"
                >
                  Enter Manual Mode
                </Button>
              )}
            </div>
            
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) {
                  const reader = new FileReader();
                  reader.onload = (event) => {
                    const imageData = event.target?.result as string;
                    if (imageData) {
                      onCapture(imageData);
                    }
                  };
                  reader.readAsDataURL(file);
                }
              }}
            />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div data-testid="camera-view" className="flex-1 relative bg-secondary camera-viewfinder">
      {/* Status Bar */}
      <div className="absolute top-0 left-0 right-0 z-10 bg-background/80 backdrop-blur-sm border-b border-border">
        <div className="flex items-center justify-between px-6 py-4">
          <h1 className="text-xl font-bold text-foreground">Bowls Measure</h1>
          <div className="flex items-center space-x-3">
            <div 
              className={`w-3 h-3 rounded-full ${
                cameraState.isInitialized && openCVState.isLoaded 
                  ? 'bg-success pulse-ring' 
                  : 'bg-warning'
              }`} 
              title={
                cameraState.isInitialized && openCVState.isLoaded 
                  ? 'Ready' 
                  : 'Loading...'
              }
            />
            <span className="text-sm font-medium text-muted-foreground">
              {cameraState.isInitialized && openCVState.isLoaded ? 'Ready' : 'Loading...'}
            </span>
          </div>
        </div>
      </div>

      {/* Live Camera Preview Area */}
      <div className="absolute inset-0 mt-16 mb-32 mx-4 rounded-lg overflow-hidden border-2 border-primary">
        {cameraState.isInitialized ? (
          <video
            ref={videoRef}
            autoPlay
            playsInline
            muted
            className="w-full h-full object-cover"
            data-testid="camera-preview"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-muted">
            <div className="text-center space-y-4 p-6 bg-background/80 backdrop-blur-sm rounded-lg max-w-sm">
              <Camera className="mx-auto h-12 w-12 text-primary" />
              <div>
                <h3 className="text-lg font-semibold text-foreground mb-2">Initializing Camera</h3>
                <p className="text-muted-foreground text-base leading-relaxed">
                  Setting up camera access...
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Camera Guidance Overlay */}
        {cameraState.isInitialized && (
          <>
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
              <div className="text-center space-y-4 p-6 bg-background/80 backdrop-blur-sm rounded-lg max-w-sm">
                <Camera className="mx-auto h-8 w-8 text-primary" />
                <div>
                  <h3 className="text-lg font-semibold text-foreground mb-2">Position Your Camera</h3>
                  <p className="text-muted-foreground text-base leading-relaxed">
                    Hold phone level, about waist-high.<br />
                    Ensure jack and all bowls are visible.
                  </p>
                </div>
              </div>
            </div>

            {/* Corner Guidelines */}
            <div className="absolute top-4 left-4 w-8 h-8 border-l-4 border-t-4 border-primary rounded-tl-lg pointer-events-none"></div>
            <div className="absolute top-4 right-4 w-8 h-8 border-r-4 border-t-4 border-primary rounded-tr-lg pointer-events-none"></div>
            <div className="absolute bottom-4 left-4 w-8 h-8 border-l-4 border-b-4 border-primary rounded-bl-lg pointer-events-none"></div>
            <div className="absolute bottom-4 right-4 w-8 h-8 border-r-4 border-b-4 border-primary rounded-br-lg pointer-events-none"></div>
          </>
        )}
      </div>

      {/* Measurement Controls */}
      <div className="absolute bottom-0 left-0 right-0 bg-background/95 backdrop-blur-sm border-t border-border">
        <div className="px-6 py-6">
          {/* Primary Measure Button */}
          <Button
            onClick={handleMeasure}
            disabled={!cameraState.isInitialized || !openCVState.isLoaded || isCapturing}
            className="w-full bg-primary hover:bg-primary/90 text-primary-foreground font-bold text-2xl py-6 px-8 rounded-lg shadow-lg border-2 border-primary-foreground/20 transition-all duration-200 hover:scale-105 focus:outline-none focus:ring-4 focus:ring-primary/50"
            data-testid="camera-button"
          >
            <Camera className="mr-4 h-6 w-6" />
            {isCapturing ? 'Capturing...' : 'Measure Distance'}
          </Button>

          {/* Secondary Actions */}
          <div className="flex justify-center space-x-4 mt-4">
            <Button
              variant="outline"
              onClick={onEnterManual}
              className="bg-secondary hover:bg-secondary/80 text-secondary-foreground font-medium px-6 py-3 rounded-lg border border-border transition-colors"
              data-testid="manual-button"
            >
              Manual Entry
            </Button>
            <Button
              variant="secondary"
              className="bg-secondary hover:bg-secondary/80 text-secondary-foreground font-medium px-6 py-3 rounded-lg border border-border transition-colors"
              data-testid="settings-button"
            >
              <Settings className="mr-2 h-4 w-4" />
              Settings
            </Button>
            <Button
              variant="secondary"
              className="bg-secondary hover:bg-secondary/80 text-secondary-foreground font-medium px-6 py-3 rounded-lg border border-border transition-colors"
              data-testid="help-button"
            >
              <HelpCircle className="mr-2 h-4 w-4" />
              Help
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

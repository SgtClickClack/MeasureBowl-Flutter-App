import { useState } from 'react';
import { AlertTriangle, X, HelpCircle, Hand, CheckCircle, Clock } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface FallbackViewProps {
  imageData: string;
  onCancel: () => void;
  onManualComplete: (jackPosition: { x: number; y: number }, bowlPositions: Array<{ x: number; y: number; color: string }>) => void;
}

export function FallbackView({ imageData, onCancel, onManualComplete }: FallbackViewProps) {
  const [step, setStep] = useState<'jack' | 'bowls'>('jack');
  const [jackPosition, setJackPosition] = useState<{ x: number; y: number } | null>(null);
  const [bowlPositions, setBowlPositions] = useState<Array<{ x: number; y: number; color: string }>>([]);
  const [selectedColor, setSelectedColor] = useState('Yellow');

  const handleImageClick = (event: React.MouseEvent<HTMLImageElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * 800; // Scale to SVG viewBox
    const y = ((event.clientY - rect.top) / rect.height) * 600;

    if (step === 'jack') {
      setJackPosition({ x, y });
      setStep('bowls');
    } else {
      setBowlPositions(prev => [...prev, { x, y, color: selectedColor }]);
    }
  };

  const handleComplete = () => {
    if (jackPosition && bowlPositions.length > 0) {
      onManualComplete(jackPosition, bowlPositions);
    }
  };

  const colors = ['Yellow', 'Red', 'Black', 'Green', 'Blue'];

  return (
    <div className="flex-1 bg-background">
      {/* Fallback Header */}
      <div className="bg-warning/10 border-b border-warning/30">
        <div className="px-6 py-4">
          <div className="flex items-center space-x-3">
            <AlertTriangle className="text-warning text-xl" />
            <div>
              <h2 className="text-lg font-semibold text-foreground">Manual Identification</h2>
              <p className="text-sm text-muted-foreground">
                Couldn't find the bowls automatically. Please tap to identify them.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Captured Image for Manual Identification */}
      <div className="relative bg-secondary m-4 rounded-lg overflow-hidden border border-border">
        <div className="relative">
          <img 
            src={imageData} 
            alt="Image for manual bowl identification" 
            className="w-full h-auto cursor-crosshair"
            onClick={handleImageClick}
            data-testid="manual-identification-image"
          />
          
          {/* Manual Selection Overlay */}
          <div className="absolute inset-0 measuring-overlay pointer-events-none">
            <div className="absolute top-4 left-4 right-4">
              <div className="bg-background/90 backdrop-blur-sm rounded-lg p-4 border border-border">
                <div className="text-center">
                  <div className="text-lg font-semibold text-foreground mb-2">
                    {step === 'jack' ? 'Step 1: Tap the Jack' : 'Step 2: Tap the Bowls'}
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {step === 'jack' 
                      ? 'Tap the white ball (jack) first' 
                      : `Tap each bowl. Current color: ${selectedColor}`
                    }
                  </div>
                </div>
              </div>
            </div>
            
            {/* Tap indicator animation */}
            {step === 'jack' && !jackPosition && (
              <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
                <div className="w-16 h-16 bg-primary/30 rounded-full flex items-center justify-center pulse-ring">
                  <Hand className="text-primary text-2xl" />
                </div>
              </div>
            )}
          </div>

          {/* Show selected positions */}
          <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 800 600">
            {/* Jack position */}
            {jackPosition && (
              <circle 
                cx={jackPosition.x} 
                cy={jackPosition.y} 
                r="15"
                fill="hsl(0, 0%, 100%)" 
                stroke="hsl(217, 91%, 60%)" 
                strokeWidth="3"
              />
            )}
            
            {/* Bowl positions */}
            {bowlPositions.map((bowl, index) => (
              <circle 
                key={index}
                cx={bowl.x} 
                cy={bowl.y} 
                r="20"
                fill={`hsl(${index * 60}, 70%, 50%)`}
                stroke="hsl(0, 0%, 100%)" 
                strokeWidth="2"
              />
            ))}
          </svg>
        </div>
      </div>

      {/* Color Selection for Bowls */}
      {step === 'bowls' && (
        <div className="px-6 py-4 bg-card border-t border-border">
          <div className="mb-4">
            <label className="text-sm font-medium text-foreground mb-2 block">
              Select bowl color:
            </label>
            <div className="flex space-x-2">
              {colors.map((color) => (
                <button
                  key={color}
                  onClick={() => setSelectedColor(color)}
                  className={`px-3 py-2 rounded text-sm font-medium transition-colors ${
                    selectedColor === color
                      ? 'bg-primary text-primary-foreground'
                      : 'bg-secondary text-secondary-foreground hover:bg-secondary/80'
                  }`}
                  data-testid={`color-${color.toLowerCase()}`}
                >
                  {color}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Manual Identification Progress */}
      <div className="px-6 py-4 bg-card border-t border-border">
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="font-medium text-foreground">Jack</span>
            <div className="flex items-center space-x-2">
              {jackPosition ? (
                <CheckCircle className="w-4 h-4 text-success" />
              ) : (
                <>
                  <Clock className="w-4 h-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Tap to identify</span>
                </>
              )}
            </div>
          </div>
          
          <div className="flex items-center justify-between">
            <span className="font-medium text-foreground">Bowls</span>
            <div className="flex items-center space-x-2">
              <span className="text-sm text-muted-foreground">
                {bowlPositions.length} identified
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Manual Mode Actions */}
      <div className="px-6 py-6 bg-background border-t border-border">
        <div className="space-y-4">
          {jackPosition && bowlPositions.length > 0 && (
            <Button
              onClick={handleComplete}
              className="w-full bg-accent hover:bg-accent/90 text-accent-foreground font-bold py-4 px-6 rounded-lg transition-colors"
              data-testid="complete-manual-identification"
            >
              Complete Identification
            </Button>
          )}
          
          <Button
            onClick={onCancel}
            variant="destructive"
            className="w-full bg-destructive hover:bg-destructive/90 text-destructive-foreground font-medium py-4 px-6 rounded-lg transition-colors"
            data-testid="cancel-manual-identification"
          >
            <X className="mr-2 h-4 w-4" />
            Cancel & Retry
          </Button>
          
          <Button
            variant="secondary"
            className="w-full bg-secondary hover:bg-secondary/80 text-secondary-foreground font-medium py-3 px-6 rounded-lg border border-border transition-colors"
            data-testid="manual-help-button"
          >
            <HelpCircle className="mr-2 h-4 w-4" />
            Need Help?
          </Button>
        </div>
      </div>
    </div>
  );
}

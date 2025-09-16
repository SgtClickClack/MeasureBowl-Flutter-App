import { Camera, Share, Save, CheckCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { MeasurementData } from '@/types/measurement';

interface ResultsViewProps {
  measurementData: MeasurementData;
  onMeasureAgain: () => void;
}

export function ResultsView({ measurementData, onMeasureAgain }: ResultsViewProps) {
  const { imageData, jackPosition, bowls } = measurementData;

  const handleShare = () => {
    if (navigator.share) {
      navigator.share({
        title: 'Bowls Measurement Results',
        text: `Measurement results: ${bowls.map(b => `${b.color}: ${b.distanceFromJack}cm`).join(', ')}`,
      }).catch(console.error);
    } else {
      // Fallback for browsers without native sharing
      navigator.clipboard.writeText(
        `Bowls Measurement Results:\n${bowls.map(b => `${b.color} Bowl: ${b.distanceFromJack}cm`).join('\n')}`
      );
      alert('Results copied to clipboard!');
    }
  };

  const handleSave = () => {
    // Create a download link for the annotated image
    const link = document.createElement('a');
    link.download = `bowls-measurement-${Date.now()}.jpg`;
    link.href = imageData;
    link.click();
  };

  const getBowlColor = (color: string) => {
    const colorMap: Record<string, string> = {
      'Yellow': 'bg-yellow-500',
      'Red': 'bg-red-500',
      'Black': 'bg-gray-800',
      'Green': 'bg-green-500',
      'Blue': 'bg-blue-500',
      'Unknown': 'bg-gray-500',
    };
    return colorMap[color] || 'bg-gray-500';
  };

  const getRankStyle = (rank: number) => {
    if (rank === 1) return 'bg-accent/10 border-accent/30';
    return 'bg-secondary border-border';
  };

  return (
    <div className="flex-1 bg-background">
      {/* Results Header */}
      <div className="bg-card border-b border-border">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-foreground">Measurement Results</h2>
            <div className="flex items-center space-x-2 text-success">
              <CheckCircle className="h-5 w-5" />
              <span className="font-medium">Complete</span>
            </div>
          </div>
        </div>
      </div>

      {/* Captured Image with Overlays */}
      <div className="relative bg-secondary m-4 rounded-lg overflow-hidden border border-border">
        <div className="relative">
          <img 
            src={imageData} 
            alt="Captured bowls measurement" 
            className="w-full h-auto"
            data-testid="measurement-image"
          />
          
          {/* SVG Overlay for Measurement Lines */}
          <svg 
            className="absolute inset-0 w-full h-full" 
            viewBox={`0 0 ${800} ${600}`}
            preserveAspectRatio="none"
          >
            {/* Jack circle */}
            <circle 
              cx={jackPosition.x} 
              cy={jackPosition.y} 
              r={jackPosition.radius}
              fill="hsl(0, 0%, 100%)" 
              stroke="hsl(217, 91%, 60%)" 
              strokeWidth="3"
            />
            
            {/* Bowl circles and measurement lines */}
            {bowls.map((bowl, index) => (
              <g key={bowl.id}>
                {/* Measurement line */}
                <line 
                  x1={jackPosition.x} 
                  y1={jackPosition.y} 
                  x2={bowl.position.x} 
                  y2={bowl.position.y} 
                  className="measurement-line"
                />
                
                {/* Bowl circle */}
                <circle 
                  cx={bowl.position.x} 
                  cy={bowl.position.y} 
                  r={bowl.position.radius}
                  fill={`hsl(${index * 60}, 70%, 50%)`}
                  stroke="hsl(0, 0%, 100%)" 
                  strokeWidth="2"
                />
                
                {/* Distance label */}
                <foreignObject 
                  x={bowl.position.x - 40} 
                  y={bowl.position.y - bowl.position.radius - 35} 
                  width="80" 
                  height="30"
                >
                  <div className="bg-warning text-background px-2 py-1 rounded text-sm font-bold text-center">
                    {bowl.distanceFromJack} cm
                  </div>
                </foreignObject>
              </g>
            ))}
          </svg>
        </div>
      </div>

      {/* Results Summary */}
      <div className="px-6 py-4 bg-card border-t border-border">
        <h3 className="text-lg font-semibold text-foreground mb-4">Distance Rankings</h3>
        
        <div className="space-y-3">
          {bowls.map((bowl) => (
            <div 
              key={bowl.id}
              className={`flex items-center justify-between p-4 border rounded-lg fade-in ${getRankStyle(bowl.rank)}`}
              data-testid={`result-bowl-${bowl.id}`}
            >
              <div className="flex items-center space-x-4">
                <div className={`w-4 h-4 rounded-full ${getBowlColor(bowl.color)}`}></div>
                <span className="text-lg font-medium text-foreground">{bowl.color} Bowl</span>
              </div>
              <div className="text-right">
                <div className={`text-2xl font-bold ${bowl.rank === 1 ? 'text-accent' : 'text-foreground'}`}>
                  {bowl.distanceFromJack} cm
                </div>
                <div className="text-sm text-muted-foreground">
                  {bowl.rank === 1 ? 'Closest' : `${bowl.rank}${bowl.rank === 2 ? 'nd' : bowl.rank === 3 ? 'rd' : 'th'} Place`}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Action Buttons */}
      <div className="px-6 py-6 bg-background border-t border-border">
        <div className="space-y-4">
          <Button
            onClick={onMeasureAgain}
            className="w-full bg-primary hover:bg-primary/90 text-primary-foreground font-bold text-xl py-5 px-6 rounded-lg shadow-lg transition-all duration-200 hover:scale-105 focus:outline-none focus:ring-4 focus:ring-primary/50"
            data-testid="measure-again-button"
          >
            <Camera className="mr-3 h-6 w-6" />
            Measure Again
          </Button>
          
          <div className="flex space-x-4">
            <Button
              onClick={handleShare}
              variant="secondary"
              className="flex-1 bg-secondary hover:bg-secondary/80 text-secondary-foreground font-medium py-4 px-4 rounded-lg border border-border transition-colors"
              data-testid="share-button"
            >
              <Share className="mr-2 h-4 w-4" />
              Share Results
            </Button>
            <Button
              onClick={handleSave}
              variant="secondary"
              className="flex-1 bg-secondary hover:bg-secondary/80 text-secondary-foreground font-medium py-4 px-4 rounded-lg border border-border transition-colors"
              data-testid="save-button"
            >
              <Save className="mr-2 h-4 w-4" />
              Save Image
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

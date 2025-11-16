import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Download, Search, Filter } from 'lucide-react';

interface Measurement {
  id: string;
  timestamp: string;
  bowlCount: number;
  imageData: string;
  jackPosition: string;
  bowls: Array<{
    color: string;
    position: string;
    distanceFromJack: number;
    rank: number;
  }>;
}

export default function History() {
  const [searchTerm, setSearchTerm] = useState('');
  const [filterDate, setFilterDate] = useState('');
  const [showExportOptions, setShowExportOptions] = useState(false);
  const [exportFormat, setExportFormat] = useState('csv');

  // Mock data for now
  const measurements: Measurement[] = [
    {
      id: 'mock-1',
      timestamp: '2024-01-15T10:30:00Z',
      bowlCount: 4,
      imageData: 'mock-image-data-1',
      jackPosition: 'center',
      bowls: [
        { color: 'black', position: 'top-left', distanceFromJack: 15.5, rank: 1 },
        { color: 'brown', position: 'top-right', distanceFromJack: 22.3, rank: 2 }
      ]
    },
    {
      id: 'mock-2',
      timestamp: '2024-01-16T14:20:00Z',
      bowlCount: 6,
      imageData: 'mock-image-data-2',
      jackPosition: 'left',
      bowls: [
        { color: 'blue', position: 'center', distanceFromJack: 8.7, rank: 1 }
      ]
    }
  ];

  const filteredMeasurements = measurements.filter((measurement: Measurement) => {
    const matchesSearch = measurement.id.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesDate = !filterDate || measurement.timestamp.startsWith(filterDate);
    return matchesSearch && matchesDate;
  });

  const handleExport = () => {
    if (exportFormat === 'csv') {
      const csvContent = [
        ['ID', 'Date', 'Bowl Count', 'Closest Distance', 'Furthest Distance'].join(','),
        ...filteredMeasurements.map(m => [
          m.id,
          new Date(m.timestamp).toLocaleDateString(),
          m.bowlCount.toString(),
          Math.min(...m.bowls.map(b => b.distanceFromJack)).toString(),
          Math.max(...m.bowls.map(b => b.distanceFromJack)).toString()
        ].join(','))
      ].join('\n');

      const blob = new Blob([csvContent], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `measurements-${new Date().toISOString().split('T')[0]}.csv`;
      a.click();
      window.URL.revokeObjectURL(url);
    } else if (exportFormat === 'json') {
      const jsonContent = JSON.stringify(filteredMeasurements, null, 2);
      const blob = new Blob([jsonContent], { type: 'application/json' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `measurements-${new Date().toISOString().split('T')[0]}.json`;
      a.click();
      window.URL.revokeObjectURL(url);
    }
    setShowExportOptions(false);
  };

  return (
    <div data-testid="history-page" className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Measurement History</h1>
        <p className="text-muted-foreground">
          View and manage your lawn bowls measurements
        </p>
      </div>

      {/* Search and Filter Controls */}
      <div data-testid="filter-controls" className="mb-6 flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
          <Input
            data-testid="search-input"
            placeholder="Search measurements..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <div className="flex gap-2">
          <Input
            type="date"
            value={filterDate}
            onChange={(e) => setFilterDate(e.target.value)}
            className="w-auto"
          />
          <Button
            variant="outline"
            onClick={() => {
              setSearchTerm('');
              setFilterDate('');
            }}
            className="flex items-center gap-2"
          >
            <Filter className="h-4 w-4" />
            Clear
          </Button>
        </div>
      </div>

      {/* Export Button */}
      <div className="mb-6 flex justify-end">
        <Button
          data-testid="export-button"
          onClick={() => setShowExportOptions(true)}
          className="flex items-center gap-2"
        >
          <Download className="h-4 w-4" />
          Export Data
        </Button>
      </div>

      {/* Export Options Modal */}
      {showExportOptions && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <Card className="w-full max-w-md">
            <CardHeader>
              <CardTitle>Export Measurements</CardTitle>
              <CardDescription>
                Choose the format for your measurement data
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <label className="flex items-center space-x-2">
                  <input
                    type="radio"
                    value="csv"
                    checked={exportFormat === 'csv'}
                    onChange={(e) => setExportFormat(e.target.value)}
                  />
                  <span>CSV (Spreadsheet)</span>
                </label>
                <label className="flex items-center space-x-2">
                  <input
                    type="radio"
                    value="json"
                    checked={exportFormat === 'json'}
                    onChange={(e) => setExportFormat(e.target.value)}
                  />
                  <span>JSON (Data)</span>
                </label>
              </div>
              <div className="flex gap-2">
                <Button onClick={handleExport} className="flex-1">
                  Export
                </Button>
                <Button variant="outline" onClick={() => setShowExportOptions(false)}>
                  Cancel
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Measurements List */}
      <div data-testid="measurements-list" className="space-y-4">
        {filteredMeasurements.length === 0 ? (
          <Card>
            <CardContent className="flex items-center justify-center h-32">
              <div className="text-center">
                <p className="text-muted-foreground mb-2">No measurements found</p>
                <p className="text-sm text-muted-foreground">
                  Try adjusting your search or filter criteria
                </p>
              </div>
            </CardContent>
          </Card>
        ) : (
          filteredMeasurements.map((measurement) => (
            <Card key={measurement.id} className="hover:shadow-md transition-shadow">
              <CardHeader>
                <div className="flex justify-between items-start">
                  <div>
                    <CardTitle className="text-lg">Measurement {measurement.id}</CardTitle>
                    <CardDescription>
                      {new Date(measurement.timestamp).toLocaleString()}
                    </CardDescription>
                  </div>
                  <div className="text-right">
                    <div className="text-sm text-muted-foreground">
                      {measurement.bowlCount} bowls
                    </div>
                    <div className="text-sm text-muted-foreground">
                      Jack: {measurement.jackPosition}
                    </div>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {measurement.bowls.map((bowl, index) => (
                    <div key={index} className="flex justify-between items-center text-sm">
                      <span className="capitalize">{bowl.color} bowl</span>
                      <span className="text-muted-foreground">
                        {bowl.distanceFromJack.toFixed(1)}cm (Rank {bowl.rank})
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>
    </div>
  );
}
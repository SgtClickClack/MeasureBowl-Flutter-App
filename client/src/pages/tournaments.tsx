import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Plus, Filter, Search } from 'lucide-react';

export default function Tournaments() {
  const [searchTerm, setSearchTerm] = useState('');

  return (
    <div data-testid="tournaments-page" className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Tournaments</h1>
        <p className="text-muted-foreground">
          Discover and join lawn bowls tournaments in your area
        </p>
      </div>

      {/* Search and Filter Controls */}
      <div data-testid="tournament-filters" className="mb-6 flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
          <Input
            placeholder="Search tournaments..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <Button
          variant="outline"
          onClick={() => setSearchTerm('')}
          className="flex items-center gap-2"
        >
          <Filter className="h-4 w-4" />
          Clear
        </Button>
      </div>

      {/* Create Tournament Button */}
      <div className="mb-6 flex justify-end">
        <Button
          data-testid="create-tournament-button"
          className="flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          Create Tournament
        </Button>
      </div>

      {/* Tournaments List */}
      <div data-testid="tournaments-list" className="space-y-4">
        <Card>
          <CardHeader>
            <CardTitle>Spring Championship</CardTitle>
            <CardDescription>Annual spring tournament for all skill levels</CardDescription>
          </CardHeader>
          <CardContent>
            <p>Mock tournament data</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
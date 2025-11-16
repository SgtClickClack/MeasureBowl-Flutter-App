import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Separator } from '@/components/ui/separator';
import { useToast } from '@/hooks/use-toast';
import { apiRequest } from '@/lib/queryClient';
import { Save, RotateCcw, User, Bell, Camera, Globe } from 'lucide-react';

interface Settings {
  id: string;
  user: {
    name: string;
    email: string;
    phone: string;
  };
  notifications: {
    email: boolean;
    push: boolean;
    measurementReminders: boolean;
    tournamentUpdates: boolean;
  };
  measurement: {
    defaultUnit: 'cm' | 'mm' | 'inches';
    autoSave: boolean;
    highAccuracy: boolean;
    showGrid: boolean;
  };
  privacy: {
    shareData: boolean;
    analytics: boolean;
    locationServices: boolean;
  };
}

export default function Settings() {
  const [formData, setFormData] = useState<Partial<Settings>>({});
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: settings, isLoading } = useQuery({
    queryKey: ['/api/settings'],
    queryFn: () => apiRequest('GET', '/api/settings'),
  });

  const saveMutation = useMutation({
    mutationFn: (data: Partial<Settings>) => apiRequest('PUT', '/api/settings', data),
    onSuccess: () => {
      toast({
        title: "Settings Saved",
        description: "Your settings have been updated successfully.",
        variant: "default",
      });
      queryClient.invalidateQueries({ queryKey: ['/api/settings'] });
    },
    onError: () => {
      toast({
        title: "Save Failed",
        description: "Could not save settings. Please try again.",
        variant: "destructive",
      });
    },
  });

  const resetMutation = useMutation({
    mutationFn: () => apiRequest('POST', '/api/settings/reset'),
    onSuccess: () => {
      toast({
        title: "Settings Reset",
        description: "Your settings have been reset to defaults.",
        variant: "default",
      });
      queryClient.invalidateQueries({ queryKey: ['/api/settings'] });
    },
    onError: () => {
      toast({
        title: "Reset Failed",
        description: "Could not reset settings. Please try again.",
        variant: "destructive",
      });
    },
  });

  const handleSave = () => {
    saveMutation.mutate(formData);
  };

  const handleReset = () => {
    resetMutation.mutate();
  };

  const updateFormData = (section: string, field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [section]: {
        ...prev[section as keyof Settings],
        [field]: value
      }
    }));
  };

  if (isLoading) {
    return (
      <div data-testid="settings-page" className="container mx-auto px-4 py-8">
        <div className="flex items-center justify-center h-64">
          <div className="text-lg">Loading settings...</div>
        </div>
      </div>
    );
  }

  const currentSettings = settings || formData;

  return (
    <div data-testid="settings-page" className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Settings</h1>
        <p className="text-muted-foreground">
          Manage your account preferences and application settings
        </p>
      </div>

      <form data-testid="settings-form" className="space-y-6">
        {/* User Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="h-5 w-5" />
              User Information
            </CardTitle>
            <CardDescription>
              Update your personal information and contact details
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <Label htmlFor="name">Full Name</Label>
                <Input
                  id="name"
                  value={formData.user?.name || currentSettings.user?.name || ''}
                  onChange={(e) => updateFormData('user', 'name', e.target.value)}
                />
              </div>
              <div>
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  value={formData.user?.email || currentSettings.user?.email || ''}
                  onChange={(e) => updateFormData('user', 'email', e.target.value)}
                />
              </div>
              <div>
                <Label htmlFor="phone">Phone</Label>
                <Input
                  id="phone"
                  value={formData.user?.phone || currentSettings.user?.phone || ''}
                  onChange={(e) => updateFormData('user', 'phone', e.target.value)}
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Notifications */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Bell className="h-5 w-5" />
              Notifications
            </CardTitle>
            <CardDescription>
              Configure how you want to receive notifications
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <Label>Email Notifications</Label>
                <p className="text-sm text-muted-foreground">Receive notifications via email</p>
              </div>
              <Switch
                checked={formData.notifications?.email ?? currentSettings.notifications?.email ?? true}
                onCheckedChange={(checked) => updateFormData('notifications', 'email', checked)}
              />
            </div>
            <div className="flex items-center justify-between">
              <div>
                <Label>Push Notifications</Label>
                <p className="text-sm text-muted-foreground">Receive push notifications on your device</p>
              </div>
              <Switch
                checked={formData.notifications?.push ?? currentSettings.notifications?.push ?? true}
                onCheckedChange={(checked) => updateFormData('notifications', 'push', checked)}
              />
            </div>
            <div className="flex items-center justify-between">
              <div>
                <Label>Measurement Reminders</Label>
                <p className="text-sm text-muted-foreground">Get reminded to take measurements</p>
              </div>
              <Switch
                checked={formData.notifications?.measurementReminders ?? currentSettings.notifications?.measurementReminders ?? false}
                onCheckedChange={(checked) => updateFormData('notifications', 'measurementReminders', checked)}
              />
            </div>
            <div className="flex items-center justify-between">
              <div>
                <Label>Tournament Updates</Label>
                <p className="text-sm text-muted-foreground">Receive updates about tournaments</p>
              </div>
              <Switch
                checked={formData.notifications?.tournamentUpdates ?? currentSettings.notifications?.tournamentUpdates ?? true}
                onCheckedChange={(checked) => updateFormData('notifications', 'tournamentUpdates', checked)}
              />
            </div>
          </CardContent>
        </Card>

        {/* Measurement Settings */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Camera className="h-5 w-5" />
              Measurement Settings
            </CardTitle>
            <CardDescription>
              Configure your measurement preferences and accuracy settings
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label htmlFor="unit">Default Unit</Label>
              <Select
                value={formData.measurement?.defaultUnit || currentSettings.measurement?.defaultUnit || 'cm'}
                onValueChange={(value) => updateFormData('measurement', 'defaultUnit', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cm">Centimeters (cm)</SelectItem>
                  <SelectItem value="mm">Millimeters (mm)</SelectItem>
                  <SelectItem value="inches">Inches</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex items-center justify-between">
              <div>
                <Label>Auto Save</Label>
                <p className="text-sm text-muted-foreground">Automatically save measurements</p>
              </div>
              <Switch
                checked={formData.measurement?.autoSave ?? currentSettings.measurement?.autoSave ?? true}
                onCheckedChange={(checked) => updateFormData('measurement', 'autoSave', checked)}
              />
            </div>
            <div className="flex items-center justify-between">
              <div>
                <Label>High Accuracy Mode</Label>
                <p className="text-sm text-muted-foreground">Use enhanced accuracy for measurements</p>
              </div>
              <Switch
                checked={formData.measurement?.highAccuracy ?? currentSettings.measurement?.highAccuracy ?? false}
                onCheckedChange={(checked) => updateFormData('measurement', 'highAccuracy', checked)}
              />
            </div>
            <div className="flex items-center justify-between">
              <div>
                <Label>Show Grid</Label>
                <p className="text-sm text-muted-foreground">Display measurement grid overlay</p>
              </div>
              <Switch
                checked={formData.measurement?.showGrid ?? currentSettings.measurement?.showGrid ?? true}
                onCheckedChange={(checked) => updateFormData('measurement', 'showGrid', checked)}
              />
            </div>
          </CardContent>
        </Card>

        {/* Privacy Settings */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Globe className="h-5 w-5" />
              Privacy & Data
            </CardTitle>
            <CardDescription>
              Manage your privacy settings and data sharing preferences
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <Label>Share Data</Label>
                <p className="text-sm text-muted-foreground">Allow sharing of anonymous measurement data</p>
              </div>
              <Switch
                checked={formData.privacy?.shareData ?? currentSettings.privacy?.shareData ?? false}
                onCheckedChange={(checked) => updateFormData('privacy', 'shareData', checked)}
              />
            </div>
            <div className="flex items-center justify-between">
              <div>
                <Label>Analytics</Label>
                <p className="text-sm text-muted-foreground">Help improve the app with usage analytics</p>
              </div>
              <Switch
                checked={formData.privacy?.analytics ?? currentSettings.privacy?.analytics ?? true}
                onCheckedChange={(checked) => updateFormData('privacy', 'analytics', checked)}
              />
            </div>
            <div className="flex items-center justify-between">
              <div>
                <Label>Location Services</Label>
                <p className="text-sm text-muted-foreground">Use location for nearby tournaments</p>
              </div>
              <Switch
                checked={formData.privacy?.locationServices ?? currentSettings.privacy?.locationServices ?? false}
                onCheckedChange={(checked) => updateFormData('privacy', 'locationServices', checked)}
              />
            </div>
          </CardContent>
        </Card>

        <Separator />

        {/* Action Buttons */}
        <div className="flex justify-between">
          <Button
            data-testid="reset-settings-button"
            type="button"
            variant="outline"
            onClick={handleReset}
            disabled={resetMutation.isPending}
          >
            <RotateCcw className="h-4 w-4 mr-2" />
            Reset to Defaults
          </Button>
          <Button
            data-testid="save-settings-button"
            type="button"
            onClick={handleSave}
            disabled={saveMutation.isPending}
          >
            <Save className="h-4 w-4 mr-2" />
            {saveMutation.isPending ? 'Saving...' : 'Save Settings'}
          </Button>
        </div>
      </form>
    </div>
  );
}

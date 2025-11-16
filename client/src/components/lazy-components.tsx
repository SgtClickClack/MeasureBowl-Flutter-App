import { lazy, Suspense } from 'react';
import { Loader2 } from 'lucide-react';

// Lazy load heavy components
export const CameraView = lazy(() => import('./camera-view').then(module => ({ default: module.CameraView })));
export const ProcessingView = lazy(() => import('./processing-view').then(module => ({ default: module.ProcessingView })));
export const ResultsView = lazy(() => import('./results-view').then(module => ({ default: module.ResultsView })));
export const FallbackView = lazy(() => import('./fallback-view').then(module => ({ default: module.FallbackView })));

// Loading component
export function LoadingSpinner() {
  return (
    <div className="flex items-center justify-center min-h-screen bg-background">
      <div className="text-center space-y-4">
        <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
        <p className="text-muted-foreground">Loading...</p>
      </div>
    </div>
  );
}

// HOC for lazy loading with suspense
export function withLazyLoading<T extends object>(Component: React.ComponentType<T>) {
  return function LazyComponent(props: T) {
    return (
      <Suspense fallback={<LoadingSpinner />}>
        <Component {...props} />
      </Suspense>
    );
  };
}

// Lazy loaded page components
export const LazyHomePage = lazy(() => import('../pages/home'));
export const LazyMeasurePage = lazy(() => import('../pages/measure'));
export const LazyHistoryPage = lazy(() => import('../pages/history'));
export const LazyTournamentsPage = lazy(() => import('../pages/tournaments'));
export const LazySettingsPage = lazy(() => import('../pages/settings'));
export const LazyHelpPage = lazy(() => import('../pages/help'));

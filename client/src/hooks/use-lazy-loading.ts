import { useState, useEffect, useCallback } from 'react';

interface LazyLoadingOptions {
  threshold?: number;
  rootMargin?: string;
  enabled?: boolean;
}

export function useLazyLoading<T extends HTMLElement>(
  options: LazyLoadingOptions = {}
) {
  const {
    threshold = 0.1,
    rootMargin = '50px',
    enabled = true
  } = options;

  const [isVisible, setIsVisible] = useState(false);
  const [elementRef, setElementRef] = useState<T | null>(null);

  const callback = useCallback((entries: IntersectionObserverEntry[]) => {
    const [entry] = entries;
    if (entry.isIntersecting) {
      setIsVisible(true);
    }
  }, []);

  useEffect(() => {
    if (!enabled || !elementRef) return;

    const observer = new IntersectionObserver(callback, {
      threshold,
      rootMargin,
    });

    observer.observe(elementRef);

    return () => {
      observer.disconnect();
    };
  }, [elementRef, callback, threshold, rootMargin, enabled]);

  return {
    ref: setElementRef,
    isVisible,
  };
}

// Hook for preloading components
export function usePreload() {
  const [preloadedComponents, setPreloadedComponents] = useState<Set<string>>(new Set());

  const preloadComponent = useCallback(async (componentName: string, importFn: () => Promise<any>) => {
    if (preloadedComponents.has(componentName)) {
      return;
    }

    try {
      await importFn();
      setPreloadedComponents(prev => new Set([...prev, componentName]));
    } catch (error) {
      console.error(`Failed to preload component ${componentName}:`, error);
    }
  }, [preloadedComponents]);

  const preloadOnHover = useCallback((componentName: string, importFn: () => Promise<any>) => {
    return {
      onMouseEnter: () => preloadComponent(componentName, importFn),
      onFocus: () => preloadComponent(componentName, importFn),
    };
  }, [preloadComponent]);

  return {
    preloadComponent,
    preloadOnHover,
    preloadedComponents,
  };
}

// Hook for image lazy loading
export function useImageLazyLoading(src: string, placeholder?: string) {
  const [imageSrc, setImageSrc] = useState(placeholder || '');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!src) return;

    const img = new Image();
    
    img.onload = () => {
      setImageSrc(src);
      setIsLoading(false);
      setError(null);
    };

    img.onerror = () => {
      setError('Failed to load image');
      setIsLoading(false);
    };

    img.src = src;

    return () => {
      img.onload = null;
      img.onerror = null;
    };
  }, [src]);

  return {
    src: imageSrc,
    isLoading,
    error,
  };
}

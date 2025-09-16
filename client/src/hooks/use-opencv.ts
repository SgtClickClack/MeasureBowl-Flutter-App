import { useState, useEffect } from 'react';
import { OpenCVState } from '@/types/measurement';

declare global {
  interface Window {
    cv: any;
  }
}

export function useOpenCV() {
  const [openCVState, setOpenCVState] = useState<OpenCVState>({
    isLoaded: false,
    isProcessing: false,
    error: null,
  });

  useEffect(() => {
    const loadOpenCV = () => {
      if (window.cv && window.cv.Mat) {
        setOpenCVState(prev => ({ ...prev, isLoaded: true }));
        return;
      }

      const script = document.createElement('script');
      script.src = 'https://docs.opencv.org/4.8.0/opencv.js';
      script.async = true;
      
      script.onload = () => {
        if (window.cv) {
          window.cv.onRuntimeInitialized = () => {
            setOpenCVState(prev => ({ ...prev, isLoaded: true }));
          };
        }
      };

      script.onerror = () => {
        setOpenCVState(prev => ({
          ...prev,
          error: 'Failed to load OpenCV.js',
        }));
      };

      document.head.appendChild(script);
    };

    loadOpenCV();
  }, []);

  const setProcessing = (isProcessing: boolean) => {
    setOpenCVState(prev => ({ ...prev, isProcessing }));
  };

  const setError = (error: string | null) => {
    setOpenCVState(prev => ({ ...prev, error }));
  };

  return {
    openCVState,
    setProcessing,
    setError,
  };
}

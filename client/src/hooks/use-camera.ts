import { useState, useEffect, useRef } from 'react';
import { CameraState } from '@/types/measurement';

export function useCamera() {
  const [cameraState, setCameraState] = useState<CameraState>({
    isInitialized: false,
    hasPermission: false,
    error: null,
    stream: null,
  });

  const videoRef = useRef<HTMLVideoElement>(null);

  const initializeCamera = async () => {
    try {
      setCameraState(prev => ({ ...prev, error: null }));
      
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: 'environment', // Use back camera on mobile
          width: { ideal: 1920 },
          height: { ideal: 1080 }
        }
      });

      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }

      setCameraState({
        isInitialized: true,
        hasPermission: true,
        error: null,
        stream,
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to access camera';
      setCameraState(prev => ({
        ...prev,
        error: errorMessage,
        hasPermission: false,
      }));
    }
  };

  const captureImage = (): string | null => {
    if (!videoRef.current || !cameraState.stream) {
      return null;
    }

    const canvas = document.createElement('canvas');
    const video = videoRef.current;
    
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    
    const ctx = canvas.getContext('2d');
    if (!ctx) return null;
    
    ctx.drawImage(video, 0, 0);
    return canvas.toDataURL('image/jpeg', 0.8);
  };

  const stopCamera = () => {
    if (cameraState.stream) {
      cameraState.stream.getTracks().forEach(track => track.stop());
      setCameraState({
        isInitialized: false,
        hasPermission: false,
        error: null,
        stream: null,
      });
    }
  };

  useEffect(() => {
    return () => {
      stopCamera();
    };
  }, []);

  return {
    cameraState,
    videoRef,
    initializeCamera,
    captureImage,
    stopCamera,
  };
}

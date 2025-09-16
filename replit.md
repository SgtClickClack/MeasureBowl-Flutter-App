# One-Shot Bowls Measure

## Overview

This is a lawn bowls measuring application designed to provide instant, accurate measurements between bowls and the jack using computer vision. The app follows a "one-shot" approach where users simply point their camera at the bowls, press a single button, and receive immediate distance measurements. The application is built as a full-stack web app with a React frontend and Express backend, targeting mobile users with an emphasis on simplicity and accessibility for elderly players.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
The client is built using React with TypeScript and follows a component-based architecture:

- **UI Framework**: React with Vite for fast development and building
- **Styling**: Tailwind CSS with shadcn/ui component library for consistent, accessible UI components
- **State Management**: React Query (@tanstack/react-query) for server state management and local React state for UI state
- **Routing**: Wouter for lightweight client-side routing
- **Computer Vision**: OpenCV.js integration for image processing and bowl detection
- **Camera Integration**: Native browser MediaDevices API for camera access

### Backend Architecture
The server follows a simple Express.js REST API pattern:

- **Framework**: Express.js with TypeScript for type safety
- **Data Storage**: In-memory storage (MemStorage class) implementing an IStorage interface for easy database migration
- **API Design**: RESTful endpoints for measurement operations (/api/measurements)
- **Development**: Vite integration for hot module replacement and development tooling

### Core Application Flow
The app implements a multi-view state machine with these primary views:
1. **Camera View**: Live camera feed with measurement button
2. **Processing View**: Computer vision processing with progress indicators
3. **Results View**: Annotated image with distance measurements and rankings
4. **Fallback View**: Manual object identification if automatic detection fails

### Data Models
The application uses a shared schema system with:
- **Measurements**: Store image data, timestamp, jack position, and bowl count
- **Bowl Measurements**: Individual bowl data including position, color, distance from jack, and ranking
- **Type Safety**: Zod schemas for runtime validation and TypeScript types

### Computer Vision Processing
The core measurement functionality relies on:
- **Circle Detection**: Hough Circle Transform for identifying jack and bowls
- **Perspective Correction**: Using the jack as a reference object for accurate distance calculation
- **Fallback Strategy**: Manual identification interface when automatic detection fails

### Database Design
Currently uses in-memory storage with a clean interface (IStorage) that can be easily migrated to PostgreSQL using Drizzle ORM. The schema is already defined for PostgreSQL with proper UUID primary keys and foreign key relationships.

## External Dependencies

### UI and Styling
- **shadcn/ui**: Complete UI component library built on Radix UI primitives
- **Tailwind CSS**: Utility-first CSS framework for styling
- **Radix UI**: Accessible, unstyled UI primitives for complex components
- **Lucide React**: Icon library for consistent iconography

### Computer Vision
- **OpenCV.js**: Browser-based computer vision library for image processing and object detection
- **Canvas API**: For image manipulation and rendering measurement annotations

### Development and Build Tools
- **Vite**: Fast build tool and development server
- **TypeScript**: Type safety across the entire application
- **Replit Plugins**: Development environment integration for runtime error handling and debugging

### Data and Validation
- **Drizzle ORM**: Type-safe database ORM (configured but not yet connected)
- **Zod**: Schema validation for API requests and responses
- **React Query**: Server state management and caching

### Camera and Media
- **MediaDevices API**: Native browser API for camera access
- **Canvas API**: Image capture and processing

### Potential Future Integrations
- **PostgreSQL with Neon**: Cloud database for persistent storage (Drizzle config already prepared)
- **PWA capabilities**: For mobile app-like experience
- **Image storage service**: For persistent image storage beyond base64 encoding
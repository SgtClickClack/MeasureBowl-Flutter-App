function App() {
  return (
    <div className="min-h-screen bg-background">
      <nav data-testid="navbar" className="bg-background border-b border-border">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center space-x-8">
              <div className="flex-shrink-0">
                <a href="/" className="text-xl font-bold text-foreground">
                  MeasureBowl
                </a>
              </div>
              <div className="flex space-x-4">
                <a
                  data-testid="navbar-link-home"
                  href="/"
                  className="flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium transition-colors bg-primary text-primary-foreground"
                >
                  Home
                </a>
                <a
                  data-testid="navbar-link-measure"
                  href="/measure"
                  className="flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium transition-colors text-foreground hover:bg-accent hover:text-accent-foreground"
                >
                  Measure
                </a>
                <a
                  data-testid="navbar-link-history"
                  href="/history"
                  className="flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium transition-colors text-foreground hover:bg-accent hover:text-accent-foreground"
                >
                  History
                </a>
                <a
                  data-testid="navbar-link-tournaments"
                  href="/tournaments"
                  className="flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium transition-colors text-foreground hover:bg-accent hover:text-accent-foreground"
                >
                  Tournaments
                </a>
                <a
                  data-testid="navbar-link-settings"
                  href="/settings"
                  className="flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium transition-colors text-foreground hover:bg-accent hover:text-accent-foreground"
                >
                  Settings
                </a>
                <a
                  data-testid="navbar-link-help"
                  href="/help"
                  className="flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium transition-colors text-foreground hover:bg-accent hover:text-accent-foreground"
                >
                  Help
                </a>
              </div>
            </div>
          </div>
        </div>
      </nav>
      <main>
        <div data-testid="home-page" className="container mx-auto px-4 py-8">
          <h1 className="text-3xl font-bold mb-2">Welcome to MeasureBowl</h1>
          <p className="text-muted-foreground">
            Your lawn bowls measurement companion
          </p>
        </div>
      </main>
    </div>
  );
}

export default App;
import { Link, useLocation } from 'wouter';
import { useState } from 'react';
import { Menu, X, Camera, History, Trophy, Settings, HelpCircle, Home, LogIn, LogOut } from 'lucide-react';

const navigationItems = [
  { testId: 'navbar-link-home', href: '/', label: 'Home', icon: Home },
  { testId: 'navbar-link-measure', href: '/measure', label: 'Measure', icon: Camera },
  { testId: 'navbar-link-history', href: '/history', label: 'History', icon: History },
  { testId: 'navbar-link-tournaments', href: '/tournaments', label: 'Tournaments', icon: Trophy },
  { testId: 'navbar-link-settings', href: '/settings', label: 'Settings', icon: Settings },
  { testId: 'navbar-link-help', href: '/help', label: 'Help', icon: HelpCircle },
];

export function Navbar() {
  const [location] = useLocation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  const handleLogin = () => {
    setIsAuthenticated(true);
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
  };

  return (
    <nav data-testid="navbar" className="bg-background border-b border-border">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          {/* Desktop Navigation */}
          <div data-testid="desktop-navbar" className="hidden md:flex items-center space-x-8">
            <div className="flex-shrink-0">
              <Link href="/" className="text-xl font-bold text-foreground">
                MeasureBowl
              </Link>
            </div>
            <div className="flex space-x-4">
              {navigationItems.map((item) => {
                const Icon = item.icon;
                const isActive = location === item.href;
                return (
                  <Link key={item.href} href={item.href}>
                    <a
                      data-testid={item.testId}
                      href={item.href}
                      className={`flex items-center space-x-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                        isActive 
                          ? "bg-primary text-primary-foreground" 
                          : "text-foreground hover:bg-accent hover:text-accent-foreground"
                      }`}
                    >
                      <Icon className="h-4 w-4" />
                      <span>{item.label}</span>
                    </a>
                  </Link>
                );
              })}
            </div>
            
            {/* Authentication buttons */}
            <div className="flex items-center space-x-2">
              {isAuthenticated ? (
                <button
                  data-testid="logout-button"
                  onClick={handleLogout}
                  className="flex items-center gap-2 px-4 py-2 border border-border rounded-md hover:bg-accent"
                >
                  <LogOut className="h-4 w-4" />
                  Logout
                </button>
              ) : (
                <button
                  data-testid="login-button"
                  onClick={handleLogin}
                  className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
                >
                  <LogIn className="h-4 w-4" />
                  Login
                </button>
              )}
            </div>
          </div>

          {/* Mobile Navigation */}
          <div className="md:hidden flex items-center">
            <div className="flex-shrink-0">
              <Link href="/" className="text-lg font-bold text-foreground">
                MeasureBowl
              </Link>
            </div>
            <div className="ml-auto">
              <button
                data-testid="mobile-menu-button"
                onClick={toggleMobileMenu}
                className="p-2 hover:bg-accent rounded-md"
              >
                {isMobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
              </button>
            </div>
          </div>
        </div>

        {/* Mobile Menu */}
        {isMobileMenuOpen && (
          <div
            data-testid="mobile-menu"
            className="md:hidden absolute top-16 left-0 right-0 bg-background border-b border-border shadow-lg z-50"
          >
            <div className="px-2 pt-2 pb-3 space-y-1">
              {navigationItems.map((item) => {
                const Icon = item.icon;
                const isActive = location === item.href;
                return (
                  <Link key={item.href} href={item.href}>
                    <a
                      data-testid={item.testId}
                      href={item.href}
                      className={`w-full justify-start flex items-center space-x-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                        isActive 
                          ? "bg-primary text-primary-foreground" 
                          : "text-foreground hover:bg-accent hover:text-accent-foreground"
                      }`}
                      onClick={() => setIsMobileMenuOpen(false)}
                    >
                      <Icon className="h-4 w-4" />
                      <span>{item.label}</span>
                    </a>
                  </Link>
                );
              })}
              
              {/* Mobile authentication buttons */}
              <div className="px-2 pt-2 border-t border-border">
                {isAuthenticated ? (
                  <button
                    data-testid="logout-button"
                    onClick={handleLogout}
                    className="w-full flex items-center gap-2 px-4 py-2 border border-border rounded-md hover:bg-accent"
                  >
                    <LogOut className="h-4 w-4" />
                    Logout
                  </button>
                ) : (
                  <button
                    data-testid="login-button"
                    onClick={handleLogin}
                    className="w-full flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
                  >
                    <LogIn className="h-4 w-4" />
                    Login
                  </button>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}
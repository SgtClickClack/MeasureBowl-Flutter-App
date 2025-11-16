import { test, expect } from '@playwright/test';

test.describe('Complete Journey Suite - Navigation and Functionality', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the home page before each test
    await page.goto('/');
  });

  test('should load the home page successfully', async ({ page }) => {
    // Check that the page loads without errors
    await expect(page).toHaveTitle(/MeasureBowl/);
    
    // Check for main application elements
    await expect(page.locator('body')).toBeVisible();
  });

  test('should have navigation bar with expected links', async ({ page }) => {
    // Test for navbar existence
    const navbar = page.locator('[data-testid="navbar"]');
    await expect(navbar).toBeVisible();

    // Test for expected navigation links
    const expectedNavLinks = [
      { testId: 'navbar-link-home', text: 'Home', href: '/' },
      { testId: 'navbar-link-measure', text: 'Measure', href: '/measure' },
      { testId: 'navbar-link-history', text: 'History', href: '/history' },
      { testId: 'navbar-link-tournaments', text: 'Tournaments', href: '/tournaments' },
      { testId: 'navbar-link-settings', text: 'Settings', href: '/settings' },
      { testId: 'navbar-link-help', text: 'Help', href: '/help' }
    ];

    for (const link of expectedNavLinks) {
      const navLink = page.locator(`[data-testid="${link.testId}"]`);
      await expect(navLink).toBeVisible();
      await expect(navLink).toHaveText(link.text);
      await expect(navLink).toHaveAttribute('href', link.href);
    }
  });

  test('should navigate to measure page', async ({ page }) => {
    const measureLink = page.locator('[data-testid="navbar-link-measure"]');
    await measureLink.click();
    
    // Should navigate to measure page
    await expect(page).toHaveURL('/measure');
    
    // Check for measure page elements
    await expect(page.locator('[data-testid="measure-page"]')).toBeVisible();
    await expect(page.locator('[data-testid="camera-view"]')).toBeVisible();
  });

  test('should navigate to history page', async ({ page }) => {
    const historyLink = page.locator('[data-testid="navbar-link-history"]');
    await historyLink.click();
    
    // Should navigate to history page
    await expect(page).toHaveURL('/history');
    
    // Check for history page elements
    await expect(page.locator('[data-testid="history-page"]')).toBeVisible();
    await expect(page.locator('[data-testid="measurements-list"]')).toBeVisible();
  });

  test('should navigate to tournaments page', async ({ page }) => {
    const tournamentsLink = page.locator('[data-testid="navbar-link-tournaments"]');
    await tournamentsLink.click();
    
    // Should navigate to tournaments page
    await expect(page).toHaveURL('/tournaments');
    
    // Check for tournaments page elements
    await expect(page.locator('[data-testid="tournaments-page"]')).toBeVisible();
    await expect(page.locator('[data-testid="tournaments-list"]')).toBeVisible();
  });

  test('should navigate to settings page', async ({ page }) => {
    const settingsLink = page.locator('[data-testid="navbar-link-settings"]');
    await settingsLink.click();
    
    // Should navigate to settings page
    await expect(page).toHaveURL('/settings');
    
    // Check for settings page elements
    await expect(page.locator('[data-testid="settings-page"]')).toBeVisible();
    await expect(page.locator('[data-testid="settings-form"]')).toBeVisible();
  });

  test('should navigate to help page', async ({ page }) => {
    const helpLink = page.locator('[data-testid="navbar-link-help"]');
    await helpLink.click();
    
    // Should navigate to help page
    await expect(page).toHaveURL('/help');
    
    // Check for help page elements
    await expect(page.locator('[data-testid="help-page"]')).toBeVisible();
    await expect(page.locator('[data-testid="help-content"]')).toBeVisible();
  });

  test('should have working camera functionality', async ({ page }) => {
    // Navigate to measure page
    await page.goto('/measure');
    
    // Check for camera elements
    await expect(page.locator('[data-testid="camera-view"]')).toBeVisible();
    await expect(page.locator('[data-testid="camera-button"]')).toBeVisible();
    await expect(page.locator('[data-testid="manual-button"]')).toBeVisible();
  });

  test('should have working measurement history', async ({ page }) => {
    // Navigate to history page
    await page.goto('/history');
    
    // Check for history elements
    await expect(page.locator('[data-testid="measurements-list"]')).toBeVisible();
    await expect(page.locator('[data-testid="filter-controls"]')).toBeVisible();
    await expect(page.locator('[data-testid="export-button"]')).toBeVisible();
  });

  test('should have working tournament management', async ({ page }) => {
    // Navigate to tournaments page
    await page.goto('/tournaments');
    
    // Check for tournament elements
    await expect(page.locator('[data-testid="tournaments-list"]')).toBeVisible();
    await expect(page.locator('[data-testid="create-tournament-button"]')).toBeVisible();
    await expect(page.locator('[data-testid="tournament-filters"]')).toBeVisible();
  });

  test('should have working settings', async ({ page }) => {
    // Navigate to settings page
    await page.goto('/settings');
    
    // Check for settings elements
    await expect(page.locator('[data-testid="settings-form"]')).toBeVisible();
    await expect(page.locator('[data-testid="save-settings-button"]')).toBeVisible();
    await expect(page.locator('[data-testid="reset-settings-button"]')).toBeVisible();
  });

  test('should have working help system', async ({ page }) => {
    // Navigate to help page
    await page.goto('/help');
    
    // Check for help elements
    await expect(page.locator('[data-testid="help-content"]')).toBeVisible();
    await expect(page.locator('[data-testid="search-help"]')).toBeVisible();
    await expect(page.locator('[data-testid="contact-support"]')).toBeVisible();
  });

  test('should handle 404 errors gracefully', async ({ page }) => {
    // Navigate to non-existent page
    await page.goto('/non-existent-page');
    
    // Should show 404 page
    await expect(page.locator('[data-testid="not-found-page"]')).toBeVisible();
    await expect(page.locator('[data-testid="go-home-button"]')).toBeVisible();
  });

  test('should have responsive navigation', async ({ page }) => {
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Check for mobile navigation
    await expect(page.locator('[data-testid="mobile-menu-button"]')).toBeVisible();
    
    // Click mobile menu
    await page.locator('[data-testid="mobile-menu-button"]').click();
    await expect(page.locator('[data-testid="mobile-menu"]')).toBeVisible();
    
    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 });
    await expect(page.locator('[data-testid="desktop-navbar"]')).toBeVisible();
  });

  test('should have working API endpoints', async ({ page }) => {
    // Test measurements API
    const measurementsResponse = await page.request.get('/api/measurements');
    expect(measurementsResponse.status()).toBe(200);
    
    // Test tournaments API
    const tournamentsResponse = await page.request.get('/api/tournaments');
    expect(tournamentsResponse.status()).toBe(200);
    
    // Test settings API
    const settingsResponse = await page.request.get('/api/settings');
    expect(settingsResponse.status()).toBe(200);
  });

  test('should handle authentication flow', async ({ page }) => {
    // Check for login/logout functionality
    const loginButton = page.locator('[data-testid="login-button"]');
    const logoutButton = page.locator('[data-testid="logout-button"]');
    
    // Should have either login or logout button
    const hasLogin = await loginButton.isVisible();
    const hasLogout = await logoutButton.isVisible();
    
    expect(hasLogin || hasLogout).toBe(true);
  });

  test('should have working search functionality', async ({ page }) => {
    // Navigate to history page
    await page.goto('/history');
    
    // Test search functionality
    const searchInput = page.locator('[data-testid="search-input"]');
    await expect(searchInput).toBeVisible();
    
    await searchInput.fill('test search');
    await expect(searchInput).toHaveValue('test search');
  });

  test('should have working export functionality', async ({ page }) => {
    // Navigate to history page
    await page.goto('/history');
    
    // Test export button
    const exportButton = page.locator('[data-testid="export-button"]');
    await expect(exportButton).toBeVisible();
    
    // Click export button
    await exportButton.click();
    
    // Should show export options
    await expect(page.locator('[data-testid="export-options"]')).toBeVisible();
  });
});

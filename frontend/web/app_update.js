(function () {
  const storageKey = "householdchores.webBuildId";

  async function clearOldAppShellCaches() {
    if ("serviceWorker" in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    }

    if ("caches" in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    }
  }

  async function checkForWebUpdate() {
    try {
      const response = await fetch(`/version.json?ts=${Date.now()}`, {
        cache: "no-store",
      });
      if (!response.ok) return;

      const version = await response.json();
      const buildId = version.buildId || version.version;
      if (!buildId) return;

      const previousBuildId = localStorage.getItem(storageKey);
      if (!previousBuildId) {
        localStorage.setItem(storageKey, buildId);
        return;
      }

      if (previousBuildId === buildId) return;

      localStorage.setItem(storageKey, buildId);
      await clearOldAppShellCaches();

      const url = new URL(window.location.href);
      url.searchParams.set("build", buildId);
      window.location.replace(url.toString());
    } catch (_) {
      // Update checks should never stop the app from loading.
    }
  }

  window.HouseholdChoresUpdates = {
    checkForWebUpdate,
    clearOldAppShellCaches,
  };

  checkForWebUpdate();
})();

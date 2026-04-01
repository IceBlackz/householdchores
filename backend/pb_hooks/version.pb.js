/// <reference path="../pb_data/types.d.ts" />

// Exposes the server version and minimum compatible app version.
// The app calls this endpoint on login to verify compatibility.
//
// Compatibility rule: MAJOR versions must match.
//   - Server 1.x is compatible with App 1.x
//   - Server 2.x requires App 2.x (breaking changes)
//
// To update versions: change both this file and the VERSION file at the repo root,
// then run the release script which updates pubspec.yaml and rebuilds everything.

routerAdd("GET", "/api/householdchores/version", (e) => {
  return e.json(200, {
    version: "1.0.0",
    minAppVersion: "1.0.0",
    appName: "householdchores",
  });
});
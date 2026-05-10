// Optional runtime web configuration.
//
// Leave backendUrl empty for the default behavior:
// - Web app served from http://server:9011
// - Backend API expected at http://server:9010
//
// For HTTPS proxy setups, set this to the HTTPS backend URL before rebuilding
// the web container, for example:
// window.HOUSEHOLDCHORES_CONFIG = { backendUrl: "https://chores.example.com:9444" };
window.HOUSEHOLDCHORES_CONFIG = {
  backendUrl: "",
};

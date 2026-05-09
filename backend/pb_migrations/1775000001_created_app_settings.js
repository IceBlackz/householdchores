/// <reference path="../pb_data/types.d.ts" />

// Stores admin-managed app settings such as notification preferences.

migrate((app) => {
  const collection = new Collection({
    id: "pbc_5000000001",
    name: "app_settings",
    type: "base",
    system: false,
    listRule: '@request.auth.id != ""',
    viewRule: '@request.auth.id != ""',
    createRule: '@request.auth.id != "" && @request.auth.is_admin = true',
    updateRule: '@request.auth.id != "" && @request.auth.is_admin = true',
    deleteRule: '@request.auth.id != "" && @request.auth.is_admin = true',
    fields: [
      {
        autogeneratePattern: "[a-z0-9]{15}",
        hidden: false,
        id: "text500000001",
        max: 15,
        min: 15,
        name: "id",
        pattern: "^[a-z0-9]+$",
        presentable: false,
        primaryKey: true,
        required: true,
        system: true,
        type: "text",
      },
      {
        autogeneratePattern: "",
        hidden: false,
        id: "text500000002",
        max: 80,
        min: 1,
        name: "key",
        pattern: "^[a-z0-9_]+$",
        presentable: true,
        primaryKey: false,
        required: true,
        system: false,
        type: "text",
      },
      {
        hidden: false,
        id: "json500000003",
        maxSize: 2000000,
        name: "value",
        presentable: false,
        required: false,
        system: false,
        type: "json",
      },
      {
        hidden: false,
        id: "date500000004",
        name: "created",
        onCreate: true,
        onUpdate: false,
        presentable: false,
        system: false,
        type: "autodate",
      },
      {
        hidden: false,
        id: "date500000005",
        name: "updated",
        onCreate: true,
        onUpdate: true,
        presentable: false,
        system: false,
        type: "autodate",
      },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_app_settings_key ON app_settings (key)",
    ],
  });

  app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("app_settings");
  app.delete(collection);
});

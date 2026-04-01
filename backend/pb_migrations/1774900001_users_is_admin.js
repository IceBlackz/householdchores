/// <reference path="../pb_data/types.d.ts" />

// Adds is_admin field to users collection.
// Only admin users may create or delete other users.
// Admins can update anyone; regular users can only update themselves.
//
// After this migration runs, set at least one user to is_admin = true
// via the PocketBase admin panel (http://localhost:9010/_/) — after that
// you can manage everything from within the app itself.

migrate((app) => {
  const collection = app.findCollectionByNameOrId("users");

  collection.fields.add(new Field({
    id:       "bool_is_admin01",
    name:     "is_admin",
    type:     "bool",
    required: false,
  }));

  collection.createRule = '@request.auth.id != "" && @request.auth.is_admin = true';
  collection.updateRule = '@request.auth.id != "" && (@request.auth.is_admin = true || @request.auth.id = id)';
  collection.deleteRule = '@request.auth.id != "" && @request.auth.is_admin = true';

  app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("users");
  collection.fields.removeById("bool_is_admin01");
  collection.createRule = '@request.auth.id != ""';
  collection.updateRule = '@request.auth.id != ""';
  collection.deleteRule = '@request.auth.id != ""';
  app.save(collection);
});
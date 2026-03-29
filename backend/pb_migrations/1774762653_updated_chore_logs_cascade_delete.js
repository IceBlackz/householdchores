/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2178705551")

  // Enable cascade delete on the chore relation so logs are cleaned up
  // automatically when a chore is deleted
  collection.fields.getById("relation2239244242").cascadeDelete = true

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2178705551")

  collection.fields.getById("relation2239244242").cascadeDelete = false

  return app.save(collection)
})

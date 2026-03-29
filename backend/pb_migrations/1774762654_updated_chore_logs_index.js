/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2178705551")

  // Index on (chore, created DESC) to speed up the per-chore latest-log query
  // used on every dashboard load
  collection.indexes = [
    ...(collection.indexes || []),
    "CREATE INDEX idx_chore_logs_chore_created ON chore_logs (chore, created DESC)",
  ]

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2178705551")

  collection.indexes = (collection.indexes || []).filter(
    (i) => !i.includes("idx_chore_logs_chore_created"),
  )

  return app.save(collection)
})

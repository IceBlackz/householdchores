/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1145403802")

  // add field
  collection.fields.addAt(8, new Field({
    "hidden": false,
    "id": "select1234567801",
    "maxSelect": 1,
    "name": "interval_unit",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": ["days", "weeks", "months", "quarters", "years"]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1145403802")

  // remove field
  collection.fields.removeById("select1234567801")

  return app.save(collection)
})

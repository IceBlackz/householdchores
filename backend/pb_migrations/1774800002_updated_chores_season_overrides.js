/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1145403802")

  // add per-season interval override fields
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "number1234567802",
    "max": null,
    "min": 0,
    "name": "season_spring_override",
    "onlyInt": true,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  collection.fields.addAt(10, new Field({
    "hidden": false,
    "id": "number1234567803",
    "max": null,
    "min": 0,
    "name": "season_summer_override",
    "onlyInt": true,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  collection.fields.addAt(11, new Field({
    "hidden": false,
    "id": "number1234567804",
    "max": null,
    "min": 0,
    "name": "season_autumn_override",
    "onlyInt": true,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  collection.fields.addAt(12, new Field({
    "hidden": false,
    "id": "number1234567805",
    "max": null,
    "min": 0,
    "name": "season_winter_override",
    "onlyInt": true,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1145403802")

  collection.fields.removeById("number1234567802")
  collection.fields.removeById("number1234567803")
  collection.fields.removeById("number1234567804")
  collection.fields.removeById("number1234567805")

  return app.save(collection)
})

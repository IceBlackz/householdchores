/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  const rooms = new Collection({
    id: "pbc_5100000001",
    name: "rooms",
    type: "base",
    system: false,
    listRule: '@request.auth.id != ""',
    viewRule: '@request.auth.id != ""',
    createRule: '@request.auth.id != ""',
    updateRule: '@request.auth.id != ""',
    deleteRule: '@request.auth.id != ""',
    fields: [
      {
        autogeneratePattern: "[a-z0-9]{15}",
        hidden: false,
        id: "text510000001",
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
        id: "text510000002",
        max: 80,
        min: 1,
        name: "name",
        pattern: "",
        presentable: true,
        primaryKey: false,
        required: true,
        system: false,
        type: "text",
      },
      {
        autogeneratePattern: "",
        hidden: false,
        id: "text510000003",
        max: 40,
        min: 0,
        name: "icon",
        pattern: "",
        presentable: false,
        primaryKey: false,
        required: false,
        system: false,
        type: "text",
      },
      {
        hidden: false,
        id: "date510000004",
        name: "created",
        onCreate: true,
        onUpdate: false,
        presentable: false,
        system: false,
        type: "autodate",
      },
      {
        hidden: false,
        id: "date510000005",
        name: "updated",
        onCreate: true,
        onUpdate: true,
        presentable: false,
        system: false,
        type: "autodate",
      },
    ],
    indexes: ["CREATE UNIQUE INDEX idx_rooms_name ON rooms (name)"],
  });

  app.save(rooms);

  const chores = app.findCollectionByNameOrId("pbc_1145403802");
  chores.fields.addAt(13, new Field({
    cascadeDelete: false,
    collectionId: "pbc_5100000001",
    hidden: false,
    id: "relation510000006",
    maxSelect: 1,
    minSelect: 0,
    name: "room",
    presentable: false,
    required: false,
    system: false,
    type: "relation",
  }));

  app.save(chores);
}, (app) => {
  const chores = app.findCollectionByNameOrId("pbc_1145403802");
  chores.fields.removeById("relation510000006");
  app.save(chores);

  const rooms = app.findCollectionByNameOrId("rooms");
  app.delete(rooms);
});

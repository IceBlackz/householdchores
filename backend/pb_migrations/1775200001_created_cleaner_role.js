/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  users.fields.add(new Field({
    id: "bool_cleaner01",
    name: "is_cleaner",
    type: "bool",
    required: false,
  }));
  users.listRule = '@request.auth.id != "" && (@request.auth.is_cleaner = false || id = @request.auth.id)';
  users.viewRule = '@request.auth.id != "" && (@request.auth.is_cleaner = false || id = @request.auth.id)';
  app.save(users);

  const chores = app.findCollectionByNameOrId("pbc_1145403802");
  chores.fields.add(new Field({
    id: "bool_chclean01",
    name: "cleaner_enabled",
    type: "bool",
    required: false,
  }));
  chores.listRule = '@request.auth.id != "" && (@request.auth.is_cleaner = false || cleaner_enabled = true)';
  chores.viewRule = '@request.auth.id != "" && (@request.auth.is_cleaner = false || cleaner_enabled = true)';
  chores.createRule = '@request.auth.id != "" && @request.auth.is_cleaner = false';
  chores.updateRule = '@request.auth.id != "" && @request.auth.is_cleaner = false';
  chores.deleteRule = '@request.auth.id != "" && @request.auth.is_cleaner = false';
  app.save(chores);

  const logs = app.findCollectionByNameOrId("pbc_2178705551");
  logs.listRule = '@request.auth.id != "" && (@request.auth.is_cleaner = false || chore.cleaner_enabled = true)';
  logs.viewRule = '@request.auth.id != "" && (@request.auth.is_cleaner = false || chore.cleaner_enabled = true)';
  logs.createRule = '@request.auth.id != "" && (@request.auth.is_cleaner = false || chore.cleaner_enabled = true)';
  logs.updateRule = '@request.auth.id != "" && @request.auth.is_cleaner = false';
  app.save(logs);

  const rooms = app.findCollectionByNameOrId("rooms");
  rooms.createRule = '@request.auth.id != "" && @request.auth.is_cleaner = false';
  rooms.updateRule = '@request.auth.id != "" && @request.auth.is_cleaner = false';
  rooms.deleteRule = '@request.auth.id != "" && @request.auth.is_cleaner = false';
  app.save(rooms);
}, (app) => {
  const rooms = app.findCollectionByNameOrId("rooms");
  rooms.createRule = '@request.auth.id != ""';
  rooms.updateRule = '@request.auth.id != ""';
  rooms.deleteRule = '@request.auth.id != ""';
  app.save(rooms);

  const logs = app.findCollectionByNameOrId("pbc_2178705551");
  logs.listRule = '@request.auth.id != ""';
  logs.viewRule = '@request.auth.id != ""';
  logs.createRule = '@request.auth.id != ""';
  logs.updateRule = '@request.auth.id != ""';
  app.save(logs);

  const chores = app.findCollectionByNameOrId("pbc_1145403802");
  chores.fields.removeById("bool_chclean01");
  chores.listRule = '@request.auth.id != ""';
  chores.viewRule = '@request.auth.id != ""';
  chores.createRule = '@request.auth.id != ""';
  chores.updateRule = '@request.auth.id != ""';
  chores.deleteRule = '@request.auth.id != ""';
  app.save(chores);

  const users = app.findCollectionByNameOrId("users");
  users.fields.removeById("bool_cleaner01");
  users.listRule = null;
  users.viewRule = null;
  app.save(users);
});

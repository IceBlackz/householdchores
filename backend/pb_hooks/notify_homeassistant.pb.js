/// <reference path="../pb_data/types.d.ts" />

// Home Assistant Webhook Integration (optional)
//
// When a chore is completed, this hook POSTs to a Home Assistant webhook.
// This lets you trigger automations (e.g. send a notification, update a counter entity).
//
// Setup:
//   1. In Home Assistant, create an automation with trigger type "Webhook" and note the webhook ID.
//   2. Set the HA_WEBHOOK_URL environment variable in backend/.env:
//      HA_WEBHOOK_URL=http://your-ha-instance:8123/api/webhook/your-webhook-id
//   3. Restart the backend: docker compose restart
//
// Payload sent to HA:
//   { "chore": "Clean Toilet", "completed_by": "Alice", "notes": "optional notes" }

onRecordCreate((e) => {
  const webhookUrl = $os.getenv("HA_WEBHOOK_URL");
  if (!webhookUrl) {
    // HA integration not configured — skip silently
    e.next();
    return;
  }

  try {
    const record = e.record;
    const choreId = record.getString("chore");

    // Resolve chore title
    let choreTitle = choreId;
    try {
      const chore = $app.findRecordById("chores", choreId);
      choreTitle = chore.getString("title");
    } catch (_) {}

    // Resolve who completed it
    const completedById = record.getString("completed_by");
    let completedByName = completedById;
    try {
      const user = $app.findRecordById("users", completedById);
      completedByName = user.getString("name") || user.getString("username") || completedById;
    } catch (_) {}

    const payload = JSON.stringify({
      chore: choreTitle,
      completed_by: completedByName,
      notes: record.getString("notes"),
    });

    const res = $http.send({
      url: webhookUrl,
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: payload,
      timeout: 5,
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      console.warn(`HA webhook returned status ${res.statusCode}`);
    }
  } catch (err) {
    // Log but don't block the chore completion
    console.error("HA webhook error:", err);
  }

  e.next();
}, "chore_logs");

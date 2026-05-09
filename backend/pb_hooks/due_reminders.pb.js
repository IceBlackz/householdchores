/// <reference path="../pb_data/types.d.ts" />

// Optional Home Assistant due-reminder integration.
//
// Required:
//   HA_DUE_WEBHOOK_URL=http://your-ha:8123/api/webhook/your-due-reminder-id
//   HA_ACTION_SECRET=use-a-long-random-secret
//
// Optional actionable links:
//   PUBLIC_BACKEND_URL=http://your-server:9010
//
// Optional schedule override:
//   HA_DUE_REMINDER_CRON=0 8 * * *

cronAdd("householdchores_due_reminders", $os.getenv("HA_DUE_REMINDER_CRON") || "0 8 * * *", function () {
  const secret = $os.getenv("HA_ACTION_SECRET");
  if (!secret) {
    return;
  }

  try {
    $http.send({
      url: "http://127.0.0.1:9010/api/householdchores/reminders/send?token=" + encodeURIComponent(secret),
      method: "POST",
      timeout: 30,
    });
  } catch (err) {
    console.error("Due reminder cron error:", err);
  }
});

routerAdd("POST", "/api/householdchores/reminders/send", function (e) {
  function queryParam(name) {
    const rawQuery = e.request.url.rawQuery || "";
    if (!rawQuery) return "";

    const pairs = rawQuery.split("&");
    for (let i = 0; i < pairs.length; i++) {
      const parts = pairs[i].split("=");
      if (decodeURIComponent(parts[0] || "") === name) {
        return decodeURIComponent((parts.slice(1).join("=") || "").replace(/\+/g, " "));
      }
    }
    return "";
  }

  function startOfDay(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  function currentSeason(date) {
    const month = date.getMonth() + 1;
    if (month >= 3 && month <= 5) return "Spring";
    if (month >= 6 && month <= 8) return "Summer";
    if (month >= 9 && month <= 11) return "Autumn";
    return "Winter";
  }

  function addInterval(base, value, unit) {
    const result = new Date(base.getTime());
    switch (unit) {
      case "weeks":
        result.setDate(result.getDate() + value * 7);
        return result;
      case "months":
        result.setMonth(result.getMonth() + value);
        return result;
      case "quarters":
        result.setMonth(result.getMonth() + value * 3);
        return result;
      case "years":
        result.setFullYear(result.getFullYear() + value);
        return result;
      default:
        result.setDate(result.getDate() + value);
        return result;
    }
  }

  function seasonOverride(chore, season) {
    let value = 0;
    switch (season) {
      case "Spring":
        value = chore.getInt("season_spring_override");
        break;
      case "Summer":
        value = chore.getInt("season_summer_override");
        break;
      case "Autumn":
        value = chore.getInt("season_autumn_override");
        break;
      case "Winter":
        value = chore.getInt("season_winter_override");
        break;
    }
    return value > 0 ? value : null;
  }

  function latestLogForChore(choreId) {
    const logs = $app.findRecordsByFilter(
      "chore_logs",
      'chore = "' + choreId + '"',
      "-created",
      1,
      0,
    );
    return logs.length > 0 ? logs[0] : null;
  }

  function dateFromRecord(record, fieldName) {
    const value = record.getDateTime(fieldName).string();
    return value ? new Date(value) : new Date();
  }

  function assigneeName(userId) {
    if (!userId) return "";
    try {
      const user = $app.findRecordById("users", userId);
      return user.getString("name") || user.getString("email") || userId;
    } catch (_) {
      return userId;
    }
  }

  function completeUrl(choreId, completedBy) {
    const publicUrl = ($os.getenv("PUBLIC_BACKEND_URL") || "").replace(/\/+$/, "");
    const secret = $os.getenv("HA_ACTION_SECRET");
    if (!publicUrl || !secret) return "";

    const ttlSeconds = parseInt($os.getenv("HA_ACTION_TOKEN_TTL_SECONDS") || "259200", 10);
    const token = $security.createJWT(
      {
        source: "householdchores_due_reminder",
        choreId: choreId,
        completedBy: completedBy || "",
      },
      secret,
      isNaN(ttlSeconds) || ttlSeconds <= 0 ? 259200 : ttlSeconds,
    );

    return publicUrl + "/api/householdchores/actions/complete?token=" + encodeURIComponent(token);
  }

  function notificationSettings() {
    try {
      const record = $app.findFirstRecordByFilter(
        "app_settings",
        'key = "notification_settings"',
      );
      return record.get("value") || {};
    } catch (_) {
      return {};
    }
  }

  function dueItems() {
    const now = new Date();
    const today = startOfDay(now);
    const season = currentSeason(now);
    const chores = $app.findRecordsByFilter("chores", "id != ''", "title", 500, 0);
    const items = [];

    for (let i = 0; i < chores.length; i++) {
      const chore = chores[i];
      const latestLog = latestLogForChore(chore.id);
      const intervalUnit = chore.getString("interval_unit") || "days";
      const desiredValue =
        seasonOverride(chore, season) || chore.getInt("interval_desired_days");
      const maxValue = chore.getInt("interval_max_days");

      let dueDate = null;
      let maxDueDate = null;
      let status = "due";
      let daysOverdue = 0;

      if (!latestLog) {
        status = "never_completed";
      } else {
        const lastCompleted = dateFromRecord(latestLog, "created");
        dueDate = startOfDay(addInterval(lastCompleted, desiredValue, intervalUnit));
        maxDueDate = startOfDay(addInterval(lastCompleted, maxValue, intervalUnit));

        if (dueDate > today) continue;

        daysOverdue = Math.max(
          0,
          Math.floor((today.getTime() - dueDate.getTime()) / 86400000),
        );
        status = maxDueDate < today ? "critical" : daysOverdue > 0 ? "overdue" : "due";
      }

      const overrideAssignee = chore.getString("onetimeonly_assignee");
      const defaultAssignee = chore.getString("default_assignee");
      const completedBy = overrideAssignee || defaultAssignee;

      items.push({
        chore_id: chore.id,
        title: chore.getString("title"),
        description: chore.getString("description"),
        assignee_id: completedBy,
        assignee_name: assigneeName(completedBy),
        status: status,
        days_overdue: daysOverdue,
        due_date: dueDate ? dueDate.toISOString().slice(0, 10) : null,
        max_due_date: maxDueDate ? maxDueDate.toISOString().slice(0, 10) : null,
        complete_url: completeUrl(chore.id, completedBy),
      });
    }

    items.sort(function (a, b) {
      const statusRank = { critical: 0, never_completed: 1, overdue: 2, due: 3 };
      const rankDiff = statusRank[a.status] - statusRank[b.status];
      if (rankDiff !== 0) return rankDiff;
      return a.title.localeCompare(b.title);
    });

    return items;
  }

  try {
    const secret = $os.getenv("HA_ACTION_SECRET");
    if (!secret || queryParam("token") !== secret) {
      return e.json(401, { error: "Unauthorized" });
    }

    const settings = notificationSettings();
    const haEnabled =
      settings.homeAssistantDueRemindersEnabled === true ||
      !!$os.getenv("HA_DUE_WEBHOOK_URL");

    if (!haEnabled) {
      return e.json(200, {
        sent: false,
        reason: "Home Assistant due reminders are disabled",
        items: [],
      });
    }

    const webhookUrl =
      settings.homeAssistantWebhookUrl || $os.getenv("HA_DUE_WEBHOOK_URL");
    if (!webhookUrl) {
      return e.json(200, {
        sent: false,
        reason: "HA_DUE_WEBHOOK_URL is not configured",
        items: [],
      });
    }

    const items = dueItems();
    if (items.length === 0) {
      return e.json(200, { sent: false, reason: "No due chores", items: [] });
    }

    const payload = {
      source: "householdchores_due_reminder",
      generated_at: new Date().toISOString(),
      actionable: !!($os.getenv("PUBLIC_BACKEND_URL") || ""),
      count: items.length,
      items: items,
    };

    const res = $http.send({
      url: webhookUrl,
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      timeout: 10,
    });

    return e.json(200, {
      sent: res.statusCode >= 200 && res.statusCode < 300,
      status_code: res.statusCode,
      items: items,
    });
  } catch (err) {
    console.error("Manual due reminder error:", err);
    return e.json(500, { error: String(err) });
  }
});

function completeFromReminderAction(e) {
  function queryParam(name) {
    const rawQuery = e.request.url.rawQuery || "";
    if (!rawQuery) return "";

    const pairs = rawQuery.split("&");
    for (let i = 0; i < pairs.length; i++) {
      const parts = pairs[i].split("=");
      if (decodeURIComponent(parts[0] || "") === name) {
        return decodeURIComponent((parts.slice(1).join("=") || "").replace(/\+/g, " "));
      }
    }
    return "";
  }

  try {
    const secret = $os.getenv("HA_ACTION_SECRET");
    const token = queryParam("token");
    if (!secret) {
      return e.json(503, { error: "Action links are not configured" });
    }
    if (!token) {
      return e.json(400, { error: "Missing token" });
    }

    let claims;
    try {
      claims = $security.parseJWT(token, secret);
    } catch (_) {
      return e.json(401, { error: "Invalid or expired token" });
    }

    if (claims.source !== "householdchores_due_reminder" || !claims.choreId) {
      return e.json(401, { error: "Invalid token payload" });
    }

    const chore = $app.findRecordById("chores", claims.choreId);
    const collection = $app.findCollectionByNameOrId("chore_logs");
    const log = new Record(collection);
    log.set("chore", claims.choreId);
    log.set("notes", "Completed from Home Assistant reminder");
    if (claims.completedBy) {
      try {
        $app.findRecordById("users", claims.completedBy);
        log.set("completed_by", claims.completedBy);
      } catch (_) {}
    }

    $app.save(log);
    chore.set("onetimeonly_assignee", "");
    $app.save(chore);

    return e.json(200, {
      ok: true,
      chore_id: claims.choreId,
      title: chore.getString("title"),
    });
  } catch (err) {
    console.error("Reminder action completion error:", err);
    return e.json(500, { error: String(err) });
  }
}

routerAdd("GET", "/api/householdchores/actions/complete", completeFromReminderAction);
routerAdd("POST", "/api/householdchores/actions/complete", completeFromReminderAction);

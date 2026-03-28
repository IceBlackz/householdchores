# AI Developer Context
**Hello AI Assistant!** If you are reading this, you are helping develop the Household Chores app. Please read this document carefully to understand the architectural decisions, database schemas, and framework quirks we are using.

## 🏗 Architecture
* **Backend:** PocketBase v0.22+ running in a Docker container (Port 9010).
* **Frontend:** Flutter (compiled for Web and Desktop).
* **Auth:** Standard PocketBase email/password User authentication. JWT tokens are handled by the `pocketbase` Dart SDK.

## 🗄 Database Schema (PocketBase)

### Collection: `chores` (Type: Base)
The master list of tasks.
* `title` (Text)
* `description` (Text)
* `interval_desired_days` (Number) - How often it *should* be done.
* `interval_max_days` (Number) - The absolute deadline.
* `season` (Select: All, Spring, Summer, Autumn, Winter)
* `default_assignee` (Relation -> `users`, Max Select: 1)
* `onetimeonly_assignee` (Relation -> `users`, Max Select: 1) - Used for temporary cycle overrides.

### Collection: `chore_logs` (Type: Base)
The history of completed tasks.
* `chore` (Relation -> `chores`, Max Select: 1)
* `completed_by` (Relation -> `users`, Max Select: 1)
* `photo_before` (File, Max: 1)
* `photo_after` (File, Max: 1)
* `notes` (Text)

### API Rules
* `users`: List/View requires `@request.auth.id != ""`
* `chores`: List/View/Create/Update requires `@request.auth.id != ""`
* `chore_logs`: List/View/Create requires `@request.auth.id != ""`

## 🧠 Core Business Logic

### 1. Smart Dashboard Sorting
The dashboard (`dashboard_screen.dart`) fetches all chores and expands both user relations. It calculates the **Next Due Date** dynamically:
1. Fetch the latest `chore_log` for the specific chore.
2. Next Due Date = Log.created + chore.interval_desired_days.
3. If no log exists, the due date is set to DateTime.now() - 999 days (Highly Overdue).
4. **Sorting Algorithm:** Tasks actively assigned to the logged-in user float to the absolute top. The secondary sort is by closest/most overdue Due Date.

### 2. One-Time Assignment Overrides
If `onetimeonly_assignee` has a value, it completely overrides `default_assignee` for the UI and sorting logic. 
*Crucial Mechanism:* In `complete_chore_screen.dart`, immediately after a `chore_log` is created, a PATCH/Update request is sent to the `chores` collection to clear `onetimeonly_assignee` back to an empty string `""`. This ensures it automatically resets for the next cycle.

## ⚠️ Framework Quirks & Known Gotchas

### Flutter Web Compatibility (File Uploads)
Because the app runs on Flutter Web (Chrome), we **cannot** use `dart:io` or file paths to upload images. 
* Use `XFile.readAsBytes()` from the `image_picker` package.
* Pass the bytes to PocketBase using `http.MultipartFile.fromBytes('field_name', bytes, filename: file.name)`.

### PocketBase Dart SDK (Modern Best Practices)
We are using the newest PocketBase Dart SDK. Do NOT use deprecated methods.
* **DO NOT** use `.expand['field']`. Use the type-safe method: `record.get<RecordModel?>('expand.field')`.
* **DO NOT** use `record.created`. Use `record.getStringValue('created')`.
* **DO NOT** use `.getFirstListItem()` for retrieving logs if there's a chance none exist (it throws a 404 Exception). Instead, use `.getList(page: 1, perPage: 1, filter: '...', sort: '-created')` and check if `logList.items.isNotEmpty`.

### Flutter UI deprecations
* Use `.withValues(alpha: 0.1)` instead of `.withOpacity(0.1)` for colors to support modern Wide Gamut rendering.
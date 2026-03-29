// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Household Chores';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get incorrectCredentials =>
      'Incorrect email or password. Please try again.';

  @override
  String get cannotConnect =>
      'Cannot connect to the server. Check your network.';

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get householdLogin => 'Household Login';

  @override
  String get householdChores => 'Household Chores';

  @override
  String get addNewChore => 'Add New Chore';

  @override
  String get editChore => 'Edit Chore';

  @override
  String get saveChore => 'Save Chore';

  @override
  String get updateChore => 'Update Chore';

  @override
  String get choreAdded => 'Chore added!';

  @override
  String get choreUpdated => 'Chore updated!';

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get choreTitle => 'Chore Title (e.g. Clean Toilet)';

  @override
  String get titleRequired => 'Please enter a title';

  @override
  String get description => 'Description (Optional)';

  @override
  String get defaultAssignee => 'Default Assignee';

  @override
  String get unassignedAnyone => 'Unassigned (Anyone)';

  @override
  String get oneTimeOverride => 'One-Time Override (This cycle only)';

  @override
  String get noneUseDefault => 'None (Use Default)';

  @override
  String get desiredInterval => 'Desired Interval';

  @override
  String get unitLabel => 'Unit';

  @override
  String get maxDeadline => 'Max Deadline';

  @override
  String get required => 'Required';

  @override
  String get season => 'Season';

  @override
  String get seasonOverrides => 'Season-Specific Overrides';

  @override
  String get seasonOverridesSubtitle =>
      'Override interval per season (0 = use default)';

  @override
  String get spring => 'Spring';

  @override
  String get summer => 'Summer';

  @override
  String get autumn => 'Autumn';

  @override
  String get winter => 'Winter';

  @override
  String seasonFieldLabel(String season, String unit) {
    return '$season ($unit)';
  }

  @override
  String get seasonFieldHint => '0 = use default';

  @override
  String get intervalDays => 'Days';

  @override
  String get intervalWeeks => 'Weeks';

  @override
  String get intervalMonths => 'Months';

  @override
  String get intervalQuarters => 'Quarters';

  @override
  String get intervalYears => 'Years';

  @override
  String completeChore(String title) {
    return 'Complete: $title';
  }

  @override
  String get markingTaskAsDone =>
      'Marking this task as done! Feel free to add proof.';

  @override
  String get attachBeforePhoto => 'Attach \"Before\" Photo';

  @override
  String get beforePhotoSelected => 'Before Photo Selected!';

  @override
  String get attachAfterPhoto => 'Attach \"After\" Photo';

  @override
  String get afterPhotoSelected => 'After Photo Selected!';

  @override
  String get notes => 'Notes (Optional)';

  @override
  String get notesHint => 'e.g. Ran out of soap!';

  @override
  String get submitCompletion => 'Submit Completion';

  @override
  String failedToSubmit(String error) {
    return 'Failed to submit: $error';
  }

  @override
  String get taskCompleted => 'Awesome! Task completed.';

  @override
  String get noChoresRelax => 'No chores here! Time to relax?';

  @override
  String get retry => 'Retry';

  @override
  String get deleteChore => 'Delete Chore';

  @override
  String deleteConfirm(String title) {
    return 'Delete \"$title\"? This cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get choreDeleted => 'Chore deleted.';

  @override
  String failedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String history(String title) {
    return 'History: $title';
  }

  @override
  String get noHistoryYet => 'No completions recorded yet.';

  @override
  String failedToLoadHistory(String error) {
    return 'Failed to load history: $error';
  }

  @override
  String get unknownUser => 'Unknown';

  @override
  String covering(String name) {
    return '$name (Covering)';
  }

  @override
  String get neverCompleted => 'Never completed';

  @override
  String overdue(int days) {
    return 'Overdue ($days days)';
  }

  @override
  String get dueToday => 'Due today';

  @override
  String dueInDays(int days) {
    return 'Due in $days d';
  }

  @override
  String get viewHistory => 'View history';

  @override
  String get editChoreTooltip => 'Edit chore';

  @override
  String get deleteChoreTooltip => 'Delete chore';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageSpanish => 'Español';
}

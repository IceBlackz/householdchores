import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('nl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Household Chores'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBack(String name);

  /// No description provided for @incorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get incorrectCredentials;

  /// No description provided for @cannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the server. Check your network.'**
  String get cannotConnect;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @householdLogin.
  ///
  /// In en, this message translates to:
  /// **'Household Login'**
  String get householdLogin;

  /// No description provided for @householdChores.
  ///
  /// In en, this message translates to:
  /// **'Household Chores'**
  String get householdChores;

  /// No description provided for @addNewChore.
  ///
  /// In en, this message translates to:
  /// **'Add New Chore'**
  String get addNewChore;

  /// No description provided for @editChore.
  ///
  /// In en, this message translates to:
  /// **'Edit Chore'**
  String get editChore;

  /// No description provided for @saveChore.
  ///
  /// In en, this message translates to:
  /// **'Save Chore'**
  String get saveChore;

  /// No description provided for @updateChore.
  ///
  /// In en, this message translates to:
  /// **'Update Chore'**
  String get updateChore;

  /// No description provided for @choreAdded.
  ///
  /// In en, this message translates to:
  /// **'Chore added!'**
  String get choreAdded;

  /// No description provided for @choreUpdated.
  ///
  /// In en, this message translates to:
  /// **'Chore updated!'**
  String get choreUpdated;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// No description provided for @choreTitle.
  ///
  /// In en, this message translates to:
  /// **'Chore Title (e.g. Clean Toilet)'**
  String get choreTitle;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get titleRequired;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get description;

  /// No description provided for @defaultAssignee.
  ///
  /// In en, this message translates to:
  /// **'Default Assignee'**
  String get defaultAssignee;

  /// No description provided for @unassignedAnyone.
  ///
  /// In en, this message translates to:
  /// **'Unassigned (Anyone)'**
  String get unassignedAnyone;

  /// No description provided for @oneTimeOverride.
  ///
  /// In en, this message translates to:
  /// **'One-Time Override (This cycle only)'**
  String get oneTimeOverride;

  /// No description provided for @noneUseDefault.
  ///
  /// In en, this message translates to:
  /// **'None (Use Default)'**
  String get noneUseDefault;

  /// No description provided for @desiredInterval.
  ///
  /// In en, this message translates to:
  /// **'Desired Interval'**
  String get desiredInterval;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @maxDeadline.
  ///
  /// In en, this message translates to:
  /// **'Max Deadline'**
  String get maxDeadline;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @seasonOverrides.
  ///
  /// In en, this message translates to:
  /// **'Season-Specific Overrides'**
  String get seasonOverrides;

  /// No description provided for @seasonOverridesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Override interval per season (0 = use default)'**
  String get seasonOverridesSubtitle;

  /// No description provided for @spring.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get spring;

  /// No description provided for @summer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get summer;

  /// No description provided for @autumn.
  ///
  /// In en, this message translates to:
  /// **'Autumn'**
  String get autumn;

  /// No description provided for @winter.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get winter;

  /// No description provided for @seasonFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'{season} ({unit})'**
  String seasonFieldLabel(String season, String unit);

  /// No description provided for @seasonFieldHint.
  ///
  /// In en, this message translates to:
  /// **'0 = use default'**
  String get seasonFieldHint;

  /// No description provided for @intervalDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get intervalDays;

  /// No description provided for @intervalWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get intervalWeeks;

  /// No description provided for @intervalMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get intervalMonths;

  /// No description provided for @intervalQuarters.
  ///
  /// In en, this message translates to:
  /// **'Quarters'**
  String get intervalQuarters;

  /// No description provided for @intervalYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get intervalYears;

  /// No description provided for @completeChore.
  ///
  /// In en, this message translates to:
  /// **'Complete: {title}'**
  String completeChore(String title);

  /// No description provided for @markingTaskAsDone.
  ///
  /// In en, this message translates to:
  /// **'Marking this task as done! Feel free to add proof.'**
  String get markingTaskAsDone;

  /// No description provided for @attachBeforePhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach \"Before\" Photo'**
  String get attachBeforePhoto;

  /// No description provided for @beforePhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'Before Photo Selected!'**
  String get beforePhotoSelected;

  /// No description provided for @attachAfterPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach \"After\" Photo'**
  String get attachAfterPhoto;

  /// No description provided for @afterPhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'After Photo Selected!'**
  String get afterPhotoSelected;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ran out of soap!'**
  String get notesHint;

  /// No description provided for @submitCompletion.
  ///
  /// In en, this message translates to:
  /// **'Submit Completion'**
  String get submitCompletion;

  /// No description provided for @failedToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit: {error}'**
  String failedToSubmit(String error);

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Awesome! Task completed.'**
  String get taskCompleted;

  /// No description provided for @noChoresRelax.
  ///
  /// In en, this message translates to:
  /// **'No chores here! Time to relax?'**
  String get noChoresRelax;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @deleteChore.
  ///
  /// In en, this message translates to:
  /// **'Delete Chore'**
  String get deleteChore;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This cannot be undone.'**
  String deleteConfirm(String title);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @choreDeleted.
  ///
  /// In en, this message translates to:
  /// **'Chore deleted.'**
  String get choreDeleted;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String failedToDelete(String error);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History: {title}'**
  String history(String title);

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No completions recorded yet.'**
  String get noHistoryYet;

  /// No description provided for @failedToLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history: {error}'**
  String failedToLoadHistory(String error);

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownUser;

  /// No description provided for @covering.
  ///
  /// In en, this message translates to:
  /// **'{name} (Covering)'**
  String covering(String name);

  /// No description provided for @neverCompleted.
  ///
  /// In en, this message translates to:
  /// **'Never completed'**
  String get neverCompleted;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue ({days} days)'**
  String overdue(int days);

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {days} d'**
  String dueInDays(int days);

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get viewHistory;

  /// No description provided for @editChoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit chore'**
  String get editChoreTooltip;

  /// No description provided for @deleteChoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete chore'**
  String get deleteChoreTooltip;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get languageDutch;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

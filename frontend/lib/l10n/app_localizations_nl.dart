// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Huishoudelijke Taken';

  @override
  String get login => 'Inloggen';

  @override
  String get logout => 'Uitloggen';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Wachtwoord';

  @override
  String welcomeBack(String name) {
    return 'Welkom terug, $name!';
  }

  @override
  String get incorrectCredentials =>
      'Onjuist e-mailadres of wachtwoord. Probeer het opnieuw.';

  @override
  String get cannotConnect =>
      'Kan geen verbinding maken met de server. Controleer je netwerk.';

  @override
  String loginFailed(String error) {
    return 'Inloggen mislukt: $error';
  }

  @override
  String get householdLogin => 'Huishouden Inloggen';

  @override
  String get householdChores => 'Huishoudelijke Taken';

  @override
  String get addNewChore => 'Nieuwe Taak Toevoegen';

  @override
  String get editChore => 'Taak Bewerken';

  @override
  String get saveChore => 'Taak Opslaan';

  @override
  String get updateChore => 'Taak Bijwerken';

  @override
  String get choreAdded => 'Taak toegevoegd!';

  @override
  String get choreUpdated => 'Taak bijgewerkt!';

  @override
  String failedToSave(String error) {
    return 'Opslaan mislukt: $error';
  }

  @override
  String get choreTitle => 'Taaknaam (bijv. Toilet schoonmaken)';

  @override
  String get titleRequired => 'Voer een naam in';

  @override
  String get description => 'Omschrijving (Optioneel)';

  @override
  String get defaultAssignee => 'Standaard Toegewezen Aan';

  @override
  String get unassignedAnyone => 'Niet toegewezen (Iedereen)';

  @override
  String get oneTimeOverride => 'Eenmalige Overschrijving (Alleen deze cyclus)';

  @override
  String get noneUseDefault => 'Geen (Gebruik standaard)';

  @override
  String get desiredInterval => 'Gewenst Interval';

  @override
  String get unitLabel => 'Eenheid';

  @override
  String get maxDeadline => 'Maximale Deadline';

  @override
  String get required => 'Verplicht';

  @override
  String get season => 'Seizoen';

  @override
  String get seasonOverrides => 'Seizoensspecifieke Overschrijvingen';

  @override
  String get seasonOverridesSubtitle =>
      'Overschrijf interval per seizoen (0 = gebruik standaard)';

  @override
  String get spring => 'Lente';

  @override
  String get summer => 'Zomer';

  @override
  String get autumn => 'Herfst';

  @override
  String get winter => 'Winter';

  @override
  String seasonFieldLabel(String season, String unit) {
    return '$season ($unit)';
  }

  @override
  String get seasonFieldHint => '0 = gebruik standaard';

  @override
  String get intervalDays => 'Dagen';

  @override
  String get intervalWeeks => 'Weken';

  @override
  String get intervalMonths => 'Maanden';

  @override
  String get intervalQuarters => 'Kwartalen';

  @override
  String get intervalYears => 'Jaren';

  @override
  String completeChore(String title) {
    return 'Voltooien: $title';
  }

  @override
  String get markingTaskAsDone =>
      'Deze taak als voltooid markeren! Voeg gerust bewijs toe.';

  @override
  String get attachBeforePhoto => '\"Voor\"-foto Toevoegen';

  @override
  String get beforePhotoSelected => 'Voor-foto Geselecteerd!';

  @override
  String get attachAfterPhoto => '\"Na\"-foto Toevoegen';

  @override
  String get afterPhotoSelected => 'Na-foto Geselecteerd!';

  @override
  String get notes => 'Notities (Optioneel)';

  @override
  String get notesHint => 'bijv. Zeep was op!';

  @override
  String get submitCompletion => 'Voltooiing Indienen';

  @override
  String failedToSubmit(String error) {
    return 'Indienen mislukt: $error';
  }

  @override
  String get taskCompleted => 'Geweldig! Taak voltooid.';

  @override
  String get noChoresRelax => 'Geen taken hier! Tijd om te ontspannen?';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get deleteChore => 'Taak Verwijderen';

  @override
  String deleteConfirm(String title) {
    return 'Verwijder \"$title\"? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get cancel => 'Annuleren';

  @override
  String get delete => 'Verwijderen';

  @override
  String get choreDeleted => 'Taak verwijderd.';

  @override
  String failedToDelete(String error) {
    return 'Verwijderen mislukt: $error';
  }

  @override
  String history(String title) {
    return 'Geschiedenis: $title';
  }

  @override
  String get noHistoryYet => 'Nog geen voltooiingen geregistreerd.';

  @override
  String failedToLoadHistory(String error) {
    return 'Laden van geschiedenis mislukt: $error';
  }

  @override
  String get unknownUser => 'Onbekend';

  @override
  String covering(String name) {
    return '$name (Vervangt)';
  }

  @override
  String get neverCompleted => 'Nooit voltooid';

  @override
  String overdue(int days) {
    return 'Te laat ($days dagen)';
  }

  @override
  String get dueToday => 'Vandaag vervalt';

  @override
  String dueInDays(int days) {
    return 'Vervalt over $days d';
  }

  @override
  String get viewHistory => 'Geschiedenis bekijken';

  @override
  String get editChoreTooltip => 'Taak bewerken';

  @override
  String get deleteChoreTooltip => 'Taak verwijderen';

  @override
  String get selectLanguage => 'Taal Selecteren';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageSpanish => 'Español';
}

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

  @override
  String get houseConfiguration => 'Huis Configuratie';

  @override
  String get houseName => 'Huis Naam';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get homeAssistantWebhook => 'Home Assistant Webhook';

  @override
  String get testConnection => 'Verbinding Testen';

  @override
  String get connectionValid => 'Verbinding geldig!';

  @override
  String get activeHouse => 'Actief Huis';

  @override
  String get noActiveHouse => 'Geen actief huis';

  @override
  String get addNewHouse => 'Nieuw Huis Toevoegen';

  @override
  String get houseAdded => 'Huis toegevoegd!';

  @override
  String get houseUpdated => 'Huis bijgewerkt!';

  @override
  String get houseDeleted => 'Huis verwijderd.';

  @override
  String get deleteHouse => 'Huis Verwijderen';

  @override
  String deleteHouseConfirm(Object name) {
    return 'Verwijder \"$name\"? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String deleteHouseFailed(Object error) {
    return 'Verwijderen van huis mislukt: $error';
  }

  @override
  String saveFailed(Object error) {
    return 'Opslaan mislukt: $error';
  }

  @override
  String get edit => 'Bewerken';

  @override
  String get enterHouseNameHint => 'bijv. Thuis, Kantoor, Oma\'s';

  @override
  String get enterServerUrlHint => 'bijv. http://127.0.0.1:9010';

  @override
  String get enterHaWebhookUrlHint => 'Optionele Home Assistant webhook URL';

  @override
  String get invalidUrlError => 'Voer een geldige URL in';

  @override
  String get requiredField => 'Dit veld is verplicht';

  @override
  String get haSettingsDescription =>
      'Configureer Home Assistant webhook URLs voor elk huis. Dit is optioneel en alleen nodig als je chore notificaties in Home Assistant wilt ontvangen.';

  @override
  String get activeHouseHaWebhook => 'Actief Huis Webhook';

  @override
  String get haWebhookDescription =>
      'Webhook URL voor Home Assistant notificaties';

  @override
  String get haWebhookNote =>
      'Opmerking: Webhook URLs worden lokaal opgeslagen en niet gesynchroniseerd tussen apparaten.';

  @override
  String get seasonFilter => 'Seizoen Filter';

  @override
  String get allSeasons => 'Alle Seizoenen';

  @override
  String get seasonFilterAll => 'Alle';

  @override
  String get seasonFilterSpring => 'Lente';

  @override
  String get seasonFilterSummer => 'Zomer';

  @override
  String get seasonFilterAutumn => 'Herfst';

  @override
  String get seasonFilterWinter => 'Winter';

  @override
  String pastDeadline(int days) {
    return '!! ${days}d na max';
  }

  @override
  String get appVersionLabel => 'App v';

  @override
  String get versionWarningTitle => 'Versiewaarschuwing';

  @override
  String get versionEndpointNotFound =>
      'Deze server rapporteert zijn versie niet. Mogelijk is hij verouderd. Toch doorgaan?';

  @override
  String get versionCheckFailed =>
      'Serverversie kon niet worden geverifieerd. Toch doorgaan?';

  @override
  String get continueAnyway => 'Toch doorgaan';

  @override
  String get appTooOld => 'App moet worden bijgewerkt';

  @override
  String appTooOldDetail(String appVersion, String serverVersion) {
    return 'Jouw app (v$appVersion) is te oud voor deze server (v$serverVersion). Werk de app bij.';
  }

  @override
  String get serverTooOld => 'Server moet worden bijgewerkt';

  @override
  String serverTooOldDetail(String serverVersion, String appVersion) {
    return 'Jouw server (v$serverVersion) is te oud voor deze app (v$appVersion). Werk de server bij.';
  }

  @override
  String get save => 'Opslaan';

  @override
  String get manageUsers => 'Gebruikers Beheren';

  @override
  String get addUser => 'Gebruiker Toevoegen';

  @override
  String get editUser => 'Gebruiker Bewerken';

  @override
  String get deleteUser => 'Gebruiker Verwijderen';

  @override
  String deleteUserConfirm(String name) {
    return 'Verwijder $name? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get userDeleted => 'Gebruiker verwijderd.';

  @override
  String get userAdded => 'Gebruiker toegevoegd!';

  @override
  String get userUpdated => 'Gebruiker bijgewerkt!';

  @override
  String get adminBadge => 'Beheerder';

  @override
  String get adminBadgeSubtitle => 'Kan gebruikers en instellingen beheren';

  @override
  String get userName => 'Naam';

  @override
  String get newPassword => 'Nieuw Wachtwoord';

  @override
  String get passwordConfirm => 'Wachtwoord Bevestigen';

  @override
  String get changePassword => 'Wachtwoord wijzigen';

  @override
  String get passwordsDoNotMatch => 'Wachtwoorden komen niet overeen';

  @override
  String get passwordTooShort => 'Wachtwoord moet minimaal 8 tekens hebben';

  @override
  String get cannotDeleteSelf => 'Je kunt je eigen account niet verwijderen';

  @override
  String get noUsersFound => 'Geen gebruikers gevonden';

  @override
  String get youLabel => 'jij';

  @override
  String get completedBy => 'Voltooid door';
}

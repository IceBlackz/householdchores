// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Tareas del Hogar';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String welcomeBack(String name) {
    return '¡Bienvenido de vuelta, $name!';
  }

  @override
  String get incorrectCredentials =>
      'Correo o contraseña incorrectos. Inténtalo de nuevo.';

  @override
  String get cannotConnect =>
      'No se puede conectar al servidor. Comprueba tu red.';

  @override
  String loginFailed(String error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get householdLogin => 'Inicio de Sesión del Hogar';

  @override
  String get householdChores => 'Tareas del Hogar';

  @override
  String get addNewChore => 'Añadir Nueva Tarea';

  @override
  String get editChore => 'Editar Tarea';

  @override
  String get saveChore => 'Guardar Tarea';

  @override
  String get updateChore => 'Actualizar Tarea';

  @override
  String get choreAdded => '¡Tarea añadida!';

  @override
  String get choreUpdated => '¡Tarea actualizada!';

  @override
  String failedToSave(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get choreTitle => 'Nombre de la Tarea (ej. Limpiar el baño)';

  @override
  String get titleRequired => 'Por favor introduce un nombre';

  @override
  String get description => 'Descripción (Opcional)';

  @override
  String get defaultAssignee => 'Asignado Por Defecto';

  @override
  String get unassignedAnyone => 'Sin asignar (Cualquiera)';

  @override
  String get oneTimeOverride => 'Sustitución Puntual (Solo este ciclo)';

  @override
  String get noneUseDefault => 'Ninguno (Usar defecto)';

  @override
  String get desiredInterval => 'Intervalo Deseado';

  @override
  String get unitLabel => 'Unidad';

  @override
  String get maxDeadline => 'Plazo Máximo';

  @override
  String get required => 'Obligatorio';

  @override
  String get season => 'Temporada';

  @override
  String get seasonOverrides => 'Intervalos por Temporada';

  @override
  String get seasonOverridesSubtitle =>
      'Anular intervalo por temporada (0 = usar defecto)';

  @override
  String get spring => 'Primavera';

  @override
  String get summer => 'Verano';

  @override
  String get autumn => 'Otoño';

  @override
  String get winter => 'Invierno';

  @override
  String seasonFieldLabel(String season, String unit) {
    return '$season ($unit)';
  }

  @override
  String get seasonFieldHint => '0 = usar defecto';

  @override
  String get intervalDays => 'Días';

  @override
  String get intervalWeeks => 'Semanas';

  @override
  String get intervalMonths => 'Meses';

  @override
  String get intervalQuarters => 'Trimestres';

  @override
  String get intervalYears => 'Años';

  @override
  String completeChore(String title) {
    return 'Completar: $title';
  }

  @override
  String get markingTaskAsDone =>
      '¡Marcando esta tarea como completada! Añade pruebas si quieres.';

  @override
  String get attachBeforePhoto => 'Adjuntar Foto \"Antes\"';

  @override
  String get beforePhotoSelected => '¡Foto Antes Seleccionada!';

  @override
  String get attachAfterPhoto => 'Adjuntar Foto \"Después\"';

  @override
  String get afterPhotoSelected => '¡Foto Después Seleccionada!';

  @override
  String get notes => 'Notas (Opcional)';

  @override
  String get notesHint => 'ej. ¡Se acabó el jabón!';

  @override
  String get submitCompletion => 'Enviar Tarea Completada';

  @override
  String failedToSubmit(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get taskCompleted => '¡Genial! Tarea completada.';

  @override
  String get noChoresRelax => '¡No hay tareas aquí! ¿Hora de descansar?';

  @override
  String get retry => 'Reintentar';

  @override
  String get deleteChore => 'Eliminar Tarea';

  @override
  String deleteConfirm(String title) {
    return '¿Eliminar \"$title\"? No se puede deshacer.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get choreDeleted => 'Tarea eliminada.';

  @override
  String failedToDelete(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String history(String title) {
    return 'Historial: $title';
  }

  @override
  String get noHistoryYet => 'Aún no hay completaciones registradas.';

  @override
  String failedToLoadHistory(String error) {
    return 'Error al cargar historial: $error';
  }

  @override
  String get unknownUser => 'Desconocido';

  @override
  String covering(String name) {
    return '$name (Sustituyendo)';
  }

  @override
  String get neverCompleted => 'Nunca completada';

  @override
  String overdue(int days) {
    return 'Atrasada ($days días)';
  }

  @override
  String get dueToday => 'Vence hoy';

  @override
  String dueInDays(int days) {
    return 'Vence en $days d';
  }

  @override
  String get viewHistory => 'Ver historial';

  @override
  String get editChoreTooltip => 'Editar tarea';

  @override
  String get deleteChoreTooltip => 'Eliminar tarea';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageSpanish => 'Español';
}

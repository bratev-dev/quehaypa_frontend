import '../../../events/domain/entities/event_draft.dart';
import '../../../map/domain/entities/event_coordinates.dart';
export '../../../events/domain/entities/event_draft.dart'
    show EventBusiness, EventAttachment;

import 'package:flutter/material.dart';

enum EventCreationStep { data, details, publish }

/// Datos del formulario y del borrador persistido, sin cambiar su presentación.
class EventCreationController extends ChangeNotifier {
  EventCreationController({
    DateTime Function()? now,
    List<EventBusiness> businesses = const [],
  }) : _businesses = List.unmodifiable(businesses),
       _now = now ?? _bogotaNow;

  static DateTime _bogotaNow() {
    final utc = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    return DateTime(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }

  void reportError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  static const int maxFileBytes = 50 * 1024 * 1024;
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'pdf', 'mp4'};

  final DateTime Function() _now;
  List<EventBusiness> _businesses;
  final List<EventAttachment> _attachments = [];
  final List<Uri> _links = [];

  EventCreationStep step = EventCreationStep.data;
  EventBusiness? selectedBusiness;
  String name = '';
  String category = '';
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String day = '';
  String month = '';
  String year = '';
  String address = '';
  EventCoordinates? coordinates;
  String city = '';
  List<String> categories = [];
  String? draftId;
  void updateCity(String value) {
    city = value;
    _changed();
  }

  void setCategories(List<String> values) {
    categories = values;
    _changed();
  }

  String description = '';
  bool isPaid = false;
  bool adultsOnly = false;
  String? errorMessage;

  List<EventAttachment> get attachments => List.unmodifiable(_attachments);
  List<Uri> get links => List.unmodifiable(_links);
  List<EventBusiness> get businesses => _businesses;

  void setBusinesses(List<EventBusiness> values) {
    _businesses = List.unmodifiable(values);
    final selectedId = selectedBusiness?.id;
    selectedBusiness = null;
    if (selectedId != null) {
      for (final business in _businesses) {
        if (business.id == selectedId) {
          selectedBusiness = business;
          break;
        }
      }
    }
    notifyListeners();
  }

  void selectBusiness(EventBusiness? value) {
    selectedBusiness = value;
    _changed();
  }

  void updateName(String value) {
    name = value;
    _changed();
  }

  void updateCategory(String value) {
    category = value;
    _changed();
  }

  void updateAddress(String value) {
    address = value;
    _changed();
  }

  void selectCoordinates(EventCoordinates point) {
    coordinates = point;
    _changed();
  }

  void updateDescription(String value) {
    description = value.length > 200 ? value.substring(0, 200) : value;
    _changed();
  }

  void updateDay(String value) {
    day = value;
    _changed();
  }

  void updateMonth(String value) {
    month = value;
    _changed();
  }

  void updateYear(String value) {
    year = value;
    _changed();
  }

  void updateStartTime(TimeOfDay value) {
    startTime = value;
    _changed();
  }

  void updateEndTime(TimeOfDay value) {
    endTime = value;
    _changed();
  }

  void setPaid(bool value) {
    isPaid = value;
    _changed();
  }

  void setAdultsOnly(bool value) {
    adultsOnly = value;
    _changed();
  }

  void _changed() {
    errorMessage = null;
    notifyListeners();
  }

  DateTime? get eventDate {
    final parsedDay = int.tryParse(day);
    final parsedMonth = int.tryParse(month);
    var parsedYear = int.tryParse(year);
    if (parsedDay == null || parsedMonth == null || parsedYear == null) {
      return null;
    }
    if (parsedYear < 100) parsedYear += 2000;
    if (parsedYear < 2000 || parsedYear > 2100) return null;
    final date = DateTime(parsedYear, parsedMonth, parsedDay);
    if (date.year != parsedYear ||
        date.month != parsedMonth ||
        date.day != parsedDay) {
      return null;
    }
    return date;
  }

  bool get endsNextDay {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return false;
    return end.hour * 60 + end.minute < start.hour * 60 + start.minute;
  }

  DateTime? get eventEndDateTime {
    final date = eventDate;
    final start = startTime;
    final end = endTime;
    if (date == null || start == null || end == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day + (endsNextDay ? 1 : 0),
      end.hour,
      end.minute,
    );
  }

  String? validateData() {
    if (name.trim().isEmpty) return 'Escribe el nombre del evento.';
    if (category.isEmpty) return 'Selecciona una categoría.';
    if (startTime == null || endTime == null) return 'Selecciona los horarios.';
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    if (endMinutes == startMinutes) {
      return 'La hora de finalización debe ser diferente a la de inicio.';
    }
    final date = eventDate;
    if (date == null) return 'Ingresa una fecha válida.';
    final today = DateUtils.dateOnly(_now());
    if (date.isBefore(today)) return 'La fecha no puede ser anterior a hoy.';
    final startsAt = DateTime(
      date.year,
      date.month,
      date.day,
      startTime!.hour,
      startTime!.minute,
    );
    if (!startsAt.isAfter(_now())) return 'La hora de inicio debe ser futura.';
    if (address.trim().isEmpty) return 'Escribe la dirección del evento.';
    if (coordinates?.isValid != true) return 'Ubica el evento en el mapa.';
    return null;
  }

  bool next() {
    if (step == EventCreationStep.data) {
      errorMessage = validateData();
      if (errorMessage != null) {
        notifyListeners();
        return false;
      }
      step = EventCreationStep.details;
    } else if (step == EventCreationStep.details) {
      step = EventCreationStep.publish;
    } else {
      return false;
    }
    errorMessage = null;
    notifyListeners();
    return true;
  }

  void previous() {
    if (step == EventCreationStep.data) return;
    step = EventCreationStep.values[step.index - 1];
    errorMessage = null;
    notifyListeners();
  }

  String? addAttachment(EventAttachment file) {
    if (!allowedExtensions.contains(file.extension)) {
      return 'Formato no admitido. Usa JPG, PNG, PDF o MP4.';
    }
    if (file.sizeBytes <= 0 || file.sizeBytes > maxFileBytes) {
      return 'Cada archivo debe tener como máximo 50 MB.';
    }
    _attachments.add(file);
    notifyListeners();
    return null;
  }

  void removeAttachment(int index) {
    if (index < 0 || index >= _attachments.length) return;
    _attachments.removeAt(index);
    notifyListeners();
  }

  void markUploaded(int index, String id) {
    final file = _attachments[index];
    _attachments[index] = EventAttachment(
      name: file.name,
      sizeBytes: file.sizeBytes,
      id: id,
    );
    notifyListeners();
  }

  EventDraft draft() {
    final date = eventDate;
    final start = startTime;
    return EventDraft(
      id: draftId,
      name: name,
      description: description,
      category: category,
      address: address,
      coordinates: coordinates,
      day: day,
      month: month,
      year: year,
      step: step.index,
      startHour: start?.hour,
      startMinute: start?.minute,
      endHour: endTime?.hour,
      endMinute: endTime?.minute,
      businessId: int.tryParse(selectedBusiness?.id ?? ''),
      isPaid: isPaid,
      adultsOnly: adultsOnly,
      links: _links.map((link) => link.toString()).toList(),
      attachments: attachments,
      startsAt: date == null || start == null
          ? null
          : DateTime(date.year, date.month, date.day, start.hour, start.minute),
      endsAt: eventEndDateTime,
    );
  }

  void restoreDraft(EventDraft draft) {
    draftId = draft.id;
    name = draft.name;
    description = draft.description;
    category = draft.category;
    address = draft.address;
    coordinates = draft.coordinates;
    isPaid = draft.isPaid;
    adultsOnly = draft.adultsOnly;
    day = draft.day;
    month = draft.month;
    year = draft.year;
    startTime = draft.startHour == null
        ? null
        : TimeOfDay(hour: draft.startHour!, minute: draft.startMinute ?? 0);
    endTime = draft.endHour == null
        ? null
        : TimeOfDay(hour: draft.endHour!, minute: draft.endMinute ?? 0);
    selectedBusiness = _businesses
        .where((business) => business.id == draft.businessId?.toString())
        .firstOrNull;
    _links
      ..clear()
      ..addAll(draft.links.map(Uri.parse));
    _attachments
      ..clear()
      ..addAll(draft.attachments);
    step = EventCreationStep
        .values[draft.step.clamp(0, EventCreationStep.values.length - 1)];
    notifyListeners();
  }

  String? addLink(String value) {
    if (_links.length >= 50 || value.trim().length > 2000) {
      return 'Puedes añadir hasta 50 enlaces de máximo 2000 caracteres.';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return 'Escribe un enlace completo que comience por http:// o https://.';
    }
    if (_links.contains(uri)) return 'Ese enlace ya fue añadido.';
    _links.add(uri);
    notifyListeners();
    return null;
  }

  void removeLink(Uri uri) {
    _links.remove(uri);
    notifyListeners();
  }
}

import 'package:flutter/material.dart';

enum EventCreationStep { data, details, publish }

class EventBusiness {
  const EventBusiness({required this.id, required this.name});

  final String id;
  final String name;
}

class EventAttachment {
  const EventAttachment({required this.name, required this.sizeBytes});

  final String name;
  final int sizeBytes;

  String get extension => name.split('.').last.toLowerCase();
}

/// Estado local del prototipo. La API de creación se conectará después.
class EventCreationController extends ChangeNotifier {
  EventCreationController({
    DateTime Function()? now,
    List<EventBusiness> businesses = const [],
  }) : _businesses = List.unmodifiable(businesses),
       _now = now ?? DateTime.now;

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
    if (address.trim().isEmpty) return 'Escribe la dirección del evento.';
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
    if (file.sizeBytes < 0 || file.sizeBytes > maxFileBytes) {
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

  String? addLink(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
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

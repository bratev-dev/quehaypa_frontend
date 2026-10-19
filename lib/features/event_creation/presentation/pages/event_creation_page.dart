import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../domain/created_event_preview.dart';
import '../controllers/event_creation_controller.dart';
import '../event_creation_colors.dart';
import '../templates/event_creation_template.dart';

typedef EventAttachmentPicker = Future<List<EventAttachment>> Function();

class EventCreationPage extends StatefulWidget {
  const EventCreationPage({
    super.key,
    this.pickAttachments,
    this.businesses = const [],
    this.initialController,
  });

  /// Permite sustituir el selector nativo en pruebas de widget.
  final EventAttachmentPicker? pickAttachments;

  /// Lista que podrá proporcionar el backend al integrar esta pantalla.
  final List<EventBusiness> businesses;
  final EventCreationController? initialController;

  @override
  State<EventCreationPage> createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  late final EventCreationController controller =
      widget.initialController ??
      EventCreationController(businesses: widget.businesses);
  final linkController = TextEditingController();

  @override
  void didUpdateWidget(covariant EventCreationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.businesses, widget.businesses)) {
      controller.setBusinesses(widget.businesses);
    }
  }

  @override
  void dispose() {
    linkController.dispose();
    if (widget.initialController == null) controller.dispose();
    super.dispose();
  }

  Future<List<EventAttachment>> _pickNativeFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: EventCreationController.allowedExtensions.toList(),
    );
    final result = <EventAttachment>[];
    for (final file in files) {
      final size = file.lengthSync() ?? await file.length();
      if (size == null) {
        throw StateError('No se pudo leer el tamaño de ${file.name}.');
      }
      result.add(EventAttachment(name: file.name, sizeBytes: size));
    }
    return result;
  }

  Future<void> _pickAttachments() async {
    try {
      final files = await (widget.pickAttachments ?? _pickNativeFiles)();
      if (!mounted) return;
      for (final file in files) {
        final error = controller.addAttachment(file);
        if (error != null) _showMessage(error);
      }
    } catch (_) {
      if (mounted) _showMessage('No pudimos seleccionar los archivos.');
    }
  }

  void _addLink() {
    final error = controller.addLink(linkController.text);
    if (error != null) {
      _showMessage(error);
    } else {
      linkController.clear();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _saveDraft() {
    _showMessage('Borrador guardado temporalmente en esta pantalla.');
  }

  Future<void> _publish() async {
    final date = controller.eventDate;
    final start = controller.startTime;
    final end = controller.eventEndDateTime;
    if (date == null || start == null || end == null) {
      _showMessage('Completa los datos del evento antes de publicarlo.');
      return;
    }

    final created = CreatedEventPreview(
      title: controller.name.trim(),
      startsAt: DateTime(
        date.year,
        date.month,
        date.day,
        start.hour,
        start.minute,
      ),
      endsAt: end,
    );
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final continueToCalendar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: EventCreationColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¡Evento creado con éxito!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tu evento ha sido registrado correctamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 29),
              SizedBox(
                width: 175,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EventCreationColors.yellow,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && continueToCalendar == true) {
      Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) => EventCreationTemplate(
    controller: controller,
    linkController: linkController,
    onPickAttachments: _pickAttachments,
    onAddLink: _addLink,
    onClose: () => Navigator.of(context).pop(),
    onDraft: _saveDraft,
    onPublish: _publish,
  );
}

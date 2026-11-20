import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../events/presentation/controllers/event_providers.dart';
import '../../../map/domain/entities/event_coordinates.dart';
import '../controllers/event_creation_controller.dart';
import '../controllers/event_creation_workflow.dart';
import '../event_creation_colors.dart';
import '../../../map/presentation/molecules/location_picker.dart';
import '../templates/event_creation_template.dart';

typedef EventAttachmentPicker = Future<List<EventAttachment>> Function();

class EventCreationPage extends ConsumerStatefulWidget {
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
  ConsumerState<EventCreationPage> createState() => _EventCreationPageState();
}

class _EventCreationPageState extends ConsumerState<EventCreationPage> {
  late final EventCreationController controller =
      widget.initialController ??
      EventCreationController(businesses: widget.businesses);
  final linkController = TextEditingController();
  late final workflow = EventCreationWorkflow(
    controller,
    ref.read(eventUseCasesProvider),
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(workflow.load);
  }

  @override
  void didUpdateWidget(covariant EventCreationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.businesses, widget.businesses)) {
      controller.setBusinesses(widget.businesses);
    }
  }

  @override
  void dispose() {
    workflow.dispose();
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
      if (size > EventCreationController.maxFileBytes) {
        throw StateError('Cada archivo debe tener como máximo 50 MB.');
      }
      result.add(
        EventAttachment(name: file.name, sizeBytes: size, path: file.path),
      );
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

  Future<void> _pickLocation() async {
    final point = await Navigator.of(context).push<EventCoordinates>(
      MaterialPageRoute(
        builder: (_) => LocationPicker(
          initialPoint: controller.coordinates,
          title: 'Ubicación del evento',
          instructions: 'Mueve el mapa para ubicar el evento en el centro.',
        ),
      ),
    );
    if (mounted && point != null) controller.selectCoordinates(point);
  }

  void _addLink() {
    final error = controller.addLink(linkController.text);
    if (error != null) {
      _showMessage(error);
    } else {
      linkController.clear();
    }
  }

  Future<void> _openAttachment(EventAttachment file) async {
    try {
      final XFile shared;
      if (file.path != null) {
        shared = XFile(file.path!);
      } else {
        final bytes = file.bytes ?? await workflow.attachment(file.id!);
        shared = XFile.fromData(bytes, name: file.name);
      }
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [shared],
          fileNameOverrides: [file.name],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      if (mounted) _showMessage(eventError(e));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveDraft() async {
    try {
      if (await workflow.save() && mounted) {
        _showMessage(
          'Borrador guardado. Podrás retomarlo al volver a Crear evento.',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(eventError(error));
    }
  }

  Future<void> _publish() async {
    try {
      final created = await workflow.publish();
      if (!mounted || created == null) return;
      ref.invalidate(organizerEventsProvider);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      final continueToCalendar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: EventCreationColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
    } catch (error) {
      if (mounted) _showMessage(eventError(error));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: workflow,
    builder: (context, child) => Stack(
      children: [
        EventCreationTemplate(
          key: ValueKey(controller.draftId),
          controller: controller,
          linkController: linkController,
          onPickAttachments: _pickAttachments,
          onPickLocation: _pickLocation,
          onAddLink: _addLink,
          onClose: () => Navigator.of(context).pop(),
          onDraft: _saveDraft,
          onPublish: _publish,
          onOpenAttachment: _openAttachment,
        ),
        if (workflow.saving || workflow.initializing)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x99000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ),
  );
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';

import '../../../events/data/event_api.dart';

import '../../domain/created_event_preview.dart';
import '../controllers/event_creation_controller.dart';
import '../event_creation_colors.dart';
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
  bool publishing = false;
  bool initializing = true;
  String? pendingPublication;
  String? categoryError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCategories);
  }

  Future<void> _loadCategories() async {
    setState(() => initializing = true);
    try {
      final api = ref.read(eventApiProvider);
      final values = await api.categories();
      final businesses = await api.businesses();
      final draft = await api.draft();
      if (mounted) {
        setState(() {
          controller.setCategories(values);
          controller.setBusinesses(businesses);
          if (draft != null) controller.restoreDraft(draft);
          categoryError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          categoryError = eventError(e);
          controller.reportError(categoryError!);
        });
      }
    } finally {
      if (mounted) setState(() => initializing = false);
    }
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
        final bytes =
            file.bytes ??
            await ref.read(eventApiProvider).draftAttachment(file.id!);
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

  Future<void> _persistDraft() async {
    final api = ref.read(eventApiProvider);
    controller.draftId = await api.saveDraft(
      controller.draftId,
      controller.draftFields(),
      controller.attachments.map((a) => a.id).whereType<String>().toList(),
    );
    for (var i = 0; i < controller.attachments.length; i++) {
      final file = controller.attachments[i];
      if (file.id == null) {
        final id = await api.uploadAttachment(controller.draftId!, file);
        if (!mounted) return;
        controller.markUploaded(i, id);
      }
    }
  }

  Future<void> _saveDraft() async {
    if (publishing || initializing) return;
    if (categoryError != null) {
      await _loadCategories();
      return;
    }
    if (pendingPublication != null) {
      _showMessage(
        'Vuelve a pulsar Publicar evento para comprobar la publicación pendiente.',
      );
      return;
    }
    setState(() => publishing = true);
    try {
      await _persistDraft();
      if (mounted) {
        _showMessage(
          'Borrador guardado. Podrás retomarlo al volver a Crear evento.',
        );
      }
    } catch (e) {
      if (mounted) _showMessage(eventError(e));
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  Future<void> _publish() async {
    if (publishing || initializing) return;
    if (categoryError != null) {
      await _loadCategories();
      return;
    }
    final validation = pendingPublication == null
        ? controller.validateData()
        : null;
    if (validation != null) {
      _showMessage(validation);
      return;
    }
    if (controller.categories.isEmpty) {
      await _loadCategories();
      return;
    }
    final date = controller.eventDate;
    final start = controller.startTime;
    final end = controller.eventEndDateTime;
    if (pendingPublication == null &&
        (date == null || start == null || end == null)) {
      _showMessage('Completa los datos del evento antes de publicarlo.');
      return;
    }

    setState(() => publishing = true);
    try {
      if (pendingPublication == null) {
        await _persistDraft();
        if (!mounted) return;
        pendingPublication = controller.draftId;
      }
      final result = await ref
          .read(eventApiProvider)
          .publishDraft(pendingPublication!);
      if (!mounted) return;
      ref.invalidate(organizerEventsProvider);
      setState(() => publishing = false);
      final startsAt =
          DateTime.tryParse(result.startsAt ?? '') ??
          (date == null || start == null
              ? null
              : DateTime(
                  date.year,
                  date.month,
                  date.day,
                  start.hour,
                  start.minute,
                ));
      if (startsAt == null) {
        throw StateError('El servidor devolvió una fecha de evento inválida.');
      }
      final created = CreatedEventPreview(
        id: result.id,
        imageUrl: result.imageUrl,
        title: result.title,
        startsAt: startsAt,
        endsAt: DateTime.tryParse(result.endsAt ?? '') ?? end ?? startsAt,
      );
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
    } catch (e) {
      if (e is DioException &&
          e.response != null &&
          e.response!.statusCode! >= 400 &&
          e.response!.statusCode! < 500) {
        pendingPublication = null;
      }
      if (mounted) _showMessage(eventError(e));
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      EventCreationTemplate(
        key: ValueKey(controller.draftId),
        controller: controller,
        linkController: linkController,
        onPickAttachments: _pickAttachments,
        onAddLink: _addLink,
        onClose: () => Navigator.of(context).pop(),
        onDraft: _saveDraft,
        onPublish: _publish,
        onOpenAttachment: _openAttachment,
      ),
      if (publishing || initializing)
        const Positioned.fill(
          child: ColoredBox(
            color: Color(0x99000000),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ],
  );
}

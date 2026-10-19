import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../atoms/event_creation_button.dart';
import '../atoms/event_creation_notch.dart';
import '../controllers/event_creation_controller.dart';
import '../event_creation_colors.dart';
import '../molecules/event_creation_input.dart';
import '../molecules/event_creation_toggle.dart';
import '../molecules/event_link_preview.dart';
import '../organisms/event_creation_progress.dart';

class EventCreationTemplate extends StatelessWidget {
  const EventCreationTemplate({
    super.key,
    required this.controller,
    required this.linkController,
    required this.onPickAttachments,
    required this.onAddLink,
    required this.onClose,
    required this.onDraft,
    required this.onPublish,
  });

  final EventCreationController controller;
  final TextEditingController linkController;
  final VoidCallback onPickAttachments;
  final VoidCallback onAddLink;
  final VoidCallback onClose;
  final VoidCallback onDraft;
  final VoidCallback onPublish;

  static const categories = [
    'Arte',
    'Cultura',
    'Deporte',
    'Gastronomía',
    'Música',
    'Tecnología',
    'Turismo',
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      backgroundColor: EventCreationColors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 68,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    right: 27,
                    bottom: -2,
                    child: EventCreationNotch(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 28, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: controller.step == EventCreationStep.data
                              ? 'Cerrar crear evento'
                              : 'Volver al paso anterior',
                          onPressed: controller.step == EventCreationStep.data
                              ? onClose
                              : controller.previous,
                          icon: Icon(
                            controller.step == EventCreationStep.data
                                ? Icons.close_rounded
                                : Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Transform.translate(
                          offset: const Offset(0, -9),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: EventCreationColors.pink,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                'Crear Evento',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                child: ColoredBox(
                  color: EventCreationColors.blue,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 105,
                        height: 900,
                        child: OverflowBox(
                          minWidth: 900,
                          maxWidth: 900,
                          child: Container(
                            width: 900,
                            height: 900,
                            decoration: const BoxDecoration(
                              color: EventCreationColors.deepBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 47),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: EventCreationProgress(
                                step: controller.step,
                                onPrevious: controller.previous,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _heading(),
                          const SizedBox(height: 22),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 350,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(.06, 0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                    child: KeyedSubtree(
                                      key: ValueKey(controller.step),
                                      child: switch (controller.step) {
                                        EventCreationStep.data => _dataForm(
                                          context,
                                        ),
                                        EventCreationStep.details =>
                                          _detailsForm(),
                                        EventCreationStep.publish =>
                                          _publishForm(),
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (controller.errorMessage case final message?)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                              child: Text(
                                message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          _actions(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _heading() {
    final title = switch (controller.step) {
      EventCreationStep.data => '¡Empecemos!',
      EventCreationStep.details => '¡Dale vida!',
      EventCreationStep.publish => '¡Ya casi!',
    };
    final subtitle = switch (controller.step) {
      EventCreationStep.data => 'Cuéntanos la información de tu evento',
      EventCreationStep.details => 'Agrega imágenes y detalles de tu evento',
      EventCreationStep.publish => 'Publica tu evento o guárdalo para después',
    };
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _dataForm(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EventCreationInput(
        key: ValueKey('business-${controller.selectedBusiness?.id}'),
        hint: 'Negocio (opcional)',
        initialValue: controller.selectedBusiness?.name,
        onChanged: (_) {},
        readOnly: true,
        onTap: () => _selectBusiness(context),
        suffix: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
      const SizedBox(height: 13),
      EventCreationInput(
        hint: 'Nombre del evento',
        initialValue: controller.name,
        onChanged: controller.updateName,
      ),
      const SizedBox(height: 13),
      Row(
        children: [
          Expanded(
            child: EventCreationInput(
              key: ValueKey('category-${controller.category}'),
              hint: 'Categoría',
              initialValue: controller.category,
              onChanged: (_) {},
              readOnly: true,
              onTap: () => _selectCategory(context),
              suffix: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: EventCreationInput(
              key: ValueKey(
                'hours-${controller.startTime}-${controller.endTime}',
              ),
              hint: 'Horarios',
              initialValue: _hoursLabel(),
              onChanged: (_) {},
              readOnly: true,
              onTap: () => _selectHours(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 17,
              ),
              fontSize: 14,
              suffix: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ),
          ),
        ],
      ),
      if (controller.endsNextDay) ...[
        const SizedBox(height: 5),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Finaliza al día siguiente',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ],
      const SizedBox(height: 9),
      const Text(
        'Fecha del evento',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w300,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _dateInput('DD', controller.day, controller.updateDay, 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dateInput(
              'MM',
              controller.month,
              controller.updateMonth,
              2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dateInput('YY', controller.year, controller.updateYear, 4),
          ),
        ],
      ),
      const SizedBox(height: 13),
      EventCreationInput(
        hint: 'Dirección',
        initialValue: controller.address,
        onChanged: controller.updateAddress,
        suffix: Padding(
          padding: const EdgeInsets.all(13),
          child: SvgPicture.asset('assets/images/event_location.svg'),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );

  Widget _dateInput(
    String hint,
    String value,
    ValueChanged<String> onChanged,
    int length,
  ) => EventCreationInput(
    hint: hint,
    initialValue: value,
    onChanged: onChanged,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    maxLength: length,
    textAlign: TextAlign.center,
  );

  Future<void> _selectBusiness(BuildContext context) async {
    final value = await showModalBottomSheet<EventBusiness>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Sin negocio'),
              onTap: () {
                controller.selectBusiness(null);
                Navigator.of(sheetContext).pop();
              },
            ),
            if (controller.businesses.isEmpty)
              const ListTile(
                title: Text('No hay negocios disponibles'),
                subtitle: Text('Puedes continuar sin seleccionar uno.'),
              ),
            for (final business in controller.businesses)
              ListTile(
                title: Text(business.name),
                onTap: () => Navigator.of(sheetContext).pop(business),
              ),
          ],
        ),
      ),
    );
    if (value != null && context.mounted) controller.selectBusiness(value);
  }

  Future<void> _selectCategory(BuildContext context) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final category in categories)
              ListTile(
                title: Text(category),
                onTap: () => Navigator.of(sheetContext).pop(category),
              ),
          ],
        ),
      ),
    );
    if (value != null && context.mounted) controller.updateCategory(value);
  }

  Future<void> _selectHours(BuildContext context) async {
    final start = await showTimePicker(
      context: context,
      initialTime: controller.startTime ?? const TimeOfDay(hour: 18, minute: 0),
      helpText: 'Hora de inicio',
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: controller.endTime ?? const TimeOfDay(hour: 20, minute: 0),
      helpText: 'Hora de finalización',
    );
    if (end == null || !context.mounted) return;
    controller.updateStartTime(start);
    controller.updateEndTime(end);
  }

  String _hoursLabel() {
    final start = controller.startTime;
    final end = controller.endTime;
    if (start == null || end == null) return '';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)}–${two(end.hour)}:${two(end.minute)}';
  }

  Widget _detailsForm() => Column(
    children: [
      Semantics(
        button: true,
        label: 'Subir archivos',
        child: InkWell(
          onTap: onPickAttachments,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: double.infinity,
            height: 148,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/event_upload.svg',
                  width: 57,
                  height: 46,
                ),
                const Text(
                  'Subir archivos',
                  style: TextStyle(
                    color: EventCreationColors.muted,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  'JPG, PNG, PDF o MP4 · Máx. 50 MB',
                  style: TextStyle(
                    color: EventCreationColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (controller.attachments.isNotEmpty) ...[
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (
                var index = 0;
                index < controller.attachments.length;
                index++
              )
                InputChip(
                  label: Text(controller.attachments[index].name),
                  onDeleted: () => controller.removeAttachment(index),
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 13),
      EventCreationInput(
        hint: 'Descripción',
        initialValue: controller.description,
        onChanged: controller.updateDescription,
        maxLength: 200,
        suffix: Padding(
          padding: const EdgeInsets.only(right: 16, top: 18),
          child: Text(
            '${controller.description.length}/200',
            style: const TextStyle(color: EventCreationColors.muted),
          ),
        ),
      ),
      const SizedBox(height: 13),
      EventCreationToggle(
        title: 'El evento es de pago',
        subtitle: 'Los asistentes deben pagar entrada\npara acceder al evento.',
        value: controller.isPaid,
        onChanged: controller.setPaid,
      ),
      const SizedBox(height: 20),
    ],
  );

  Widget _publishForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EventCreationToggle(
        title: 'Limitar a los espectadores',
        subtitle:
            'Solamente las personas mayores de 18 años\npueden ver este evento',
        value: controller.adultsOnly,
        onChanged: controller.setAdultsOnly,
      ),
      const SizedBox(height: 13),
      SizedBox(
        width: 270,
        child: EventCreationInput(
          hint: 'Añadir enlaces de tu evento',
          controller: linkController,
          onChanged: (_) {},
          onSubmitted: (_) => onAddLink(),
          keyboardType: TextInputType.url,
          suffix: IconButton(
            tooltip: 'Añadir enlace',
            icon: const Icon(Icons.add_rounded),
            onPressed: onAddLink,
          ),
        ),
      ),
      if (controller.links.isNotEmpty) ...[
        const SizedBox(height: 12),
        EventLinkPreview(
          links: controller.links,
          onRemove: controller.removeLink,
        ),
      ],
      const SizedBox(height: 20),
    ],
  );

  Widget _actions() => Padding(
    padding: const EdgeInsets.fromLTRB(26, 16, 26, 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: controller.step == EventCreationStep.publish
            ? Row(
                children: [
                  Expanded(
                    child: EventCreationButton(
                      label: 'Guardar Borrador',
                      secondary: true,
                      onPressed: onDraft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EventCreationButton(
                      label: 'Publicar evento',
                      onPressed: onPublish,
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: 183,
                child: EventCreationButton(
                  label: 'Siguiente',
                  onPressed: controller.next,
                ),
              ),
      ),
    ),
  );
}

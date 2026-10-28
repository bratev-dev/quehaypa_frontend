import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/event_creation/presentation/controllers/event_creation_controller.dart';

void main() {
  late EventCreationController controller;

  setUp(() {
    controller = EventCreationController(now: () => DateTime(2026, 6, 1));
  });
  tearDown(() => controller.dispose());

  void fillValidData() {
    controller.updateName('Festival de música');
    controller.updateCategory('Música');
    controller.updateStartTime(const TimeOfDay(hour: 18, minute: 0));
    controller.updateEndTime(const TimeOfDay(hour: 21, minute: 0));
    controller.updateDay('02');
    controller.updateMonth('06');
    controller.updateYear('2026');
    controller.updateAddress('Calle 1 #2-3');
    controller.updateCity('Bogotá');
  }

  group('Datos del evento', () {
    test('impide avanzar hasta completar los campos', () {
      expect(controller.next(), isFalse);
      expect(controller.errorMessage, 'Escribe el nombre del evento.');
      expect(controller.step, EventCreationStep.data);

      fillValidData();
      expect(controller.next(), isTrue);
      expect(controller.step, EventCreationStep.details);
      expect(controller.errorMessage, isNull);
    });

    test('rechaza horas idénticas y fechas imposibles o pasadas', () {
      fillValidData();
      controller.updateEndTime(const TimeOfDay(hour: 18, minute: 0));
      expect(controller.validateData(), contains('diferente'));

      controller.updateEndTime(const TimeOfDay(hour: 21, minute: 0));
      controller.updateDay('31');
      controller.updateMonth('02');
      expect(controller.eventDate, isNull);
      expect(controller.validateData(), 'Ingresa una fecha válida.');

      controller.updateDay('31');
      controller.updateMonth('05');
      expect(
        controller.validateData(),
        'La fecha no puede ser anterior a hoy.',
      );
    });

    test('permite crear un evento sin negocio seleccionado', () {
      fillValidData();
      expect(controller.selectedBusiness, isNull);
      expect(controller.validateData(), isNull);
    });

    test('interpreta la hora final más temprana como el día siguiente', () {
      fillValidData();
      controller.updateStartTime(const TimeOfDay(hour: 22, minute: 0));
      controller.updateEndTime(const TimeOfDay(hour: 4, minute: 0));
      controller.updateDay('30');

      expect(controller.endsNextDay, isTrue);
      expect(controller.eventEndDateTime, DateTime(2026, 7, 1, 4));
      expect(controller.validateData(), isNull);
      expect(controller.next(), isTrue);
    });

    test('conserva el identificador de un negocio de la lista recibida', () {
      const business = EventBusiness(id: 'business-1', name: 'Mi negocio');
      final withBusinesses = EventCreationController(
        businesses: const [business],
      );
      addTearDown(withBusinesses.dispose);

      expect(withBusinesses.businesses.single.id, 'business-1');
      withBusinesses.selectBusiness(business);
      expect(withBusinesses.selectedBusiness?.id, 'business-1');
      withBusinesses.setBusinesses(const [
        EventBusiness(id: 'business-1', name: 'Nombre actualizado'),
      ]);
      expect(withBusinesses.selectedBusiness?.name, 'Nombre actualizado');
      withBusinesses.selectBusiness(null);
      expect(withBusinesses.selectedBusiness, isNull);
    });

    test('acepta año de dos cifras y conserva los datos al retroceder', () {
      fillValidData();
      controller.updateYear('26');
      expect(controller.eventDate, DateTime(2026, 6, 2));
      controller.next();
      controller.updateDescription('Detalles del evento');
      controller.setPaid(true);
      controller.next();
      controller.setAdultsOnly(true);
      controller.previous();
      controller.previous();

      expect(controller.step, EventCreationStep.data);
      expect(controller.name, 'Festival de música');
      expect(controller.description, 'Detalles del evento');
      expect(controller.isPaid, isTrue);
      expect(controller.adultsOnly, isTrue);
    });
  });

  group('Archivos y enlaces', () {
    test('limita la descripción a 200 caracteres', () {
      controller.updateDescription(List.filled(205, 'a').join());
      expect(controller.description.length, 200);
    });

    test('admite los formatos de Figma hasta 50 MB y permite quitarlos', () {
      const max = EventCreationController.maxFileBytes;
      expect(
        controller.addAttachment(
          const EventAttachment(name: 'afiche.PNG', sizeBytes: max),
        ),
        isNull,
      );
      expect(controller.attachments.single.name, 'afiche.PNG');
      expect(
        controller.addAttachment(
          const EventAttachment(name: 'otro.gif', sizeBytes: 100),
        ),
        contains('Formato'),
      );
      expect(
        controller.addAttachment(
          const EventAttachment(name: 'grande.png', sizeBytes: max + 1),
        ),
        contains('50 MB'),
      );
      expect(controller.attachments, hasLength(1));
      controller.removeAttachment(0);
      expect(controller.attachments, isEmpty);
    });

    test('valida, deduplica y elimina enlaces externos', () {
      expect(controller.addLink('instagram.com/evento'), contains('https://'));
      expect(controller.addLink('https://instagram.com/evento'), isNull);
      expect(
        controller.addLink('https://instagram.com/evento'),
        contains('ya fue'),
      );
      expect(controller.links, hasLength(1));
      controller.removeLink(controller.links.single);
      expect(controller.links, isEmpty);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/domain/entities/event_coordinates.dart';
import 'package:frontend/features/event_creation/presentation/controllers/event_creation_controller.dart';
import 'package:frontend/features/events/data/event_api.dart';
import 'package:frontend/features/events/data/repositories/event_repository_impl.dart';
import 'package:frontend/features/events/domain/usecases/event_use_cases.dart';
import 'package:frontend/features/preferences/data/datasources/preferences_remote_data_source.dart';

/// Opt-in. Los tokens se leen del proceso, no se guardan ni se compilan en la app.
void main() {
  const base = String.fromEnvironment('LIVE_API_BASE_URL');
  final organizerToken = Platform.environment['LIVE_ORGANIZER_TOKEN'] ?? '';
  final regularToken = Platform.environment['LIVE_REGULAR_TOKEN'] ?? '';
  test(
    'organizador publica con negocio e imagen y el usuario recibe el evento real',
    () async {
      final dio = Dio(
        BaseOptions(
          baseUrl: base,
          headers: {'Authorization': 'Bearer $organizerToken'},
        ),
      );
      final regular = Dio(
        BaseOptions(
          baseUrl: base,
          headers: {'Authorization': 'Bearer $regularToken'},
        ),
      );
      addTearDown(() {
        dio.close(force: true);
        regular.close(force: true);
      });
      final api = EventApi(dio);
      final actions = EventUseCases(EventRepositoryImpl(api));
      final data = await actions.loadCreation();
      expect(
        data.draft,
        isNull,
        reason: 'No se sobrescriben borradores previos de la cuenta de prueba',
      );
      expect(data.categories, isNotEmpty);
      expect(data.businesses, isNotEmpty);
      final again = await api.businesses();
      expect(
        again.map((business) => business.id),
        data.businesses.map((business) => business.id),
      );
      final date = DateTime.now().add(const Duration(days: 2));
      final form = EventCreationController(businesses: data.businesses)
        ..setCategories(data.categories)
        ..selectBusiness(data.businesses.first)
        ..updateName(
          'QHP112-validación-${DateTime.now().millisecondsSinceEpoch}',
        )
        ..updateCategory(data.categories.first)
        ..updateAddress('Prueba técnica temporal')
        ..selectCoordinates(const EventCoordinates(2.4448, -76.6147))
        ..updateDay('${date.day}')
        ..updateMonth('${date.month}')
        ..updateYear('${date.year}')
        ..updateStartTime(const TimeOfDay(hour: 18, minute: 0))
        ..updateEndTime(const TimeOfDay(hour: 20, minute: 0));
      addTearDown(form.dispose);
      final image = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAQSURBVBhXY2Bg+P+fgTIAAIDDAf9xL9E8AAAAAElFTkSuQmCC',
      );
      form.addAttachment(
        EventAttachment(
          name: 'portada.png',
          sizeBytes: image.length,
          bytes: image,
        ),
      );
      form.draftId = await actions.saveDraft(form.draft());
      final fileId = await actions.uploadAttachment(
        form.draftId!,
        form.attachments.single,
      );
      form.markUploaded(0, fileId);
      expect((await actions.draftAttachment(fileId)), image);
      final restored = (await EventRepositoryImpl(api).draft())!;
      expect(restored.attachments.single.id, fileId);
      final event = await actions.publishDraft(form.draftId!);
      addTearDown(() async {
        await dio.delete<dynamic>('/api/v1/events/${event.id}');
      });
      expect(event.businessId, int.parse(data.businesses.first.id));
      expect(event.imageUrl, isNotNull);
      expect((await actions.publishDraft(form.draftId!)).id, event.id);
      expect(
        (await actions.organizerEvents()).any((value) => value.id == event.id),
        isTrue,
      );
      final publicImage = await regular.get<List<int>>(
        api.publicUrl(event.imageUrl!),
        options: Options(responseType: ResponseType.bytes),
      );
      expect(publicImage.data, image);
      final source = PreferencesRemoteDataSource(dio: regular);
      expect(
        (await source.getFeed()).any((value) => value.id == event.id),
        isTrue,
      );
      expect(
        (await source.getEvents(category: event.category))
            .any((value) => value.id == event.id),
        isTrue,
      );
    },
    skip: base.isEmpty || organizerToken.isEmpty || regularToken.isEmpty
        ? 'Requiere gateway y tokens vigentes de las cuentas de prueba'
        : false,
  );
}

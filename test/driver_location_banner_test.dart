import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/widgets/driver_location_banner.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/l10n.dart';

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState> implements DriverBloc {}

class _MockMaps extends Mock implements MapsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(LocationProblem.denied);
    registerFallbackValue(const DriverLocationTrackingStarted(userId: ''));
  });

  Future<(_MockDriverBloc, _MockMaps)> pump(WidgetTester tester, LocationProblem p, {Locale locale = const Locale('es')}) async {
    final bloc = _MockDriverBloc();
    whenListen(bloc, const Stream<DriverState>.empty(), initialState: const DriverInitial());
    final maps = _MockMaps();
    when(() => maps.fixLocation(any())).thenAnswer((_) async {});
    await tester.pumpWidget(localizedApp(
      BlocProvider<DriverBloc>.value(
        value: bloc,
        child: Scaffold(body: DriverLocationBanner(problem: p, userId: 'd1', maps: maps)),
      ),
      locale: locale,
    ));
    return (bloc, maps);
  }

  testWidgets('GPS off: says so and opens the location settings', (tester) async {
    final (_, maps) = await pump(tester, LocationProblem.serviceOff);
    expect(find.text('Tu ubicación no se está compartiendo'), findsOneWidget);
    expect(find.textContaining('Activa la ubicación (GPS)'), findsOneWidget);
    await tester.tap(find.text('Abrir ajustes'));
    verify(() => maps.fixLocation(LocationProblem.serviceOff)).called(1);
  });

  testWidgets('permission denied: asks again, then retries sharing', (tester) async {
    final (bloc, maps) = await pump(tester, LocationProblem.denied);
    await tester.tap(find.text('Permitir ubicación'));
    await tester.pump();
    verify(() => maps.fixLocation(LocationProblem.denied)).called(1);
    verify(() => bloc.add(const DriverLocationTrackingStarted(userId: 'd1'))).called(1);
  });

  testWidgets('coming back from settings retries by itself', (tester) async {
    final (bloc, _) = await pump(tester, LocationProblem.deniedForever);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    verify(() => bloc.add(const DriverLocationTrackingStarted(userId: 'd1'))).called(1);
  });

  testWidgets('fits a 360px phone in Portuguese', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, LocationProblem.deniedForever, locale: const Locale('pt'));
    expect(find.textContaining('Ajustes → Luxelane Chófer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

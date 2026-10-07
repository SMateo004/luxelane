import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/company/data/company_repository.dart';
import 'package:luxelane/features/company/domain/company.dart';
import 'package:luxelane/features/company/domain/company_statement.dart';
import 'package:luxelane/features/company/presentation/pages/company_portal_page.dart';
import 'package:luxelane/features/company/presentation/widgets/companies_admin_tab.dart';
import 'package:luxelane/features/company/presentation/widgets/company_profile_entry.dart';

import 'helpers/l10n.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

const _acme = Company(
  id: 'acme',
  name: 'Acme SRL',
  taxId: '1234567',
  billingEmail: 'cuentas@acme.bo',
  costCenters: ['Ventas', 'Gerencia'],
);

Booking _b(
  String id,
  DateTime at, {
  BookingStatus status = BookingStatus.completed,
  double price = 200,
  double? finalPrice,
  String rider = 'ana',
  String? costCenter,
  String? reference,
  bool late = false,
  String? passenger,
}) =>
    Booking(
      id: id,
      riderId: rider,
      origin: const Place(address: 'Hotel Los Tajibos', lat: 0, lng: 0),
      destination: const Place(address: 'Aeropuerto Viru Viru', lat: 0, lng: 0),
      scheduledAt: at,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: price,
      finalPrice: finalPrice,
      createdAt: at,
      updatedAt: at,
      companyId: 'acme',
      companyName: 'Acme SRL',
      costCenter: costCenter,
      billingReference: reference,
      lateCancellation: late,
      passengerName: passenger,
    );

final _october = [
  _b('1', DateTime(2026, 10, 2, 8), costCenter: 'Ventas', reference: 'PO-1', finalPrice: 250, passenger: 'Ana Rojas'),
  _b('2', DateTime(2026, 10, 3, 9), costCenter: 'Ventas', rider: 'luis', passenger: 'Cliente, "VIP"'),
  _b('3', DateTime(2026, 10, 4, 9), rider: 'luis'),
  _b('4', DateTime(2026, 10, 5, 9), status: BookingStatus.cancelled, late: true),
  _b('5', DateTime(2026, 10, 9, 9), status: BookingStatus.confirmed),
  _b('6', DateTime(2026, 9, 30, 23), price: 999), // previous month
];

class _FakeRepo implements CompanyRepository {
  _FakeRepo({this.membership, List<Booking>? bookings}) : bookings = bookings ?? _october;

  CompanyMembership? membership;
  final List<Booking> bookings;
  final calls = <String>[];
  String? nextError;

  @override
  Stream<CompanyMembership?> watchMembership(String uid) => Stream.value(membership);
  @override
  Stream<Company?> watchCompany(String companyId) => Stream.value(_acme);
  @override
  Stream<List<Company>> watchAllCompanies() =>
      Stream.value([_acme, const Company(id: 'b', name: 'Beta SA', taxId: '99999', billingEmail: 'b@b.bo', active: false)]);
  @override
  Stream<List<CompanyMember>> watchMembers(String companyId) => Stream.value(const [
        CompanyMember(uid: 'ana', email: 'ana@acme.bo', displayName: 'Ana Rojas', role: CompanyRole.admin),
        CompanyMember(uid: 'luis', email: 'luis@acme.bo', displayName: 'Luis Vaca', role: CompanyRole.member),
      ]);
  @override
  Stream<List<CompanyInvite>> watchInvites(String companyId) =>
      Stream.value(const [CompanyInvite(email: 'nuevo@acme.bo', role: CompanyRole.member)]);
  @override
  Stream<List<Booking>> watchBookings(String companyId, DateTime from, DateTime to) =>
      Stream.value(bookings.where((b) => !b.scheduledAt.isBefore(from) && b.scheduledAt.isBefore(to)).toList());

  Future<String?> _record(String c) async {
    calls.add(c);
    final e = nextError;
    nextError = null;
    return e;
  }

  @override
  Future<String?> createCompany({
    required String name,
    required String taxId,
    required String billingEmail,
    required String adminEmail,
  }) =>
      _record('create:$name:$taxId:$billingEmail:$adminEmail');
  @override
  Future<String?> updateCompany(String companyId,
          {String? name,
          String? taxId,
          String? billingEmail,
          List<String>? costCenters,
          bool? requireCostCenter,
          bool? active}) =>
      _record('update:$companyId:${costCenters?.join('|')}:$requireCostCenter:$active');
  @override
  Future<String?> addMember(String companyId, String email, CompanyRole role) =>
      _record('add:$email:${role.name}');
  @override
  Future<String?> setMemberRole(String companyId, String uid, CompanyRole role) =>
      _record('role:$uid:${role.name}');
  @override
  Future<String?> removeMember(String companyId, String uid) => _record('remove:$uid');
  @override
  Future<String?> cancelInvite(String email) => _record('cancel:$email');
}

final _ana = User(
  id: 'ana',
  email: 'ana@acme.bo',
  phone: '',
  displayName: 'Ana Rojas',
  role: UserRole.rider,
  createdAt: DateTime(2025),
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

Widget _app(Widget child, {Locale locale = const Locale('es'), User? user}) {
  final auth = _MockAuthBloc();
  whenListen(auth, const Stream<AuthState>.empty(), initialState: AuthAuthenticated(user ?? _ana));
  return BlocProvider<AuthBloc>.value(value: auth, child: localizedApp(child, locale: locale));
}

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('CompanyStatement', () {
    final st = CompanyStatement.compute(_october, DateTime(2026, 10, 15));

    test('bills completed rides of the month only', () {
      expect(st.month, DateTime(2026, 10));
      expect(st.bookings, hasLength(5));
      expect(st.completed, 3);
      expect(st.total, 250 + 200 + 200);
      expect(st.upcoming, 1);
      expect(st.cancelled, 1);
      expect(st.lateCancellations, 1);
    });

    test('groups by cost center and traveler, biggest first', () {
      expect(st.byCostCenter.map((g) => (g.key, g.trips, g.amount)), [('Ventas', 2, 450.0), (null, 1, 200.0)]);
      expect(st.byTraveler.map((g) => (g.key, g.amount)), [('luis', 400.0), ('ana', 250.0)]);
    });

    test('CSV lists billed rides, escaped', () {
      final csv = st.csv(
        headers: const ['Fecha', 'Por', 'Pasajero', 'Origen', 'Destino', 'Vehículo', 'CC', 'Ref', 'Bs'],
        date: (b) => '${b.scheduledAt.day}',
        traveler: (b) => b.riderId,
        vehicle: (b) => 'Business',
      );
      final lines = csv.trim().split('\n');
      expect(lines, hasLength(4));
      expect(lines.first, 'Fecha,Por,Pasajero,Origen,Destino,Vehículo,CC,Ref,Bs');
      expect(lines, contains('3,luis,"Cliente, ""VIP""",Hotel Los Tajibos,Aeropuerto Viru Viru,Business,Ventas,,200.00'));
      expect(lines, contains('2,ana,Ana Rojas,Hotel Los Tajibos,Aeropuerto Viru Viru,Business,Ventas,PO-1,250.00'));
    });
  });

  group('CompanyErrorCodes', () {
    test('maps server messages', () {
      expect(CompanyErrorCodes.fromMessage('company/last-admin'), CompanyErrorCodes.lastAdmin);
      expect(CompanyErrorCodes.fromMessage('boom'), CompanyErrorCodes.failed);
      expect(CompanyErrorCodes.fromMessage(null), CompanyErrorCodes.failed);
    });
  });

  group('CompanyPortalPage', () {
    for (final size in const [Size(390, 900), Size(1280, 900)]) {
      testWidgets('statement for a company admin (${size.width.toInt()}px)', (tester) async {
        await _size(tester, size);
        final repo = _FakeRepo(membership: const CompanyMembership('acme', CompanyRole.admin));
        await tester.pumpWidget(_app(CompanyPortalPage(repository: repo, now: DateTime(2026, 10, 7))));
        await tester.pumpAndSettle();

        expect(find.text('Acme SRL'), findsOneWidget);
        expect(find.text('Estado de cuenta'), findsOneWidget);
        expect(find.text('A facturar'), findsOneWidget);
        expect(find.text('Por centro de costo'), findsOneWidget);
        expect(find.text('Sin centro de costo'), findsOneWidget);
        expect(find.text('Luis Vaca'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Previous month: only the 30 Sep ride.
        await tester.tap(find.byTooltip('Mes anterior'));
        await tester.pumpAndSettle();
        expect(find.text('Luis Vaca'), findsNothing);
        expect(find.text('Ana Rojas'), findsWidgets);
      });
    }

    testWidgets('members can not open the portal', (tester) async {
      final repo = _FakeRepo(membership: const CompanyMembership('acme', CompanyRole.member));
      await tester.pumpWidget(_app(CompanyPortalPage(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Solo los administradores de la empresa pueden ver este portal.'), findsOneWidget);
    });

    testWidgets('members tab adds, promotes and lists invites', (tester) async {
      await _size(tester, const Size(390, 1200));
      final repo = _FakeRepo(membership: const CompanyMembership('acme', CompanyRole.admin));
      await tester.pumpWidget(_app(CompanyPortalPage(repository: repo, now: DateTime(2026, 10, 7))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Miembros').first);
      await tester.pumpAndSettle();

      expect(find.text('nuevo@acme.bo'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'pedro@acme.bo');
      await tester.tap(find.text('AGREGAR'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['add:pedro@acme.bo:member']);

      await tester.tap(find.byTooltip('Opciones del miembro').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer administrador'));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'role:luis:admin');

      repo.nextError = CompanyErrorCodes.lastAdmin;
      await tester.tap(find.byTooltip('Opciones del miembro').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar permisos de administrador'));
      await tester.pumpAndSettle();
      expect(find.text('La empresa necesita al menos un administrador.'), findsOneWidget);
    });

    testWidgets('settings saves cost centers', (tester) async {
      await _size(tester, const Size(390, 1400));
      final repo = _FakeRepo(membership: const CompanyMembership('acme', CompanyRole.admin));
      await tester.pumpWidget(_app(CompanyPortalPage(repository: repo, now: DateTime(2026, 10, 7)),
          locale: const Locale('en')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'New cost center'), 'Marketing');
      await tester.tap(find.byTooltip('Add cost center'));
      await tester.pump();
      await tester.tap(find.text('Require a cost center'));
      await tester.pump();
      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['update:acme:Ventas|Gerencia|Marketing:true:null']);
      expect(find.text('Changes saved'), findsOneWidget);
    });
  });

  testWidgets('admin tab lists companies and creates one (pt)', (tester) async {
    await _size(tester, const Size(1280, 900));
    final repo = _FakeRepo();
    await tester.pumpWidget(_app(Scaffold(body: CompaniesAdminTab(repository: repo)), locale: const Locale('pt')));
    await tester.pumpAndSettle();
    expect(find.text('Contas corporativas'), findsOneWidget);
    expect(find.text('Beta SA'), findsOneWidget);

    await tester.tap(find.text('NOVA EMPRESA'));
    await tester.pumpAndSettle();
    final fields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(fields.at(0), 'Gamma');
    await tester.enterText(fields.at(1), '55555');
    await tester.enterText(fields.at(2), 'f@g.bo');
    await tester.enterText(fields.at(3), 'boss@g.bo');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['create:Gamma:55555:f@g.bo:boss@g.bo']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('profile entry: admins get the portal link, others nothing', (tester) async {
    final repo = _FakeRepo(membership: const CompanyMembership('acme', CompanyRole.admin));
    await tester.pumpWidget(_app(Scaffold(body: CompanyProfileEntry(uid: 'ana', repository: repo))));
    await tester.pumpAndSettle();
    expect(find.text('Acme SRL'), findsOneWidget);
    expect(find.textContaining('Administras esta cuenta'), findsOneWidget);

    await tester.pumpWidget(_app(Scaffold(body: CompanyProfileEntry(uid: 'x', repository: _FakeRepo()))));
    await tester.pumpAndSettle();
    expect(find.text('Acme SRL'), findsNothing);
  });
}

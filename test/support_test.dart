import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/support/data/support_repository.dart';
import 'package:luxelane/features/support/domain/support_ticket.dart';
import 'package:luxelane/features/support/presentation/pages/help_center_page.dart';
import 'package:luxelane/features/support/presentation/pages/ticket_thread_page.dart';
import 'package:luxelane/features/support/presentation/widgets/support_admin_tab.dart';

import 'helpers/l10n.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

SupportTicket _t(String id, TicketStatus s, {bool urgent = false, int minute = 0, bool unreadUser = false, bool unreadAdmin = false}) =>
    SupportTicket(
      id: id,
      userId: 'ana',
      userName: 'Ana Rojas',
      userRole: 'rider',
      category: urgent ? TicketCategory.safety : TicketCategory.lostItem,
      subject: 'Ticket $id',
      status: s,
      urgent: urgent,
      lastMessageAt: DateTime(2026, 10, 7, 10, minute),
      lastMessagePreview: 'Mensaje $id',
      unreadForUser: unreadUser,
      unreadForAdmin: unreadAdmin,
      bookingId: id == 'b' ? 'abcdef123456' : null,
    );

class _FakeRepo implements SupportRepository {
  _FakeRepo(this.tickets, {this.messages = const {}});
  final List<SupportTicket> tickets;
  final Map<String, List<SupportMessage>> messages;
  final calls = <String>[];

  @override
  Stream<List<SupportTicket>> watchMyTickets(String userId) => Stream.value(tickets);
  @override
  Stream<List<SupportTicket>> watchAllTickets() => Stream.value(tickets);
  @override
  Stream<SupportTicket?> watchTicket(String ticketId) =>
      Stream.value(tickets.where((t) => t.id == ticketId).firstOrNull);
  @override
  Stream<List<SupportMessage>> watchMessages(String ticketId) => Stream.value(messages[ticketId] ?? const []);

  @override
  Future<String> createTicket({
    required User user,
    required TicketCategory category,
    required String subject,
    required String message,
    String? bookingId,
  }) async {
    calls.add('create:${user.id}:${category.name}:$subject:$message:$bookingId');
    return 'a';
  }

  @override
  Future<void> sendMessage({required String ticketId, required User author, required String text, required bool asTeam}) async =>
      calls.add('send:$ticketId:$text:$asTeam');
  @override
  Future<void> markRead(String ticketId, {required bool asTeam}) async => calls.add('read:$ticketId:$asTeam');
  @override
  Future<void> setStatus(String ticketId, TicketStatus status) async => calls.add('status:$ticketId:${status.name}');
}

User _user(UserRole role) => User(
      id: role == UserRole.admin ? 'boss' : 'ana',
      email: 'x@x.bo',
      phone: '',
      displayName: role == UserRole.admin ? 'Soporte' : 'Ana Rojas',
      role: role,
      createdAt: DateTime(2025),
      isVerified: true,
      isActive: true,
      fcmTokens: const [],
    );

Widget _app(Widget child, {Locale locale = const Locale('es'), UserRole role = UserRole.rider}) {
  final auth = _MockAuthBloc();
  whenListen(auth, const Stream<AuthState>.empty(), initialState: AuthAuthenticated(_user(role)));
  return BlocProvider<AuthBloc>.value(value: auth, child: localizedApp(child, locale: locale));
}

Future<void> _size(WidgetTester t, Size s) async {
  t.view
    ..physicalSize = s
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() => initializeDateFormatting());

  test('queue order: urgent open, open, answered, resolved; newest first', () {
    final sorted = sortForQueue([
      _t('r', TicketStatus.resolved, minute: 50),
      _t('o1', TicketStatus.open, minute: 10),
      _t('ans', TicketStatus.answered, minute: 40),
      _t('u', TicketStatus.open, urgent: true, minute: 1),
      _t('o2', TicketStatus.open, minute: 30),
    ]);
    expect(sorted.map((t) => t.id), ['u', 'o2', 'o1', 'ans', 'r']);
  });

  group('HelpCenterPage', () {
    for (final size in const [Size(360, 2000), Size(1280, 1600)]) {
      testWidgets('FAQ, my requests and a new request (${size.width.toInt()}px)', (tester) async {
        await _size(tester, size);
        final semantics = tester.ensureSemantics();
        final repo = _FakeRepo([_t('a', TicketStatus.answered, unreadUser: true)]);
        await tester.pumpWidget(_app(HelpCenterPage(repository: repo)));
        await tester.pumpAndSettle();

        expect(find.text('Preguntas frecuentes'), findsOneWidget);
        expect(find.text('Mis solicitudes'), findsOneWidget);
        expect(find.text('Respondida'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('No leída')), findsWidgets);
        semantics.dispose();

        // FAQ answers use the real waiting policy.
        await tester.tap(find.text('¿Cuánto tiempo me espera el chófer?'));
        await tester.pumpAndSettle();
        expect(find.textContaining('60 minutos gratis'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('NUEVA SOLICITUD'));
        await tester.pumpAndSettle();
        // Validation: nothing chosen yet.
        await tester.tap(find.text('ENVIAR'));
        await tester.pumpAndSettle();
        expect(find.text('Elige una opción.'), findsOneWidget);
        expect(repo.calls, isEmpty);

        await tester.tap(find.text('Objeto olvidado'));
        await tester.pump();
        await tester.enterText(find.byType(TextField).at(0), 'Paraguas');
        await tester.pump();
        await tester.enterText(find.byType(TextField).at(1), 'Lo dejé en el asiento trasero');
        await tester.ensureVisible(find.text('ENVIAR'));
        await tester.tap(find.text('ENVIAR'));
        await tester.pumpAndSettle();
        expect(repo.calls.first, 'create:ana:lostItem:Paraguas:Lo dejé en el asiento trasero:null');
        // Lands on the conversation.
        expect(find.byType(TicketThreadPage), findsOneWidget);
      });
    }

    testWidgets('trip help pre-selects the trip category; safety shows the emergency note (en)', (tester) async {
      await _size(tester, const Size(390, 1600));
      final repo = _FakeRepo(const []);
      await tester.pumpWidget(_app(HelpCenterPage(repository: repo, bookingId: 'abcdef123456'), locale: const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('Help with this trip'), findsOneWidget);
      await tester.tap(find.text('NEW REQUEST'));
      await tester.pumpAndSettle();
      expect(find.text('Linked to trip ABCDEF12'), findsOneWidget);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'A trip')).selected, isTrue);
      await tester.tap(find.text('Safety'));
      await tester.pumpAndSettle();
      expect(find.textContaining('call 110'), findsOneWidget);
    });
  });

  group('TicketThreadPage', () {
    final msgs = {
      'a': [
        SupportMessage(id: '1', authorId: 'ana', fromTeam: false, authorName: 'Ana Rojas', text: 'Olvidé mi paraguas', createdAt: DateTime(2026, 10, 7, 9)),
        SupportMessage(id: '2', authorId: 'boss', fromTeam: true, authorName: 'Soporte', text: 'Ya contactamos al chófer', createdAt: DateTime(2026, 10, 7, 10)),
      ],
    };

    testWidgets('customer reads, replies and resolves', (tester) async {
      await _size(tester, const Size(390, 900));
      final repo = _FakeRepo([_t('a', TicketStatus.answered, unreadUser: true)], messages: msgs);
      await tester.pumpWidget(_app(TicketThreadPage(ticketId: 'a', repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Equipo Luxelane · 7 oct 10:00'), findsOneWidget);
      expect(find.text('Ya contactamos al chófer'), findsOneWidget);
      expect(repo.calls, contains('read:a:false'));

      await tester.enterText(find.byType(TextField), 'Gracias, ¿cuándo lo recibo?');
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('send:a:Gracias, ¿cuándo lo recibo?:false'));

      await tester.tap(find.text('Ya está resuelto'));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'status:a:resolved');
    });

    testWidgets('team answers as the team and can reopen', (tester) async {
      final repo = _FakeRepo([_t('a', TicketStatus.resolved, unreadAdmin: true)], messages: msgs);
      await tester.pumpWidget(_app(TicketThreadPage(ticketId: 'a', repository: repo, asTeam: true), role: UserRole.admin));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ana Rojas (Pasajero)'), findsOneWidget);
      expect(repo.calls, contains('read:a:true'));
      await tester.enterText(find.byType(TextField), 'Te lo llevamos mañana');
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('send:a:Te lo llevamos mañana:true'));
      await tester.tap(find.text('Reabrir'));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'status:a:open');
    });
  });

  testWidgets('admin queue: urgent banner and filters (pt)', (tester) async {
    await _size(tester, const Size(1280, 1200));
    final repo = _FakeRepo([
      _t('u', TicketStatus.open, urgent: true),
      _t('o', TicketStatus.open, unreadAdmin: true),
      _t('ans', TicketStatus.answered),
      _t('r', TicketStatus.resolved),
    ]);
    await tester.pumpWidget(_app(Scaffold(body: SupportAdminTab(repository: repo)), locale: const Locale('pt'), role: UserRole.admin));
    await tester.pumpAndSettle();
    expect(find.text('1 relato de segurança sem resposta'), findsOneWidget);
    expect(find.text('A responder (2)'), findsOneWidget);
    expect(find.text('Ticket u'), findsOneWidget);
    expect(find.text('Ticket ans'), findsNothing);

    await tester.tap(find.text('Resolvidas'));
    await tester.pumpAndSettle();
    expect(find.text('Ticket r'), findsOneWidget);
    expect(find.text('Ticket u'), findsNothing);
  });
}

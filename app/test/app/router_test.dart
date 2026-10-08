import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/router.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';

Membership m(MemberStatus status) => Membership(
  member: Member(
    id: 'm-$status',
    messId: 'x-$status',
    displayName: 'A',
    role: MemberRole.member,
    status: status,
    joinedOn: DateTime(2026),
  ),
);

/// Follows redirects to the final location, like go_router does.
String land(
  String location, {
  bool signedIn = true,
  bool profileComplete = true,
  List<Membership>? memberships = const [],
}) {
  for (var i = 0; i < 10; i++) {
    final next = decideRedirect(
      signedIn: signedIn,
      profileComplete: profileComplete,
      memberships: memberships,
      location: location,
    );
    if (next == null) return location;
    location = next;
  }
  throw StateError('redirect loop at $location');
}

void main() {
  final active = [m(MemberStatus.active)];
  final pending = [m(MemberStatus.pending)];

  test('signed out always lands on phone', () {
    expect(land('/', signedIn: false), '/auth/phone');
    expect(land('/today', signedIn: false), '/auth/phone');
    expect(land('/auth/profile', signedIn: false), '/auth/phone');
  });

  test('missing name lands on profile setup', () {
    expect(land('/today', profileComplete: false), '/auth/profile');
    expect(land('/auth/phone', profileComplete: false), '/auth/profile');
  });

  test('memberships still loading: stay put', () {
    expect(land('/auth/phone', memberships: null), '/auth/phone');
  });

  test('no memberships → onboarding, create/join allowed', () {
    expect(land('/'), '/onboarding');
    expect(land('/today'), '/onboarding');
    expect(land('/onboarding/create'), '/onboarding/create');
    expect(land('/onboarding/join'), '/onboarding/join');
    expect(land('/pending'), '/onboarding');
    // Left/inactive only counts as no mess.
    expect(land('/today', memberships: [m(MemberStatus.left)]), '/onboarding');
  });

  test('only pending → /pending', () {
    expect(land('/today', memberships: pending), '/pending');
    expect(land('/', memberships: pending), '/pending');
    expect(land('/more', memberships: pending), '/pending');
    // "Join another mess" from the pending screen.
    expect(land('/onboarding/join', memberships: pending), '/onboarding/join');
    expect(land('/pending', memberships: pending), '/pending');
  });

  test('active → shell, default /today', () {
    expect(land('/', memberships: active), '/today');
    expect(land('/auth/phone', memberships: active), '/today');
    expect(land('/pending', memberships: active), '/today');
    expect(land('/more/members', memberships: active), '/more/members');
    expect(land('/money', memberships: [...pending, ...active]), '/money');
  });

  test('invite deep link survives sign-in and profile setup', () {
    expect(land('/join/AB12', signedIn: false), '/auth/phone?code=AB12');
    expect(
      land('/auth/phone?code=AB12', profileComplete: false),
      '/auth/profile?code=AB12',
    );
    expect(land('/auth/profile?code=AB12'), '/onboarding/join?code=AB12');
    expect(land('/join/AB12'), '/onboarding/join?code=AB12');
    expect(
      land('/join/AB12', memberships: active),
      '/onboarding/join?code=AB12',
    );
  });
}

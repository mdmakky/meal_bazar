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
  bool recovering = false,
  bool profileComplete = true,
  List<Membership>? memberships = const [],
}) {
  for (var i = 0; i < 10; i++) {
    final next = decideRedirect(
      signedIn: signedIn,
      recovering: recovering,
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

  test('reset-code screen is reachable signed out', () {
    expect(land('/auth/reset-code', signedIn: false), '/auth/reset-code');
    expect(land('/auth/reset-code', memberships: active), '/today');
  });

  test('signed out always lands on sign-in', () {
    expect(land('/', signedIn: false), '/auth/sign-in');
    expect(land('/today', signedIn: false), '/auth/sign-in');
    expect(land('/auth/profile', signedIn: false), '/auth/sign-in');
  });

  test('password recovery holds the user on reset-password', () {
    for (final from in ['/', '/today', '/auth/sign-in', '/onboarding']) {
      expect(land(from, recovering: true), '/auth/reset-password');
    }
    expect(
      land('/auth/reset-password', recovering: true, profileComplete: false),
      '/auth/reset-password',
    );
    expect(land('/auth/reset-password', memberships: active), '/today');
    expect(land('/auth/reset-password', signedIn: false), '/auth/sign-in');
  });

  test('missing name lands on profile setup', () {
    expect(land('/today', profileComplete: false), '/auth/profile');
    expect(land('/auth/sign-in', profileComplete: false), '/auth/profile');
  });

  test('memberships still loading: stay put', () {
    expect(land('/auth/sign-in', memberships: null), '/auth/sign-in');
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
    expect(land('/auth/sign-in', memberships: active), '/today');
    expect(land('/pending', memberships: active), '/today');
    expect(land('/more/members', memberships: active), '/more/members');
    expect(land('/money', memberships: [...pending, ...active]), '/money');
    // The 5 tabs.
    for (final tab in ['/today', '/meals', '/bazar', '/money', '/more']) {
      expect(land(tab, memberships: active), tab);
    }
    expect(land('/bazar', signedIn: false), '/auth/sign-in');
  });

  test('a 10-char link invite carries through a signed-out start', () {
    expect(
      land('/join/K7MQ2XW9ZA', signedIn: false),
      '/auth/sign-in?code=K7MQ2XW9ZA',
    );
    expect(
      land('/auth/profile?code=K7MQ2XW9ZA'),
      '/onboarding/join?code=K7MQ2XW9ZA',
    );
  });

  test('invite deep link survives sign-in and profile setup', () {
    expect(land('/join/AB12', signedIn: false), '/auth/sign-in?code=AB12');
    expect(
      land('/auth/sign-in?code=AB12', signedIn: false),
      '/auth/sign-in?code=AB12',
    );
    expect(
      land('/auth/sign-in?code=AB12', profileComplete: false),
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

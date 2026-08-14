import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/build_info.dart';

/// The label under Settings exists to tell a running build apart from the one
/// you just compiled, so it has to stay readable in every case.
void main() {
  test('shows version and build number together', () {
    // No define in a plain test run, so this is the un-stamped shape.
    expect(
      buildLabel(version: '1.0.10', buildNumber: '10'),
      kBuildStamp.isEmpty ? '1.0.10+10' : '1.0.10+10 · $kBuildStamp',
    );
  });

  test('omits the build number when the platform reports none', () {
    expect(
      buildLabel(version: '1.0.10', buildNumber: ''),
      kBuildStamp.isEmpty ? '1.0.10' : '1.0.10 · $kBuildStamp',
    );
  });
}

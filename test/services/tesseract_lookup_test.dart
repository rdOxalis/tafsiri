import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/services/ocr/tesseract_ocr_service.dart';

/// Finding the engine at all (ADR-051). A desktop application does not get the
/// `PATH` a terminal shows it, which is why a correct Homebrew install was
/// reported as "Tesseract is not installed" on macOS.
void main() {
  /// A filesystem where only [present] exists.
  bool Function(String) only(List<String> present) => present.contains;

  String resolve({
    String configured = 'tesseract',
    required String os,
    String? path,
    required List<String> present,
  }) =>
      resolveTesseract(
        configured: configured,
        operatingSystem: os,
        pathVariable: path,
        exists: only(present),
      );

  group('macOS', () {
    test('finds Homebrew on Apple silicon when PATH is the bare minimum', () {
      // What `flutter run -d macos` and a double-click from Finder actually
      // hand the process. /opt/homebrew is nowhere in it.
      expect(
        resolve(
          os: 'macos',
          path: '/usr/bin:/bin:/usr/sbin:/sbin',
          present: ['/opt/homebrew/bin/tesseract'],
        ),
        '/opt/homebrew/bin/tesseract',
      );
    });

    test('finds an Intel Homebrew install too', () {
      expect(
        resolve(
          os: 'macos',
          path: '/usr/bin:/bin',
          present: ['/usr/local/bin/tesseract'],
        ),
        '/usr/local/bin/tesseract',
      );
    });
  });

  group('Windows', () {
    test('finds the default install without a PATH entry', () {
      // Spares the user the PATH edit and the sign-out that makes it take
      // effect — Explorer reads the environment once, at login.
      expect(
        resolve(
          os: 'windows',
          path: r'C:\Windows\system32;C:\Windows',
          present: [r'C:\Program Files\Tesseract-OCR\tesseract.exe'],
        ),
        r'C:\Program Files\Tesseract-OCR\tesseract.exe',
      );
    });

    test('looks for the .exe, not the bare name', () {
      expect(
        resolve(
          os: 'windows',
          path: r'C:\tools',
          present: [r'C:\tools\tesseract.exe'],
        ),
        r'C:\tools\tesseract.exe',
      );
    });

    test('splits PATH on semicolons there and colons elsewhere', () {
      // A Windows PATH split on ':' would tear 'C:\tools' in half.
      expect(
        resolve(
          os: 'windows',
          path: r'C:\tools;C:\other',
          present: [r'C:\other\tesseract.exe'],
        ),
        r'C:\other\tesseract.exe',
      );
    });
  });

  group('precedence', () {
    test('PATH wins over the well-known locations', () {
      // Someone who put a particular build first on their PATH meant it.
      expect(
        resolve(
          os: 'macos',
          path: '/opt/mine/bin:/usr/bin',
          present: ['/opt/mine/bin/tesseract', '/opt/homebrew/bin/tesseract'],
        ),
        '/opt/mine/bin/tesseract',
      );
    });

    test('an explicitly configured path is an instruction, not a hint', () {
      expect(
        resolve(
          configured: '/somewhere/else/tesseract',
          os: 'macos',
          path: '/usr/bin',
          present: ['/opt/homebrew/bin/tesseract', '/usr/bin/tesseract'],
        ),
        '/somewhere/else/tesseract',
      );
    });

    test('falls back to the bare name when nothing is anywhere', () {
      // So Process.run raises the real "not found", which is what
      // OcrUnavailableException reports.
      expect(
        resolve(os: 'linux', path: '/usr/bin:/bin', present: []),
        'tesseract',
      );
    });

    test('an empty or absent PATH does not confuse the search', () {
      expect(
        resolve(os: 'macos', path: null, present: ['/usr/local/bin/tesseract']),
        '/usr/local/bin/tesseract',
      );
      expect(
        resolve(os: 'macos', path: '', present: ['/usr/local/bin/tesseract']),
        '/usr/local/bin/tesseract',
      );
    });
  });

  test('Linux keeps resolving through PATH as it always did', () {
    expect(
      resolve(
        os: 'linux',
        path: '/usr/local/sbin:/usr/bin',
        present: ['/usr/bin/tesseract'],
      ),
      '/usr/bin/tesseract',
    );
  });
}

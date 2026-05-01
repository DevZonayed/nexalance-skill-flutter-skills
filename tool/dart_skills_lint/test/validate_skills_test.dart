// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_skills_lint/dart_skills_lint.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('Skills Validation', () {
    setUpAll(() {
      // Enable logging to see detailed validation errors in test output.
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) => print(record.message)); // ignore: avoid_print
    });

    test('validate_published_skills', () async {
      final bool isValid = await validateSkills(
        skillDirPaths: ['skills'],
        resolvedRules: {
          'check-dart-code-blocks': AnalysisSeverity.error,
          'disallowed-field': AnalysisSeverity.error,
        },
      );
      expect(isValid, isTrue, reason: 'Skills in "skills" directory failed validation.');
    });

    test('validate_contributor_skills', () async {
      final bool isValid = await validateSkills(
        skillDirPaths: ['.agents/skills'],
        resolvedRules: {
          'check-dart-code-blocks': AnalysisSeverity.error,
          'disallowed-field': AnalysisSeverity.error,
        },
      );
      expect(isValid, isTrue, reason: 'Skills in ".agents/skills" directory failed validation.');
    });
  });
}

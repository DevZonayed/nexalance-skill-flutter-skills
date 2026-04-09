// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'models/analysis_severity.dart';
import 'models/check_type.dart';
import 'models/skill_context.dart';
import 'models/skill_rule.dart';
import 'models/validation_error.dart';
import 'rules.dart';
import 'rules/absolute_paths_rule.dart';
import 'rules/description_length_rule.dart';
import 'rules/disallowed_field_rule.dart';
import 'rules/name_format_rule.dart';
import 'rules/relative_paths_rule.dart';
import 'rules/valid_yaml_metadata_rule.dart';

final _log = Logger('dart_skills_lint');

/// The result of a skill directory validation attempt.
class ValidationResult {
  ValidationResult({
    this.validationErrors = const [],
    List<String> warnings = const [],
  }) : _manualWarnings = warnings;

  /// Whether the skill directory is valid according to the specification.
  bool get isValid =>
      !validationErrors.any((e) => e.severity == AnalysisSeverity.error && !e.isIgnored);

  /// A list of structured validation errors found.
  final List<ValidationError> validationErrors;

  final List<String> _manualWarnings;

  /// A list of error messages for failing checks (excluding ignored ones).
  List<String> get errors => validationErrors
      .where((e) => e.severity == AnalysisSeverity.error && !e.isIgnored)
      .map((e) => e.message)
      .toList();

  /// A list of warning messages for suboptimal setups or recommendations.
  List<String> get warnings => [
        ..._manualWarnings,
        ...validationErrors
            .where((e) => e.severity == AnalysisSeverity.warning && !e.isIgnored)
            .map((e) => e.message),
      ];
}

/// Validates agent skill directories against the Agent Skills specification.
class Validator {
  Validator({
    Map<String, AnalysisSeverity>? ruleOverrides,
    List<SkillRule>? customRules,
  })  : _ruleOverrides = ruleOverrides ?? {},
        _customRules = customRules ?? [];
  static const _skillFileName = 'SKILL.md';

  final Map<String, AnalysisSeverity> _ruleOverrides;
  final List<SkillRule> _customRules;

  AnalysisSeverity _getSeverity(CheckType rule) {
    return _ruleOverrides[rule.name] ?? rule.defaultSeverity;
  }

  static final _skillStartRegex = RegExp(r'^---\s*\n(.*?)\n---\s*\n', dotAll: true);

  /// Validates a single skill directory.
  ///
  /// Scans the directory for `SKILL.md`, parses its YAML metadata, and validates
  /// constraints like name format and field lengths using registered rules.
  Future<ValidationResult> validate(Directory dir) async {
    final validationErrors = <ValidationError>[];

    final bool isValidDir = await _checkDirectoryStructure(dir, validationErrors);
    if (!isValidDir) {
      return ValidationResult(validationErrors: validationErrors);
    }

    final skillMdFile = File(p.join(dir.path, _skillFileName));
    final String content = await skillMdFile.readAsString();

    YamlMap? parsedYaml;
    String? yamlParsingError;
    try {
      final RegExpMatch? match = _skillStartRegex.firstMatch(content);
      if (match != null) {
        final String yamlStr = match.group(1)!;
        final Object? doc = loadYaml(yamlStr);
        if (doc is YamlMap) {
          parsedYaml = doc;
        } else {
          yamlParsingError = 'YAML frontmatter is not a map';
        }
      } else {
        yamlParsingError = 'Missing YAML metadata in $_skillFileName';
      }
    } catch (e) {
      yamlParsingError = 'Failed to parse YAML: $e';
    }

    final context = SkillContext(
      directory: dir,
      rawContent: content,
      parsedYaml: parsedYaml,
      yamlParsingError: yamlParsingError,
    );

    final List<SkillRule> rules = _buildRules();

    for (final rule in rules) {
      final List<ValidationError> errors = await rule.validate(context);
      for (final error in errors) {
        if (error.severity != rule.severity) {
          _log.warning(
              'Rule "${rule.name}" used severity ${error.severity} instead of defined ${rule.severity}.');
        }
      }
      validationErrors.addAll(errors);
    }

    return ValidationResult(
      validationErrors: validationErrors,
    );
  }

  List<SkillRule> _buildRules() {
    final rules = <SkillRule>[];
    final seenNames = <String>{};

    void addRule(SkillRule rule) {
      if (rule.severity != AnalysisSeverity.disabled) {
        if (seenNames.contains(rule.name)) {
          throw ArgumentError('Duplicate rule name detected: ${rule.name}');
        }
        seenNames.add(rule.name);
        rules.add(rule);
      }
    }

    addRule(ValidYamlMetadataRule(severity: _getSeverity(validYamlMetadataCheck)));
    addRule(DisallowedFieldRule(severity: _getSeverity(disallowedFieldCheck)));
    addRule(NameFormatRule(severity: _getSeverity(invalidSkillNameCheck)));
    addRule(AbsolutePathsRule(severity: _getSeverity(absolutePathsCheck)));
    addRule(RelativePathsRule(severity: _getSeverity(relativePathsCheck)));
    addRule(DescriptionLengthRule(severity: _getSeverity(descriptionTooLongCheck)));

    _customRules.forEach(addRule);

    return rules;
  }

  Future<bool> _checkDirectoryStructure(
      Directory dir, List<ValidationError> validationErrors) async {
    if (!dir.existsSync()) {
      if (File(dir.path).existsSync()) {
        validationErrors.add(ValidationError(
            ruleId: pathDoesNotExistCheck.name,
            file: dir.path,
            message: 'Path is not a directory: ${dir.path} (see $dirStructureUrl)',
            severity: _getSeverity(pathDoesNotExistCheck)));
      } else {
        validationErrors.add(ValidationError(
            ruleId: pathDoesNotExistCheck.name,
            file: dir.path,
            message: 'Directory does not exist: ${dir.path} (see $dirStructureUrl)',
            severity: _getSeverity(pathDoesNotExistCheck)));
      }
      return false;
    }

    final skillMdFile = File(p.join(dir.path, _skillFileName));
    if (!skillMdFile.existsSync()) {
      validationErrors.add(ValidationError(
          ruleId: pathDoesNotExistCheck.name,
          file: dir.path,
          message: '$_skillFileName is missing in directory: ${dir.path} (see $dirStructureUrl)',
          severity: _getSeverity(pathDoesNotExistCheck)));
      return false;
    }
    return true;
  }
}

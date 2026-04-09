import 'package:yaml/yaml.dart';
import '../models/analysis_severity.dart';
import '../models/skill_context.dart';
import '../models/skill_rule.dart';
import '../models/validation_error.dart';
import '../rules.dart';

/// Enforces that the description field is not too long.
class DescriptionLengthRule extends SkillRule {
  DescriptionLengthRule({this.severity = AnalysisSeverity.error});

  @override
  final String name = descriptionTooLongCheck.name;

  @override
  final AnalysisSeverity severity;

  static const maxDescriptionLength = 1024;
  static const _skillFileName = 'SKILL.md';
  static const _descriptionFieldUrl = 'https://agentskills.io/specification#description-field';

  @override
  Future<List<ValidationError>> validate(SkillContext context) async {
    final errors = <ValidationError>[];

    if (context.parsedYaml == null) {
      return errors;
    }

    final YamlMap yaml = context.parsedYaml!;
    final String description = yaml['description']?.toString() ?? '';

    if (description.length > maxDescriptionLength) {
      errors.add(ValidationError(
        ruleId: name,
        severity: severity,
        file: _skillFileName,
        message:
            'Description field is too long. Maximum $maxDescriptionLength characters (see $_descriptionFieldUrl)',
      ));
    }

    return errors;
  }
}

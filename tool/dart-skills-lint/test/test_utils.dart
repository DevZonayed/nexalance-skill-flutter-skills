String buildFrontmatter({
  String name = 'Skill-Name',
  String description = 'A test skill',
  String? compatibility,
}) {
  final sb = StringBuffer();
  sb.writeln('---');
  sb.writeln('name: $name');
  sb.writeln('description: $description');
  if (compatibility != null) {
    sb.writeln('compatibility: $compatibility');
  }
  sb.writeln('---');
  return sb.toString();
}

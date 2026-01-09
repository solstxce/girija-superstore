class UpdateInfo {
  final String version;
  final String build;
  final bool required;
  final List<String> acceptedPreviousVersions;

  UpdateInfo({
    required this.version,
    required this.build,
    required this.required,
    required this.acceptedPreviousVersions,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      build: json['build'] as String,
      required: json['required'] as bool,
      acceptedPreviousVersions: List<String>.from(json['accepted_previous_versions'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'build': build,
      'required': required,
      'accepted_previous_versions': acceptedPreviousVersions,
    };
  }

  String getBuildUrl() {
    return build.replaceAll('{version}', version);
  }
}

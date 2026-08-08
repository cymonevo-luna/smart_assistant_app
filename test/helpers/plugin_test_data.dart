Map<String, dynamic> nestedInstalledPlugin({
  required String id,
  required String slug,
  required String name,
  bool enabled = true,
  String setupStatus = 'not_started',
  String? catalogId,
}) {
  return {
    'id': id,
    'enabled': enabled,
    'setup_status': setupStatus,
    'plugin': {
      'id': catalogId ?? 'catalog-$slug',
      'slug': slug,
      'name': name,
      'required_setup': true,
      'setup_type': 'oauth_google',
    },
  };
}

enum PluginSetupType {
  oauthGoogle,
  form;

  static PluginSetupType? fromApi(String? value) {
    switch (value) {
      case 'oauth_google':
        return PluginSetupType.oauthGoogle;
      case 'form':
        return PluginSetupType.form;
      default:
        return null;
    }
  }

  String toApi() {
    switch (this) {
      case PluginSetupType.oauthGoogle:
        return 'oauth_google';
      case PluginSetupType.form:
        return 'form';
    }
  }
}

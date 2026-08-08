/// Deep link fired when the user taps the 1×1 home-screen widget.
final widgetListenUri = Uri(
  scheme: 'smartassistant',
  host: 'assistant',
  path: '/widget-listen',
);

/// Returns true when [uri] is the widget listen deep link.
bool isWidgetListenUri(Uri uri) {
  return uri.scheme == widgetListenUri.scheme &&
      uri.host == widgetListenUri.host &&
      uri.path == widgetListenUri.path;
}

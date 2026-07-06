import 'chrome_policy.dart';

class TioRouteContract {
  const TioRouteContract({
    required this.path,
    required this.title,
    required this.description,
    this.chromePolicy = ChromePolicy.mainChrome,
  });

  final String path;
  final String title;
  final String description;
  final ChromePolicy chromePolicy;
}

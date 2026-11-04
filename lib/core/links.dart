import 'package:url_launcher/url_launcher.dart';

const kRepoUrl = 'https://github.com/powerkd/habit_tracker';
const kIssuesUrl = '$kRepoUrl/issues';

/// 用外部瀏覽器開啟網址,失敗回傳 false
Future<bool> openUrl(String url) async {
  try {
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

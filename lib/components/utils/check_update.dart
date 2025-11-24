import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> checkForUpdate() async {
  const url = "https://api.github.com/repos/DottoXD/NetManager/tags";

  try {
    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) return false;

    final data = json.decode(res.body);
    if (data is! List || data.isEmpty) return false;

    final latestTag = data[0];
    final latestSha = latestTag["commit"]["sha"].substring(0, 7);

    final gitCommit = String.fromEnvironment(
      'GIT_COMMIT',
      defaultValue: 'development',
    );

    if (gitCommit == "development") return false;

    return latestSha != gitCommit;
  } catch (_) {
    return false;
  }
}

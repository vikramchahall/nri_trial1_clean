import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  WhatsAppHelper._(); // private constructor

  static Future<void> sendDonation({
    required String name,
    required String amount,
    required String cause,
  }) async {
    const phone = "918837510630";

    final message =
        "Hello! My name is $name.\n"
        "I have donated ₹$amount.\n"
        "Purpose: $cause.";

    final uri = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch WhatsApp');
    }
  }
}

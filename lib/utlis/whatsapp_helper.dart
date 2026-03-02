import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  WhatsAppHelper._();

  static Future<void> sendDonation({
    required String name,
    required String amount,
    required String cause,
    required String phoneNumber, // ✅ DYNAMIC — from the post
  }) async {
    // Sanitize: strip spaces, dashes, +, etc. Keep only digits
    final sanitized = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If user entered without country code (10 digits), prefix India code
    final phone = sanitized.length == 10 ? '91$sanitized' : sanitized;

    final message =
        "Hello! My name is $name.\n"
        "I want to donate ₹$amount.\n"
        "additional note: $cause.";

  final uri = Uri.parse(
      "https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}",
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch WhatsApp');
    }
  }
}
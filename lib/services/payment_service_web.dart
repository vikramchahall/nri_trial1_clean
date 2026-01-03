// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openRazorpayWeb({
  required String key,
  required int amount,
  required String name,
  required String description,
  required Function onSuccess,
}) {
  // Listen for the success message from index.html
  html.window.onMessage.listen((event) {
    if (event.data == "PAYMENT_SUCCESS") {
      onSuccess();
    }
  });

  // Call the Javascript function in index.html
  js.context.callMethod('payWithRazorpay', [
    key,
    amount,
    name,
    description,
    'testvikram@nri.com',
    '8837510630'
  ]);
}
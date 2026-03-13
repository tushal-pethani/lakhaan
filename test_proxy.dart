import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final response = await http.post(
    Uri.parse('https://gst-proxy-three.vercel.app/api/verify-gst'),
    headers: {
      'Content-Type': 'application/json',
      'Origin': 'https://billings-app-77b3e.web.app'
    },
    body: jsonEncode({'gstin': '07AADCS6555J1Z3'}),
  );
  print(response.statusCode);
  print(response.body);
}

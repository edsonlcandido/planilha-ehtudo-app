
import 'dart:convert';
import 'package:http/http.dart' as http;

class WebhookService {
  static const String _webhookUrl = 'https://ehtudo-n8n.pfdgdz.easypanel.host/webhook/planilha/v2/transacoes-txt';

  static Future<bool> sendTransaction(Map<String, dynamic> transaction) async {
    try {
      // O corpo da requisição precisa ser um mapa que contém a chave "body"
      final requestBody = {
        'body': transaction
      };

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      // n8n geralmente retorna 200 OK para um webhook bem-sucedido
      if (response.statusCode == 200) {
        print('Webhook sent successfully for transaction ID: ${transaction['id']}');
        return true;
      } else {
        print('Failed to send webhook for transaction ID: ${transaction['id']}. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending webhook for transaction ID: ${transaction['id']}. Error: $e');
      return false;
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'bill_ocr_services.dart';

class ReceiptApiService {
  ReceiptApiService._();
  static final ReceiptApiService instance = ReceiptApiService._();

  // Put your PC IP here, for example:
  // static const String _baseUrl = 'http://192.168.1.5:8000';
  static const String _baseUrl = 'my ip';

  Future<BillScanResult> scan(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/parse-receipt'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Backend error: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return BillScanResult(
      rawText: data['rawText']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toDouble(),
      merchant: data['merchant']?.toString(),
      category: data['category']?.toString() ?? 'Others',
      note: data['note']?.toString() ?? '',
    );
  }
}

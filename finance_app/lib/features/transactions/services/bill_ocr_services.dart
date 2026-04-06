import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────────────────────────────────────
class BillScanResult {
  final String rawText;
  final double? amount;
  final String? merchant;
  final String category;
  final String note;

  const BillScanResult({
    required this.rawText,
    this.amount,
    this.merchant,
    required this.category,
    required this.note,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────
class BillOcrService {
  BillOcrService._();
  static final BillOcrService instance = BillOcrService._();

  // ── Category mapping ──────────────────────────────────────────────────────
  static const Map<String, List<String>> _categoryKeywords = {
    'Food': [
      'restaurant',
      'cafe',
      'food',
      'pizza',
      'burger',
      'swiggy',
      'zomato',
      'dine',
      'coffee',
    ],
    'Travel': [
      'uber',
      'ola',
      'taxi',
      'metro',
      'fuel',
      'petrol',
      'diesel',
      'bus',
    ],
    'Shopping': ['amazon', 'flipkart', 'mall', 'store', 'shopping', 'mart'],
    'Bills': [
      'electricity',
      'bill',
      'recharge',
      'wifi',
      'rent',
      'utility',
      'postpaid',
    ],
    'Health': ['pharmacy', 'medical', 'hospital', 'clinic', 'doctor'],
    'Entertainment': ['movie', 'cinema', 'netflix', 'spotify', 'show'],
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────
  Future<BillScanResult> scan(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognised = await recognizer.processImage(
        inputImage,
      );

      final raw = recognised.text;

      final amount = _extractAmount(recognised);
      final merchant = _extractMerchant(recognised);
      final category = _detectCategory(raw);
      final note = _buildNote(raw);

      // 🔍 DEBUG LOGS
      print("----------- OCR DEBUG -----------");
      print("TEXT:\n$raw");
      print("AMOUNT: $amount");
      print("MERCHANT: $merchant");
      print("CATEGORY: $category");
      print("--------------------------------");

      return BillScanResult(
        rawText: raw,
        amount: amount,
        merchant: merchant,
        category: category,
        note: note,
      );
    } finally {
      recognizer.close();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 🔥 IMPROVED AMOUNT DETECTION (MAIN FIX)
  // ─────────────────────────────────────────────────────────────────────────
  double? _extractAmount(RecognizedText recognised) {
    final candidates = <_AmountCandidate>[];

    for (final block in recognised.blocks) {
      for (final line in block.lines) {
        final rawLine = _cleanupMoneyText(line.text.trim());
        if (rawLine.isEmpty) continue;

        final lower = rawLine.toLowerCase();

        final matches = RegExp(
          r'(?<!\d)(\d{1,3}(?:,\d{3})+|\d+)(?:\.(\d{1,2}))?(?!\d)',
        ).allMatches(rawLine);

        for (final m in matches) {
          final rawNumber = m.group(0)!;
          final value = double.tryParse(rawNumber.replaceAll(',', ''));

          if (value == null || value < 1) continue;

          int score = 0;

          // ✅ Strong keywords
          if (RegExp(
            r'(grand total|total amount|net total|amount due|amount payable|'
            r'total payable|balance due|bill total|final total|total)',
            caseSensitive: false,
          ).hasMatch(lower)) {
            score += 8;
          }

          // ✅ Currency markers
          if (RegExp(
            r'(₹|rs\.?|inr)',
            caseSensitive: false,
          ).hasMatch(rawLine)) {
            score += 6;
          }

          // ✅ Format hints
          if (rawNumber.contains(',') || rawNumber.contains('.')) {
            score += 2;
          }

          // ❌ Penalize unwanted lines
          if (RegExp(
            r'(invoice|bill no|order no|gst|phone|date|time|hsn|tax|qty)',
            caseSensitive: false,
          ).hasMatch(lower)) {
            score -= 6;
          }

          // Small bonus
          if (value >= 10) score += 1;
          if (value >= 1000) score += 1;

          candidates.add(_AmountCandidate(value, score, rawLine));
        }
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final scoreDiff = b.score.compareTo(a.score);
      if (scoreDiff != 0) return scoreDiff;
      return b.value.compareTo(a.value);
    });

    print("Best amount line: ${candidates.first.line}");

    return candidates.first.value;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Merchant detection
  // ─────────────────────────────────────────────────────────────────────────
  String? _extractMerchant(RecognizedText recognised) {
    for (final block in recognised.blocks.take(3)) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.length >= 3 &&
            t.length <= 60 &&
            !RegExp(r'^\d').hasMatch(t) &&
            !RegExp(r'^[\d\s\-/:.]+$').hasMatch(t)) {
          return _titleCase(t);
        }
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Category detection
  // ─────────────────────────────────────────────────────────────────────────
  String _detectCategory(String text) {
    final lowerText = text.toLowerCase();

    String bestCategory = 'Others';
    int maxScore = 0;

    _categoryKeywords.forEach((category, keywords) {
      int score = 0;

      for (var keyword in keywords) {
        if (lowerText.contains(keyword)) score++;
      }

      if (score > maxScore) {
        maxScore = score;
        bestCategory = category;
      }
    });

    return bestCategory;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  String _buildNote(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 3 && l.length < 80)
        .take(2)
        .toList();
    return lines.join(' • ');
  }

  String _cleanupMoneyText(String text) {
    return text
        .replaceAll(RegExp(r'[^\d,.\s₹RsINR]', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _titleCase(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper class
// ─────────────────────────────────────────────────────────────────────────────
class _AmountCandidate {
  final double value;
  final int score;
  final String line;

  _AmountCandidate(this.value, this.score, this.line);
}

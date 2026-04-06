# Finance Companion

A Flutter-based personal finance companion app with a Python FastAPI backend for receipt OCR, automated amount detection, merchant extraction, and expense categorization.

The frontend stores transactions locally with SQLite and uses Riverpod for state management. The backend exposes a `/parse-receipt` endpoint that accepts an image upload and returns structured receipt data such as `rawText`, `amount`, `merchant`, and `category`. The backend code also includes custom preprocessing and cleanup logic for OCR noise, rupee-symbol misreads, and dropped decimals.

## Features

### Flutter frontend
- Add income and expense transactions manually.
- Edit and delete existing transactions.
- View a transaction list grouped by date.
- Filter transactions by category.
- See summary cards for spending and income.
- Use a styled light/dark theme.
- Save data locally using SQLite.
- Scan receipts and prefill the add form.
- Support for OCR-based and manual entry flows.

### Python backend
- FastAPI receipt parsing API.
- OpenCV preprocessing for cleaner OCR input.
- Tesseract OCR text extraction.
- Amount extraction with heuristics for noisy bills.
- Merchant detection from OCR text.
- Category detection using keyword matching.

## Project structure

```text
finance-companion/
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── theme/
│   │   │   │   ├── app_colors.dart
│   │   │   │   └── app_theme.dart
│   │   │   └── widgets/
│   │   │       └── reusable_widgets.dart
│   │   ├── data/
│   │   │   └── db_helper.dart
│   │   └── features/
│   │       └── transactions/
│   │           ├── data/
│   │           │   ├── transaction_model.dart
│   │           │   └── transaction_repo.dart
│   │           ├── presentation/
│   │           │   ├── add_transaction_screen.dart
│   │           │   └── transaction_list_screen.dart
│   │           ├── provider/
│   │           │   └── transaction_provider.dart
│   │           └── services/
│   │               ├── bill_ocr_services.dart
│   │               └── receipt_api_service.dart
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── backend/
│   ├── main.py
│   └── ...
├── assets/
│   └── screenshots/
└── README.md
```

## Screenshots



### App Overview

| Home | Add Expense | Transaction Details |
|---|---|---|
| ![Home Screen](assets/screenshots/home-screen.png) | ![Add Expense Screen](assets/screenshots/add-expense-screen.png) | ![Add Income Screen](assets/screenshots/add-income-screen.png) |

### OCR / Receipt Scanning

| Upload Receipt | Parsed Result | Category Detection |
|---|---|---|
| ![Upload Receipt](assets/screenshots/upload-receipt.png) | ![Parsed Result](assets/screenshots/parsed-result.png) | ![Filtered Results](assets/screenshots/category-detection.png) |

## Tech stack

### Frontend
- Flutter
- Dart
- Riverpod
- Sqflite
- Path Provider
- Image Picker
- Google ML Kit Text Recognition

### Backend
- Python
- FastAPI
- OpenCV
- NumPy
- Pytesseract
- Uvicorn

## How the app works

1. The user adds a transaction manually or scans a receipt.
2. The Flutter app can either:
   - use local OCR, or
   - send the receipt image to the FastAPI backend.
3. The backend extracts raw text from the image and tries to detect:
   - amount
   - merchant
   - category
4. The frontend receives the result and pre-fills the transaction form.
5. The user saves the transaction into the local SQLite database.

## Flutter setup

### 1) Install dependencies
Install Flutter SDK, Android Studio, and ensure your device/emulator is ready.

### 2) Get packages
From the Flutter project root:

```bash
flutter pub get
```

### 3) Run the app

```bash
flutter run
```

### 4) Backend URL configuration
In `lib/features/transactions/services/receipt_api_service.dart`, update the backend IP address:

```dart
static const String _baseUrl = 'http://YOUR_PC_IP:8000';
```

Use your computer’s local IP address so the phone/emulator can reach the FastAPI server.

## Backend setup

### 1) Create a virtual environment

```bash
python -m venv venv
```

Activate it:

```bash
# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate
```

### 2) Install Python dependencies

```bash
pip install fastapi uvicorn opencv-python numpy pytesseract python-multipart
```

### 3) Install Tesseract OCR
Install Tesseract on your system and make sure it is available in PATH.

### 4) Run the backend

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API

### `POST /parse-receipt`

**Request**: multipart form-data with a file field named `file`

**Response example**

```json
{
  "rawText": "...",
  "amount": 1455.0,
  "merchant": "Blinkit",
  "category": "Food",
  "note": "Auto detected • Blinkit"
}
```

## Flutter app flow

### Add transaction screen
The add screen supports three entry modes:
- New manual entry
- Edit existing transaction
- OCR pre-fill from a scanned receipt

### Transaction list screen
The list screen includes:
- summary cards
- category filters
- date grouping
- edit action
- delete action
- floating action button that opens the type picker sheet

## Notes

- The backend OCR accuracy depends on image quality.
- Clear, well-lit receipts give better results.
- If the backend is running on your PC and the app is on a phone, both devices must be on the same network.
- If you use an emulator, you may need to adjust the backend address accordingly.

## Future improvements

- Cloud sync for transactions
- Export to CSV/PDF
- Better receipt line-item extraction
- Better category prediction
- Analytics dashboard
- Search by merchant or note

## License

Add your preferred license before publishing on GitHub.

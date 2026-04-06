from fastapi import FastAPI, File, UploadFile
import cv2
import numpy as np
import pytesseract
import re

app = FastAPI()

# ─────────────────────────────────────────────────────────────────
# OCR  —  BUG 4 FIX: proper image preprocessing for receipts
# ─────────────────────────────────────────────────────────────────
def extract_text(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    h, w = gray.shape
    if w < 1000:
        scale = 1000 / w
        gray = cv2.resize(gray, None, fx=scale, fy=scale,
                          interpolation=cv2.INTER_CUBIC)

    gray = cv2.bilateralFilter(gray, 9, 75, 75)

    thresh = cv2.adaptiveThreshold(
        gray, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        blockSize=31,
        C=15
    )

    config = r'--oem 3 --psm 4'
    return pytesseract.image_to_string(thresh, config=config)


# ─────────────────────────────────────────────────────────────────
# Parenthesis / bracket stripping
#
# Swiggy/Zomato OCR produces two kinds of paren noise:
#   Balanced:   (1455.00)  → Tesseract reads both parens correctly
#   Orphan-):   1455.00)   → Tesseract drops the opening '(' entirely
#   Orphan-(:   (1455.00   → less common but handled too
#
# Also strip surrounding quotes, backslashes, equals that OCR adds
# around numbers: '=12.50)  \= 1.00)  °20)
# ─────────────────────────────────────────────────────────────────
def _strip_parens(text: str) -> str:
    """
    Strip any mix of leading/trailing paren, bracket, quote, =, °, \\
    that wraps a number token.  Works on balanced AND orphan cases.
    """
    # Pass 1: balanced parens/brackets around a number
    text = re.sub(r"[(\['\`\\=°]+\s*([\d,]+(?:\.\d{1,2})?)\s*[)\]']+",
                  lambda m: m.group(1), text)
    # Pass 2: orphan trailing ) or ] after a number
    text = re.sub(r'([\d,]+(?:\.\d{1,2})?)\s*[)\]]', lambda m: m.group(1), text)
    # Pass 3: orphan leading junk before a number on a line
    text = re.sub(r"(?m)^[\s'`\\=°({\[]+(\d)", r'\1', text)
    return text


# ─────────────────────────────────────────────────────────────────
# ₹ glyph normalization — BUG 1 FIX
#
# BUG FIX: P2 pattern `\b7\s{1,3}` was matching the trailing '7'
# in numbers like '17' because \b sits before the whole token, not
# between digits. Fix: require that '7' is NOT preceded by any digit.
# ─────────────────────────────────────────────────────────────────
_PRICE_HINT = re.compile(
    r'total|amount|payable|due|pay|price|charge|fee|'
    r'subtotal|tax|gst|mrp|cost|fare',
    re.IGNORECASE
)

def _normalize_rupee(text: str) -> str:
    """Replace OCR misreads of ₹ as 7/Z/F/? on price-context lines."""
    result = []
    for line in text.split('\n'):
        is_price_line = (
            _PRICE_HINT.search(line) is not None or
            '₹' in line or
            re.match(r'^[\s\w]{0,15}[7ZF?]\s*[\d,]{2}', line)
        )
        if is_price_line:
            # P1: '7' glued to comma-formatted amount — '71,299' or '7299'
            line = re.sub(r'(?<![,\d])7([\d,]+(?:\.\d{1,2})?)',
                          lambda m: '₹' + m.group(1), line)
            # P2: standalone '7' (not preceded by digit) with spaces before amount
            # FIX: use (?<!\d) lookbehind instead of \b to avoid matching '17 450'
            line = re.sub(r'(?<!\d)7\s{1,3}([\d,]{2,}(?:\.\d{1,2})?)',
                          lambda m: '₹' + m.group(1), line)
            # P3: Z or F misread
            line = re.sub(r'\b[ZF]\s{0,2}([\d,]{2,}(?:\.\d{1,2})?)',
                          lambda m: '₹' + m.group(1), line)
            # P4: ? misread
            line = re.sub(r'\?([\d,]{2,}(?:\.\d{1,2})?)',
                          lambda m: '₹' + m.group(1), line)
        result.append(line)
    return '\n'.join(result)


# ─────────────────────────────────────────────────────────────────
# Decimal reconstruction
#
# NEW BUG FIX: Tesseract drops decimals on app screenshots.
# "195.70" → "19570",  "1,455.00" → "145500"
#
# Strategy: after extracting a candidate value, if it looks
# suspiciously large (>= 10000) AND a decimal-shifted version
# (divide by 100) falls in a plausible receipt range (10–9999),
# AND other values on nearby lines are also in that lower range,
# prefer the decimal-shifted value.
#
# We do this ONLY when the value has exactly 4–5 digits with no
# decimal, suggesting a dropped ".XX" suffix.
# ─────────────────────────────────────────────────────────────────
def _maybe_fix_dropped_decimal(val: float, all_values: list[float]) -> float:
    """
    If val looks like a decimal was dropped (e.g. 19570 → 195.70),
    return the corrected value; otherwise return val unchanged.

    Only fires when:
    - val is a whole number (no decimal in source string)
    - val >= 1000 (small whole numbers like 220, 350 are real prices)
    - val/100 is plausible AND closer to peer median than val itself
    """
    if val != int(val):          # source had a decimal point — trust it
        return val
    if val < 1000 or val > 99999:
        return val

    shifted = val / 100
    if shifted < 10:
        return val

    # Use peers that ARE decimal values (have a fractional part) as anchors —
    # they're more trustworthy than other whole-number guesses.
    decimal_peers = [v for v in all_values if v != val and v != int(v) and 10 <= v <= 9999]
    all_peers     = [v for v in all_values if v != val and 10 <= v <= 9999]
    peers = decimal_peers if decimal_peers else all_peers
    if not peers:
        return val

    import statistics
    median_peer = statistics.median(peers)
    if abs(median_peer - shifted) < abs(median_peer - val):
        return shifted

    return val


# ─────────────────────────────────────────────────────────────────
# Amount extraction
# ─────────────────────────────────────────────────────────────────

_SCRUB = [
    re.compile(r'\b(19|20)\d{2}\b'),
    re.compile(r'\b\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}\b'),
    re.compile(r'\b[6-9]\d{9}\b'),
    re.compile(r'\b\d{6}\b'),
    re.compile(r'\b\d{7,}\b'),
    re.compile(r'(?:no|inv|invoice|receipt|order|ref|gstin|pan)'
               r'[.:\s]*\d+', re.IGNORECASE),
    re.compile(r'\b\d{1,2}:\d{2}(?::\d{2})?\b'),
]

_TOTAL_LABEL = re.compile(
    r'(?:grand\s*total|total\s*amount|net\s*total|net\s*payable|'
    r'amount\s*due|amount\s*payable|total\s*payable|payable\s*amount|'
    r'bill\s*total|bill.*summary|you\s*pay|total)',
    re.IGNORECASE
)

# Also match "Paid" lines — Swiggy/Zomato show "Paid" as a standalone line
# AFTER the amount, so we look BACKWARD from this label.
_PAID_LABEL = re.compile(r'\bpaid\b', re.IGNORECASE)

_CURRENCY_NUM = re.compile(r'(?:₹|Rs\.?)\s*([\d,]+(?:\.\d{1,2})?)',
                            re.IGNORECASE)


def _parse_num(s: str) -> float | None:
    try:
        return float(s.replace(',', ''))
    except (ValueError, AttributeError):
        return None


def _collect_tagged(window: str) -> list[tuple[float, bool]]:
    """
    Extract (value, had_decimal) pairs from a text window.
    had_decimal=True  → source string had a '.' — trust the value as-is.
    had_decimal=False → bare integer — candidate for dropped-decimal correction.
    Deduplicates by rounded value to avoid double-counting the same number.
    """
    seen: set[float] = set()
    found: list[tuple[float, bool]] = []
    for m in _CURRENCY_NUM.finditer(window):
        raw = m.group(1)
        v = _parse_num(raw)
        if v and 5 <= v <= 99999:
            key = round(v, 2)
            if key not in seen:
                seen.add(key)
                found.append((v, '.' in raw))
    for raw in re.findall(r'[\d,]+(?:\.\d{1,2})?', window):
        v = _parse_num(raw)
        if v and 10 <= v <= 99999:
            key = round(v, 2)
            if key not in seen:
                seen.add(key)
                found.append((v, '.' in raw))
    return found


def _maybe_fix_dropped_decimal_tagged(val: float, had_decimal: bool,
                                      peer_vals: list[float]) -> float:
    """
    Attempt decimal correction ONLY when the source string had NO decimal point.
    This prevents "1455.00" (parsed as 1455.0, had_decimal=True) from being
    misidentified as a shifted value.
    """
    if had_decimal:
        return val               # source was "1455.00" — never touch it
    if val != int(val):
        return val
    if val < 1000 or val > 99999:
        return val

    shifted = val / 100
    if shifted < 10:
        return val

    # Prefer decimal peers as anchors (they came from explicit ".xx" strings)
    import statistics
    decimal_peers = [v for v in peer_vals if v != int(v) and 10 <= v <= 9999]
    all_peers     = [v for v in peer_vals if 10 <= v <= 9999 and v != val]
    peers = decimal_peers if decimal_peers else all_peers
    if not peers:
        return val

    median_peer = statistics.median(peers)
    if abs(median_peer - shifted) < abs(median_peer - val):
        return shifted
    return val


def _resolve_tagged(tagged: list[tuple[float, bool]]) -> float | None:
    """Correct dropped decimals and return the best (largest reliable) amount."""
    import statistics
    if not tagged:
        return None
    peer_vals = [v for v, _ in tagged]
    fixed_tagged = [((_maybe_fix_dropped_decimal_tagged(v, d, peer_vals)), d)
                    for v, d in tagged]

    # Values that came from explicit decimal strings (e.g. "1455.00") are
    # fully trusted — never filter them out. Return the largest one if any.
    trusted = [v for v, d in fixed_tagged if d]
    if trusted:
        return max(trusted)

    # All values are bare integers (no decimal in source) — use median filter
    # to drop outliers, then return max of what remains.
    fixed_vals = [v for v, _ in fixed_tagged]
    if len(fixed_vals) == 1:
        return fixed_vals[0]
    med = statistics.median(fixed_vals)
    reasonable = [v for v in fixed_vals if v <= med * 20]
    return max(reasonable) if reasonable else max(fixed_vals)


def extract_amount(text: str) -> float | None:
    # Step 0: strip parens/brackets/junk that Swiggy/Zomato screenshots add
    text = _strip_parens(text)

    # Step 1: normalize ₹ misreads
    text = _normalize_rupee(text)
    lines = text.split('\n')

    # ── Pass 1: labeled total/paid lines ─────────────────────────────────────
    # Swiggy layout:  amount is 2-4 lines BEFORE "Paid"
    # Normal receipt: amount is on same line or 1-2 lines AFTER the label
    label_tagged: list[tuple[float, bool]] = []
    for i, line in enumerate(lines):
        is_total = bool(_TOTAL_LABEL.search(line))
        is_paid  = bool(_PAID_LABEL.search(line))
        if not (is_total or is_paid):
            continue
        if is_paid:
            start = max(0, i - 4)
            end   = min(len(lines), i + 1)
        else:
            start = max(0, i - 1)
            end   = min(len(lines), i + 3)
        window = ' '.join(lines[start:end])
        label_tagged.extend(_collect_tagged(window))

    if label_tagged:
        return _resolve_tagged(label_tagged)

    # ── Pass 2: currency-symbol numbers anywhere ──────────────────────────────
    curr_tagged = _collect_tagged(text)
    curr_tagged = [(v, d) for v, d in curr_tagged
                   if any(m.group(0) for m in _CURRENCY_NUM.finditer(text)
                          if _parse_num(m.group(1)) == v)]
    # Simpler: just re-extract currency hits with tag
    curr_tagged = []
    for m in _CURRENCY_NUM.finditer(text):
        raw = m.group(1)
        v = _parse_num(raw)
        if v and 5 <= v <= 99999:
            curr_tagged.append((v, '.' in raw))
    if curr_tagged:
        return _resolve_tagged(curr_tagged)

    # ── Pass 3: bare-number fallback after scrubbing noise ────────────────────
    scrubbed = text
    for p in _SCRUB:
        scrubbed = p.sub(' ', scrubbed)
    bare_tagged = []
    for m in re.finditer(r'\b(\d{2,5}(?:\.\d{1,2})?)\b', scrubbed):
        raw = m.group(1)
        v = _parse_num(raw)
        if v and 10 <= v <= 99999:
            bare_tagged.append((v, '.' in raw))
    return _resolve_tagged(bare_tagged) if bare_tagged else None


# ─────────────────────────────────────────────────────────────────
# Merchant extraction
# ─────────────────────────────────────────────────────────────────
_SKIP_LINE = re.compile(
    r'invoice|bill\s*no|bill\s*date|gst|order|date|phone|mob|'
    r'address|thank|welcome|visit|pan|cin|gstin',
    re.IGNORECASE
)

def extract_merchant(text: str) -> str | None:
    for line in text.split('\n')[:6]:
        line = line.strip()
        if len(line) < 3 or len(line) > 60:
            continue
        if re.search(r'\d', line):
            continue
        if _SKIP_LINE.search(line):
            continue
        return line.title()
    return None


# ─────────────────────────────────────────────────────────────────
# Category detection
# ─────────────────────────────────────────────────────────────────
_CATEGORY_WEIGHTS: dict[str, dict[str, int]] = {
    'Food': {
        'swiggy': 3, 'zomato': 3, 'dominos': 3, "domino's": 3,
        'mcdonalds': 3, 'kfc': 3, 'subway': 3, 'pizza hut': 3,
        'blinkit': 3, 'starbucks': 3, 'haldiram': 3, 'ccd': 3,
        'restaurant': 2, 'cafe': 2, 'dhaba': 2, 'bakery': 2,
        'canteen': 2, 'eatery': 2, 'tiffin': 2,
        'food': 1, 'pizza': 1, 'burger': 1, 'coffee': 1,
        'biryani': 1, 'meal': 1, 'menu': 1, 'snacks': 1,
    },
    'Travel': {
        'uber': 3, 'ola': 3, 'rapido': 3, 'irctc': 3,
        'indigo': 3, 'spicejet': 3, 'redbus': 3, 'makemytrip': 3,
        'taxi': 2, 'metro': 2, 'cab': 2, 'petrol pump': 2,
        'toll': 2, 'flight': 2, 'railway': 2, 'parking': 2,
        'petrol': 1, 'diesel': 1, 'fuel': 1, 'bus': 1, 'travel': 1,
    },
    'Shopping': {
        'amazon': 3, 'flipkart': 3, 'myntra': 3, 'meesho': 3,
        'nykaa': 3, 'ajio': 3, 'dmart': 3, 'd-mart': 3,
        'big bazaar': 3, 'reliance fresh': 3,
        'supermarket': 2, 'hypermarket': 2, 'retail': 2,
        'grocery': 2, 'outlet': 2,
        'mall': 1, 'store': 1, 'shop': 1, 'market': 1,
    },
    'Bills': {
        'airtel': 3, 'jio': 3, 'bsnl': 3, 'vodafone': 3,
        'tata power': 3, 'bescom': 3, 'msedcl': 3,
        'electricity': 2, 'postpaid': 2, 'broadband': 2,
        'wifi': 2, 'internet': 2, 'recharge': 2, 'utility': 2,
        'rent': 1, 'maintenance': 1, 'subscription': 1,
    },
    'Health': {
        'apollo': 3, 'medplus': 3, '1mg': 3, 'netmeds': 3,
        'practo': 3, 'fortis': 3, 'manipal': 3,
        'pharmacy': 2, 'hospital': 2, 'clinic': 2,
        'diagnostic': 2, 'pathology': 2, 'lab': 2,
        'medicine': 1, 'tablet': 1, 'doctor': 1,
        'prescription': 1, 'health': 1, 'dental': 1,
    },
    'Entertainment': {
        'bookmyshow': 3, 'pvr': 3, 'inox': 3, 'cinepolis': 3,
        'netflix': 3, 'spotify': 3, 'hotstar': 3, 'disney': 3,
        'cinema': 2, 'multiplex': 2, 'theatre': 2, 'concert': 2,
        'movie': 1, 'show': 1, 'ticket': 1, 'stream': 1,
    },
}


def detect_category(text: str, merchant: str | None = None) -> str:
    lower = text.lower()
    merch_lower = (merchant or '').lower()

    for cat, kws in _CATEGORY_WEIGHTS.items():
        for kw, w in kws.items():
            if w >= 3 and kw in merch_lower:
                return cat

    scores: dict[str, int] = {}
    for cat, kws in _CATEGORY_WEIGHTS.items():
        score = sum(w for kw, w in kws.items() if kw in lower)
        if score > 0:
            scores[cat] = score

    if scores:
        best_cat = max(scores, key=lambda c: scores[c])
        if scores[best_cat] >= 3:
            return best_cat
        for kw, w in _CATEGORY_WEIGHTS[best_cat].items():
            if w == 3 and kw in lower:
                return best_cat

    return 'Others'


# ─────────────────────────────────────────────────────────────────
# API endpoint
# ─────────────────────────────────────────────────────────────────
@app.post("/parse-receipt")
async def parse_receipt(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    text     = extract_text(img)
    merchant = extract_merchant(text)
    amount   = extract_amount(text)
    category = detect_category(text, merchant)

    print("\n========== OCR DEBUG ==========")
    print("RAW TEXT:\n", text)
    print("AMOUNT  :", amount)
    print("MERCHANT:", merchant)
    print("CATEGORY:", category)
    print("================================\n")

    return {
        "rawText":  text,
        "amount":   amount,
        "merchant": merchant,
        "category": category,
        "note":     f"Auto detected • {merchant or 'Unknown merchant'}",
    }
# 🕉️ Sanskrit Recitation App

> A Flutter-based mobile application for reading, searching, and bookmarking Sanskrit verses — built with a focus on linguistic accuracy and a smooth user experience.

**Developed under:** Abhishek Jaiswal, Ph.D. Scholar, Department of CSE, IIT Kanpur
**Duration:** January 2025 – May 2025

---

## 📖 Table of Contents

- [Overview](#overview)
- [Why This App?](#why-this-app)
- [Features](#features)
- [Technical Deep-Dive](#technical-deep-dive)
  - [1. Hierarchical Data Modelling with JSON Serialization](#1-hierarchical-data-modelling-with-json-serialization)
  - [2. State Management with Provider](#2-state-management-with-provider)
  - [3. Diacritic-Insensitive Search Algorithm](#3-diacritic-insensitive-search-algorithm)
  - [4. Real-Time RichText Highlighting](#4-real-time-richtext-highlighting)
  - [5. Themes via Reactive Provider](#5-themes-via-reactive-provider)
  - [6. Bookmarking with SharedPreferences](#6-bookmarking-with-sharedpreferences)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Getting Started](#getting-started)
- [Dependencies](#dependencies)

---

## Overview

The Sanskrit Recitation App is a cross-platform Flutter application that enables users to browse, read, and practice Sanskrit verses. Sanskrit texts follow a deeply hierarchical structure — they are organized into *Kāṇḍas* (books), *Sargās* (chapters), and individual *shlokas* (verses). A recurring challenge with Sanskrit digital tools is handling **diacritical marks** (like ā, ī, ṭ, ṣ, ñ) used in IAST (International Alphabet of Sanskrit Transliteration), which most search engines cannot handle out of the box.

This app solves that problem while also providing a polished reading and bookmarking experience.

---

## Why This App?

**The Problem:**
Sanskrit texts are increasingly digitized, but existing tools make them hard to navigate and search. A user looking for *"dharma"* would miss results containing *"dharmā"* or *"dhárma"* because standard string matching is exact and diacritics-sensitive. There is also no lightweight mobile tool that presents Sanskrit texts in a hierarchically browsable, bookmarkable, and searchable format.

**The Goal:**
Build a mobile app that:
1. Stores and renders Sanskrit texts in their structured, hierarchical form
2. Lets users search for verses **without needing to type diacritics**
3. Highlights search matches **in real-time within the original diacriticized text**
4. Supports bookmarking and personalization (themes) across sessions

---

## Features

| Feature | Description |
|---|---|
| 📚 Hierarchical browsing | Navigate texts organized into Books → Chapters → Verses |
| 🔍 Diacritic-insensitive search | Type "dharma", find "dharmā", "dhárma", etc. |
| ✨ Real-time match highlighting | Matched text is highlighted inline in the original |
| 🔖 Bookmarking | Save verses locally; persists across app restarts |
| 🎨 Customizable themes | Light/dark and color themes managed reactively |
| 📱 Cross-platform | Runs on Android, iOS, and the web from a single codebase |

---

## Technical Deep-Dive

### 1. Hierarchical Data Modelling with JSON Serialization

**Why?**
Sanskrit texts are not flat lists of verses — they are nested structures. Representing them as a flat list would destroy context (which verse belongs to which chapter and book). We needed a data model that mirrors this tree structure.

**How?**
The text content is stored in `.json` asset files following a nested schema:

```json
{
  "title": "Ramayana",
  "khandas": [
    {
      "name": "Bala Kanda",
      "sargas": [
        {
          "name": "Sarga 1",
          "shlokas": [
            {
              "id": 1,
              "text": "tapaḥ svādhyāyanirataṃ tapasvī vāgvidāṃ varam"
            }
          ]
        }
      ]
    }
  ]
}
```

Dart model classes (e.g., `Shloka`, `Sarga`, `Khanda`) are then created with `fromJson` factory constructors to deserialize this data:

```dart
class Shloka {
  final int id;
  final String text;

  Shloka({required this.id, required this.text});

  factory Shloka.fromJson(Map<String, dynamic> json) => Shloka(
    id: json['id'],
    text: json['text'],
  );
}
```

This approach separates data from UI, makes the content editor-friendly (just update the JSON), and keeps the Dart code clean.

---

### 2. State Management with Provider

**Why?**
Flutter's default `setState` is limited to a single widget. When multiple screens need to share state — such as which verse is bookmarked, what the current theme is, or what the current search query is — you need a proper state management solution. **Provider** is a lightweight, officially recommended solution that uses Flutter's `InheritedWidget` under the hood.

**How?**
`ChangeNotifier` classes act as the "stores" of state. Any widget that calls `context.watch<T>()` will rebuild automatically when `notifyListeners()` is called on `T`.

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // All listening widgets rebuild
  }
}
```

Providers are registered at the top of the widget tree using `MultiProvider`, making them accessible anywhere in the app:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => BookmarkProvider()),
    ChangeNotifierProvider(create: (_) => SearchProvider()),
  ],
  child: MyApp(),
)
```

---

### 3. Diacritic-Insensitive Search Algorithm

**Why?**
This is the core technical challenge of the app. Sanskrit in IAST transliteration uses characters like `ā`, `ī`, `ū`, `ṭ`, `ḍ`, `ṣ`, `ṃ`, `ḥ`, `ñ`. A user typing on a standard keyboard cannot easily produce these. If search is exact-match, they'd have to type `dharmā` to find *dharmā* — which defeats the purpose.

The solution: **normalize both the query and the text before matching**, then **map the results back to original positions**.

**How — Step by Step:**

**Step 1: Build a normalization map**

A custom mapping converts each diacritical character to its ASCII equivalent:

```dart
const Map<String, String> diacriticMap = {
  'ā': 'a', 'Ā': 'A',
  'ī': 'i', 'Ī': 'I',
  'ū': 'u', 'Ū': 'U',
  'ṭ': 't', 'Ṭ': 'T',
  'ḍ': 'd', 'Ḍ': 'D',
  'ṣ': 's', 'Ṣ': 'S',
  'ś': 's', 'Ś': 'S',
  'ṃ': 'm', 'ḥ': 'h',
  'ñ': 'n', 'ṅ': 'n',
  // ... and so on
};
```

**Step 2: Normalize a string, tracking index mappings**

Crucially, when a multi-byte character like `ā` (1 char in original) maps to `a` (1 char in normalized), the indices still align 1:1. We build a parallel list that maps each position in the *normalized* string back to its position in the *original* string:

```dart
String normalizeText(String input, List<int> indexMap) {
  final buffer = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    final char = input[i];
    final normalized = diacriticMap[char] ?? char;
    buffer.write(normalized.toLowerCase());
    indexMap.add(i); // normalized position → original position
  }
  return buffer.toString();
}
```

**Step 3: Search in normalized space**

The user's query is also normalized (so `"dharma"` → `"dharma"`). We then run standard `indexOf` or regex matching on the normalized text:

```dart
List<Match> findMatches(String normalizedText, String normalizedQuery) {
  return RegExp(RegExp.escape(normalizedQuery))
      .allMatches(normalizedText)
      .toList();
}
```

**Step 4: Map results back to original positions**

Each match has a start/end in the normalized text. We use the `indexMap` to translate these back to positions in the original text:

```dart
int originalStart = indexMap[match.start];
int originalEnd = indexMap[match.end - 1] + 1;
```

Now we know exactly which characters in the *original diacriticized text* correspond to the user's search — even though the user never typed a single diacritic.

---

### 4. Real-Time RichText Highlighting

**Why?**
Once we know *which spans* of the original text match the search query, we need to visually highlight them. Flutter's standard `Text` widget cannot do this — it renders text with a single style. We need **`RichText`** with **`TextSpan`** to apply different styles to different portions of the same string.

**How?**

Given the original text and a list of matched `(start, end)` ranges, we split the text into alternating highlighted and non-highlighted segments:

```dart
List<TextSpan> buildHighlightedSpans(
    String originalText, List<(int, int)> matchRanges) {
  final spans = <TextSpan>[];
  int cursor = 0;

  for (final (start, end) in matchRanges) {
    // Text before this match — normal style
    if (cursor < start) {
      spans.add(TextSpan(
        text: originalText.substring(cursor, start),
        style: normalStyle,
      ));
    }
    // The matched portion — highlighted style
    spans.add(TextSpan(
      text: originalText.substring(start, end),
      style: highlightStyle, // e.g., yellow background, bold
    ));
    cursor = end;
  }

  // Any remaining text after the last match
  if (cursor < originalText.length) {
    spans.add(TextSpan(text: originalText.substring(cursor), style: normalStyle));
  }

  return spans;
}
```

This list of spans is fed into a `RichText` widget:

```dart
RichText(
  text: TextSpan(children: buildHighlightedSpans(shloka.text, matches)),
)
```

The result: the user types `"dharma"` and the word *dharmā* lights up — inside the original Sanskrit text, diacritics and all — in real time as they type.

---

### 5. Themes via Reactive Provider

**Why?**
Users have different preferences for reading — some prefer light mode, others dark. Hardcoding a theme makes the app inflexible. We want theme changes to propagate instantly across every screen without triggering full rebuilds.

**How?**
A `ThemeProvider` (a `ChangeNotifier`) holds the current `ThemeMode` and custom color seeds. The root `MaterialApp` listens to it:

```dart
Consumer<ThemeProvider>(
  builder: (context, themeProvider, _) => MaterialApp(
    themeMode: themeProvider.themeMode,
    theme: ThemeData(colorSchemeSeed: themeProvider.seedColor),
    darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeProvider.seedColor,
        brightness: Brightness.dark,
      ),
    ),
    ...
  ),
)
```

When the user picks a new color or toggles dark mode, `notifyListeners()` causes `MaterialApp` to rebuild with the new theme — and since `MaterialApp` is the ancestor of all screens, the entire UI updates instantly. Theme preferences are also persisted to `SharedPreferences` so they survive app restarts.

---

### 6. Bookmarking with SharedPreferences

**Why?**
Bookmarks must survive the user closing the app. In-memory state is wiped when the app is killed. We need **local persistent storage** — and for a simple list of bookmark IDs, a lightweight key-value store is perfect. `SharedPreferences` is exactly that: it writes to the platform's native preference storage (NSUserDefaults on iOS, SharedPreferences on Android).

**How?**

```dart
class BookmarkProvider extends ChangeNotifier {
  final Set<String> _bookmarks = {};

  Future<void> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('bookmarks') ?? [];
    _bookmarks.addAll(saved);
    notifyListeners();
  }

  Future<void> toggleBookmark(String shlokaId) async {
    if (_bookmarks.contains(shlokaId)) {
      _bookmarks.remove(shlokaId);
    } else {
      _bookmarks.add(shlokaId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', _bookmarks.toList());
    notifyListeners();
  }

  bool isBookmarked(String shlokaId) => _bookmarks.contains(shlokaId);
}
```

Any widget displaying a verse can call `context.watch<BookmarkProvider>().isBookmarked(id)` to show the correct bookmark icon, and it auto-updates when another screen toggles the bookmark.

---

## Project Structure

```
sanskrit_recitation_app/
├── assets/
│   └── data/               # JSON files with Sanskrit text content
├── lib/
│   ├── main.dart            # App entry point, Provider setup
│   ├── models/
│   │   ├── shloka.dart      # Verse data model
│   │   ├── sarga.dart       # Chapter data model
│   │   └── khanda.dart      # Book data model
│   ├── providers/
│   │   ├── theme_provider.dart
│   │   ├── bookmark_provider.dart
│   │   └── search_provider.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── chapter_screen.dart
│   │   ├── verse_screen.dart
│   │   ├── search_screen.dart
│   │   └── bookmarks_screen.dart
│   ├── widgets/
│   │   ├── shloka_card.dart
│   │   └── highlighted_text.dart  # RichText highlighting widget
│   └── utils/
│       └── diacritic_normalizer.dart  # Core search normalization logic
├── pubspec.yaml
└── README.md
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    Flutter UI Layer                  │
│  HomeScreen → ChapterScreen → VerseScreen            │
│  SearchScreen            BookmarksScreen             │
└────────────────────┬────────────────────────────────┘
                     │ context.watch / context.read
┌────────────────────▼────────────────────────────────┐
│              Provider Layer (State)                  │
│  ThemeProvider   BookmarkProvider   SearchProvider   │
└────────────────────┬────────────────────────────────┘
                     │
        ┌────────────┴───────────────┐
        ▼                            ▼
┌──────────────┐          ┌─────────────────────┐
│ SharedPrefs  │          │   JSON Assets        │
│ (bookmarks,  │          │ (Sanskrit text data) │
│  theme pref) │          └─────────────────────┘
└──────────────┘
```

**Data flows upward:** JSON is deserialized into model objects → fed to the UI.
**State flows downward:** Provider notifies widgets → they rebuild reactively.
**Persistence is asynchronous:** SharedPreferences writes happen in the background without blocking the UI.

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart `>=3.0.0`
- Android Studio / VS Code with Flutter extension

### Installation

```bash
# Clone the repository
git clone https://github.com/ppsspp18/Sanskrit-Recitation-App.git
cd Sanskrit-Recitation-App

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Build for release

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | Reactive state management |
| `shared_preferences` | Persistent local key-value storage for bookmarks and theme |
| `flutter` SDK | UI framework |

All content (Sanskrit text) is bundled as local JSON assets — **no internet connection required**.

---

## Key Takeaways

This project demonstrates several non-trivial engineering decisions:

1. **Linguistic awareness in search** — The diacritic normalization algorithm is domain-specific. Generic search libraries don't handle IAST transliteration, so a custom normalizer was necessary.

2. **Index-preserving normalization** — Simply stripping diacritics for display would lose information. By tracking the mapping between normalized and original indices, we can highlight the *exact original characters* that matched — a subtle but critical detail.

3. **Reactive architecture** — Using Provider throughout means the entire app responds to state changes (search query, theme, bookmarks) without manual widget communication or complex callback chains.

4. **Separation of concerns** — Models, providers, screens, and utilities are cleanly separated, making the codebase maintainable and testable.

---

*Built at IIT Kanpur | Department of Computer Science and Engineering*

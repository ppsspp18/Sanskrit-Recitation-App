import 'package:shared_preferences/shared_preferences.dart';

class BookmarkManager {
  static const String _key = 'bookmarkedVerses';

  static Future<List<String>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_key) ?? [];
    if (!bookmarks.contains(id)) {
      bookmarks.add(id);
      await prefs.setStringList(_key, bookmarks);
    }
  }

  static Future<void> removeBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_key) ?? [];
    bookmarks.remove(id);
    await prefs.setStringList(_key, bookmarks);
  }

  static Future<bool> isBookmarked(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_key) ?? [];
    return bookmarks.contains(id);
  }
}

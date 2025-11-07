import 'package:flutter/material.dart';
import 'translations.dart';

/// App localization delegate
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('es', 'ES'), // Spanish
    Locale('fr', 'FR'), // French
    Locale('de', 'DE'), // German
    Locale('it', 'IT'), // Italian
    Locale('pt', 'BR'), // Portuguese (Brazil)
    Locale('ru', 'RU'), // Russian
    Locale('zh', 'CN'), // Chinese (Simplified)
    Locale('ja', 'JP'), // Japanese
    Locale('ko', 'KR'), // Korean
    Locale('ar', 'SA'), // Arabic
    Locale('hi', 'IN'), // Hindi
  ];
  
  String get languageCode => locale.languageCode;
  
  // Get translation
  String translate(String key) {
    final translations = _getTranslations();
    return translations[key] ?? key;
  }
  
  Map<String, String> _getTranslations() {
    switch (locale.languageCode) {
      case 'es':
        return translationsES;
      case 'fr':
        return translationsFR;
      case 'de':
        return translationsDE;
      case 'it':
        return translationsIT;
      case 'pt':
        return translationsPT;
      case 'ru':
        return translationsRU;
      case 'zh':
        return translationsZH;
      case 'ja':
        return translationsJA;
      case 'ko':
        return translationsKO;
      case 'ar':
        return translationsAR;
      case 'hi':
        return translationsHI;
      default:
        return translationsEN;
    }
  }
  
  // Common translations
  String get appName => translate('app_name');
  String get newTab => translate('new_tab');
  String get closeTab => translate('close_tab');
  String get refresh => translate('refresh');
  String get back => translate('back');
  String get forward => translate('forward');
  String get bookmarks => translate('bookmarks');
  String get history => translate('history');
  String get settings => translate('settings');
  String get search => translate('search');
  String get searchOrEnterUrl => translate('search_or_enter_url');
  String get aiAssistant => translate('ai_assistant');
  String get devTools => translate('dev_tools');
  String get menu => translate('menu');
  String get cancel => translate('cancel');
  String get ok => translate('ok');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get save => translate('save');
  String get share => translate('share');
  String get copy => translate('copy');
  String get paste => translate('paste');
  String get cut => translate('cut');
  String get selectAll => translate('select_all');
  String get undo => translate('undo');
  String get redo => translate('redo');
  String get find => translate('find');
  String get print => translate('print');
  String get downloads => translate('downloads');
  String get extensions => translate('extensions');
  String get account => translate('account');
  String get signIn => translate('sign_in');
  String get signOut => translate('sign_out');
  String get newWindow => translate('new_window');
  String get newIncognitoWindow => translate('new_incognito_window');
  String get closeWindow => translate('close_window');
  String get zoomIn => translate('zoom_in');
  String get zoomOut => translate('zoom_out');
  String get resetZoom => translate('reset_zoom');
  String get fullScreen => translate('full_screen');
  String get exitFullScreen => translate('exit_full_screen');
  String get help => translate('help');
  String get about => translate('about');
  String get preferences => translate('preferences');
  String get clearBrowsingData => translate('clear_browsing_data');
  String get clearHistory => translate('clear_history');
  String get clearCache => translate('clear_cache');
  String get clearCookies => translate('clear_cookies');
  String get privacyAndSecurity => translate('privacy_and_security');
  String get appearance => translate('appearance');
  String get language => translate('language');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get systemDefault => translate('system_default');
  String get notifications => translate('notifications');
  String get permissions => translate('permissions');
  String get advanced => translate('advanced');
  String get general => translate('general');
  String get noActiveTab => translate('no_active_tab');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get close => translate('close');
  String get minimize => translate('minimize');
  String get maximize => translate('maximize');
  String get restore => translate('restore');
  
  // Bookmarks
  String get addBookmark => translate('add_bookmark');
  String get removeBookmark => translate('remove_bookmark');
  String get editBookmark => translate('edit_bookmark');
  String get bookmarkAdded => translate('bookmark_added');
  String get bookmarkRemoved => translate('bookmark_removed');
  String get noBookmarks => translate('no_bookmarks');
  String get bookmarkName => translate('bookmark_name');
  String get bookmarkUrl => translate('bookmark_url');
  String get bookmarkFolder => translate('bookmark_folder');
  
  // History
  String get clearHistoryConfirm => translate('clear_history_confirm');
  String get historyCleared => translate('history_cleared');
  String get noHistory => translate('no_history');
  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String get lastWeek => translate('last_week');
  String get lastMonth => translate('last_month');
  String get older => translate('older');
  
  // Downloads
  String get downloadStarted => translate('download_started');
  String get downloadCompleted => translate('download_completed');
  String get downloadFailed => translate('download_failed');
  String get noDownloads => translate('no_downloads');
  String get openFile => translate('open_file');
  String get showInFolder => translate('show_in_folder');
  String get pauseDownload => translate('pause_download');
  String get resumeDownload => translate('resume_download');
  String get cancelDownload => translate('cancel_download');
  
  // AI Assistant
  String get aiAssistantWelcome => translate('ai_assistant_welcome');
  String get askMeAnything => translate('ask_me_anything');
  String get summarizePage => translate('summarize_page');
  String get translatePage => translate('translate_page');
  String get extractData => translate('extract_data');
  String get fillForm => translate('fill_form');
  String get aiProcessing => translate('ai_processing');
  String get aiError => translate('ai_error');
  
  // Security
  String get secureConnection => translate('secure_connection');
  String get insecureConnection => translate('insecure_connection');
  String get certificateValid => translate('certificate_valid');
  String get certificateInvalid => translate('certificate_invalid');
  String get blockPopups => translate('block_popups');
  String get allowPopups => translate('allow_popups');
  String get blockCookies => translate('block_cookies');
  String get allowCookies => translate('allow_cookies');
  
  // Tabs
  String tabsCount(int count) => translate('tabs_count').replaceAll('{count}', count.toString());
  String get duplicateTab => translate('duplicate_tab');
  String get pinTab => translate('pin_tab');
  String get unpinTab => translate('unpin_tab');
  String get muteTab => translate('mute_tab');
  String get unmuteTab => translate('unmute_tab');
  String get closeOtherTabs => translate('close_other_tabs');
  String get closeTabsToRight => translate('close_tabs_to_right');
  String get reopenClosedTab => translate('reopen_closed_tab');
  
  // Errors
  String get pageNotFound => translate('page_not_found');
  String get connectionError => translate('connection_error');
  String get timeoutError => translate('timeout_error');
  String get unknownError => translate('unknown_error');
  String get tryAgain => translate('try_again');
  
  // Confirmation dialogs
  String get areYouSure => translate('are_you_sure');
  String get confirmDelete => translate('confirm_delete');
  String get confirmClear => translate('confirm_clear');
  String get confirmClose => translate('confirm_close');
  String get yes => translate('yes');
  String get no => translate('no');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension for easy access to translations
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:system_tray/system_tray.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

class SystemIntegrationService {
  static SystemTray? _systemTray;
  static bool _isInitialized = false;
  
  static Future<void> init() async {
    if (_isInitialized) return;
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _initializeSystemTray();
      await _setupLaunchAtStartup();
    }
    
    _isInitialized = true;
  }
  
  static Future<void> _initializeSystemTray() async {
    try {
      _systemTray = SystemTray();
      
      await _systemTray!.initSystemTray(
        title: "Titan Browser",
        iconPath: Platform.isWindows 
            ? 'assets/icons/titan_icon.ico'
            : 'assets/icons/titan_icon.png',
      );
      
      final menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: 'Show Titan',
          onClicked: (menuItem) => _showWindow(),
        ),
        MenuItemLabel(
          label: 'New Window',
          onClicked: (menuItem) => _newWindow(),
        ),
        MenuItemLabel(
          label: 'New Incognito Window',
          onClicked: (menuItem) => _newIncognitoWindow(),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Settings',
          onClicked: (menuItem) => _openSettings(),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Exit',
          onClicked: (menuItem) => _exitApp(),
        ),
      ]);
      
      await _systemTray!.setContextMenu(menu);
      
      _systemTray!.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          _showWindow();
        }
      });
    } catch (e) {
      print('Failed to initialize system tray: $e');
    }
  }
  
  static Future<void> _setupLaunchAtStartup() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
      );
    } catch (e) {
      print('Failed to setup launch at startup: $e');
    }
  }
  
  static Future<void> pinToTaskbar() async {
    if (Platform.isWindows) {
      await _pinToWindowsTaskbar();
    } else if (Platform.isMacOS) {
      await _pinToMacOSDock();
    } else if (Platform.isLinux) {
      await _pinToLinuxTaskbar();
    }
  }
  
  static Future<void> _pinToWindowsTaskbar() async {
    try {
      // Create a PowerShell script to pin to taskbar
      final script = '''
\$shell = New-Object -ComObject Shell.Application
\$folder = \$shell.Namespace((Get-Item "${Platform.resolvedExecutable}").DirectoryName)
\$item = \$folder.ParseName((Get-Item "${Platform.resolvedExecutable}").Name)
\$item.InvokeVerb("taskbarpin")
      ''';
      
      final result = await Process.run(
        'powershell',
        ['-Command', script],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        print('Successfully pinned to Windows taskbar');
      }
    } catch (e) {
      print('Failed to pin to Windows taskbar: $e');
    }
  }
  
  static Future<void> _pinToMacOSDock() async {
    try {
      // Add to macOS dock using defaults command
      final result = await Process.run(
        'defaults',
        [
          'write',
          'com.apple.dock',
          'persistent-apps',
          '-array-add',
          '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>${Platform.resolvedExecutable}</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
        ],
      );
      
      if (result.exitCode == 0) {
        await Process.run('killall', ['Dock']);
        print('Successfully pinned to macOS dock');
      }
    } catch (e) {
      print('Failed to pin to macOS dock: $e');
    }
  }
  
  static Future<void> _pinToLinuxTaskbar() async {
    try {
      // Create desktop entry for Linux
      final homeDir = Platform.environment['HOME'];
      final desktopFile = '$homeDir/.local/share/applications/titan-browser.desktop';
      
      final content = '''
[Desktop Entry]
Version=1.0
Type=Application
Name=Titan Browser
Comment=AI-powered cross-platform browser
Exec=${Platform.resolvedExecutable}
Icon=titan-browser
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
      ''';
      
      final file = File(desktopFile);
      await file.writeAsString(content);
      
      // Make executable
      await Process.run('chmod', ['+x', desktopFile]);
      
      print('Successfully created Linux desktop entry');
    } catch (e) {
      print('Failed to create Linux desktop entry: $e');
    }
  }
  
  static Future<void> enableLaunchAtStartup(bool enable) async {
    try {
      if (enable) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } catch (e) {
      print('Failed to set launch at startup: $e');
    }
  }
  
  static Future<bool> isLaunchAtStartupEnabled() async {
    try {
      return await launchAtStartup.isEnabled();
    } catch (e) {
      print('Failed to check launch at startup status: $e');
      return false;
    }
  }
  
  static void _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }
  
  static void _newWindow() {
    // Implementation for new window
    print('Opening new window');
  }
  
  static void _newIncognitoWindow() {
    // Implementation for new incognito window
    print('Opening new incognito window');
  }
  
  static void _openSettings() {
    // Implementation for opening settings
    print('Opening settings');
  }
  
  static void _exitApp() async {
    await windowManager.close();
  }
  
  static Future<void> dispose() async {
    await _systemTray?.destroy();
  }
}
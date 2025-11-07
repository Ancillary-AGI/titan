import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../core/platform_theme.dart';

/// Platform-adaptive scaffold
class PlatformScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  
  const PlatformScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        navigationBar: appBar != null && appBar is CupertinoNavigationBar
            ? appBar as CupertinoNavigationBar
            : null,
        child: body,
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Platform-adaptive button
class PlatformButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isPrimary;
  final EdgeInsets? padding;
  
  const PlatformButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isPrimary = true,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoButton(
        onPressed: onPressed,
        padding: padding,
        color: isPrimary ? CupertinoTheme.of(context).primaryColor : null,
        child: child,
      );
    }
    
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        child: child,
      );
    }
    
    return TextButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

/// Platform-adaptive icon button
class PlatformIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final double? iconSize;
  
  const PlatformIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.iconSize,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(icon, size: iconSize ?? 24),
      );
    }
    
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      tooltip: tooltip,
    );
  }
}

/// Platform-adaptive text field
class PlatformTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  
  const PlatformTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? hintText,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        prefix: prefix,
        suffix: suffix,
        obscureText: obscureText,
        keyboardType: keyboardType,
        padding: const EdgeInsets.symmetric(
          horizontal: PlatformTheme.spaceMd,
          vertical: PlatformTheme.spaceSm,
        ),
      );
    }
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText ?? placeholder,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }
}

/// Platform-adaptive switch
class PlatformSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  
  const PlatformSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      );
    }
    
    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Platform-adaptive slider
class PlatformSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  
  const PlatformSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoSlider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
      );
    }
    
    return Slider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
    );
  }
}

/// Platform-adaptive progress indicator
class PlatformProgressIndicator extends StatelessWidget {
  final double? value;
  final double? strokeWidth;
  
  const PlatformProgressIndicator({
    super.key,
    this.value,
    this.strokeWidth,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoActivityIndicator(
        radius: strokeWidth ?? 10,
      );
    }
    
    return CircularProgressIndicator(
      value: value,
      strokeWidth: strokeWidth ?? 4,
    );
  }
}

/// Platform-adaptive alert dialog
class PlatformAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<PlatformDialogAction> actions;
  
  const PlatformAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions.map((action) {
          return CupertinoDialogAction(
            onPressed: action.onPressed,
            isDefaultAction: action.isDefault,
            isDestructiveAction: action.isDestructive,
            child: Text(action.text),
          );
        }).toList(),
      );
    }
    
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: actions.map((action) {
        return TextButton(
          onPressed: action.onPressed,
          child: Text(action.text),
        );
      }).toList(),
    );
  }
  
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    required List<PlatformDialogAction> actions,
  }) {
    if (PlatformTheme.isCupertinoPlatform) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (context) => PlatformAlertDialog(
          title: title,
          content: content,
          actions: actions,
        ),
      );
    }
    
    return showDialog<T>(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }
}

class PlatformDialogAction {
  final String text;
  final VoidCallback onPressed;
  final bool isDefault;
  final bool isDestructive;
  
  const PlatformDialogAction({
    required this.text,
    required this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
  });
}

/// Platform-adaptive list tile
class PlatformListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  
  const PlatformListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      );
    }
    
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Platform-adaptive app bar
class PlatformAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  
  const PlatformAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformTheme.isCupertinoPlatform) {
      return CupertinoNavigationBar(
        middle: title,
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            : null,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    }
    
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
  
  @override
  Size get preferredSize {
    if (PlatformTheme.isCupertinoPlatform) {
      return const Size.fromHeight(44);
    }
    return const Size.fromHeight(56);
  }
}

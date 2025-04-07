import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../main.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.languageSettingsTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.selectLanguageText,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _buildLanguageOption(
              context,
              '🇺🇸 English',
              'en',
              currentLocale,
              localeProvider,
            ),
            const Divider(),
            _buildLanguageOption(
              context,
              '🇨🇳 中文',
              'zh',
              currentLocale,
              localeProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    String languageCode,
    String currentLocale,
    LocaleProvider localeProvider,
  ) {
    final isSelected = currentLocale == languageCode;

    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () async {
        if (!isSelected) {
          await localeProvider.changeLocale(Locale(languageCode, ''));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.languageChangedText),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }
}

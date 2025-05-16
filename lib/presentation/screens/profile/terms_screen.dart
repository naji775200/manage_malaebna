import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translationService.tr('profile.terms', {}, context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: _buildTermsContent(context),
      ),
    );
  }

  Widget _buildTermsContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translationService.tr('terms.title', {}, context),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          translationService.tr('terms.last_updated', {}, context),
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),

        // Terms sections
        _buildSection(
          context,
          translationService.tr('terms.sections.acceptance.title', {}, context),
          translationService.tr(
              'terms.sections.acceptance.content', {}, context),
        ),
        _buildSection(
          context,
          translationService.tr(
              'terms.sections.description.title', {}, context),
          translationService.tr(
              'terms.sections.description.content', {}, context),
        ),
        _buildSection(
          context,
          translationService.tr('terms.sections.accounts.title', {}, context),
          translationService.tr('terms.sections.accounts.content', {}, context),
        ),
        _buildSection(
          context,
          translationService.tr('terms.sections.booking.title', {}, context),
          translationService.tr('terms.sections.booking.content', {}, context),
        ),
        _buildSection(
          context,
          translationService.tr('terms.sections.conduct.title', {}, context),
          translationService.tr('terms.sections.conduct.content', {}, context),
        ),
        _buildSection(
          context,
          translationService.tr('terms.sections.liability.title', {}, context),
          translationService.tr(
              'terms.sections.liability.content', {}, context),
        ),
        _buildSection(
          context,
          translationService.tr(
              'terms.sections.modifications.title', {}, context),
          translationService.tr(
              'terms.sections.modifications.content', {}, context),
        ),
        _buildSection(
          context,
          translationService.tr('terms.sections.contact.title', {}, context),
          translationService.tr('terms.sections.contact.content', {}, context),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

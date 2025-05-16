import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translationService.tr('profile.privacy', {}, context)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translationService.tr('privacy.title', {}, context),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              translationService.tr('privacy.last_updated', {}, context),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              translationService.tr(
                  'privacy.sections.collection.title', {}, context),
              translationService.tr(
                  'privacy.sections.collection.content', {}, context),
            ),
            _buildSection(
              context,
              translationService.tr(
                  'privacy.sections.usage.title', {}, context),
              translationService.tr(
                  'privacy.sections.usage.content', {}, context),
            ),
            _buildSection(
              context,
              translationService.tr(
                  'privacy.sections.sharing.title', {}, context),
              translationService.tr(
                  'privacy.sections.sharing.content', {}, context),
            ),
            _buildSection(
              context,
              translationService.tr(
                  'privacy.sections.security.title', {}, context),
              translationService.tr(
                  'privacy.sections.security.content', {}, context),
            ),
            _buildSection(
              context,
              translationService.tr(
                  'privacy.sections.rights.title', {}, context),
              translationService.tr(
                  'privacy.sections.rights.content', {}, context),
            ),
            _buildSection(
              context,
              translationService.tr(
                  'privacy.sections.children.title', {}, context),
              translationService.tr(
                  'privacy.sections.children.content', {}, context),
            ),
            _buildSection(
              context,
              translationService.tr(
                  'privacy.sections.changes.title', {}, context),
              translationService.tr(
                  'privacy.sections.changes.content', {}, context),
            ),
            _buildSection(
              context,
              translationService.tr(
                  'privacy.sections.contact.title', {}, context),
              translationService.tr(
                  'privacy.sections.contact.content', {}, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.help_center_outlined, size: 80, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'How can we help you?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildContactCard(
              context,
              Icons.email_outlined,
              'Email Us',
              'support@campusflow.edu',
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              context,
              Icons.phone_outlined,
              'Call Support',
              '+91 1800-CAMPUS',
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              context,
              Icons.chat_bubble_outline,
              'Live Chat',
              'Connect with our agents',
            ),
            const SizedBox(height: 40),
            Text(
              'FAQs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildFaqItem('How do I book an appointment?', 'Go to the Home tab and click the "+" button or select a faculty from the search list.'),
            _buildFaqItem('Can I cancel an appointment?', 'Yes, students can cancel pending or approved appointments from the appointment card.'),
            _buildFaqItem('What if a faculty rejects my request?', 'You will receive a notification with the rejection reason. You can then edit and resubmit your request.'),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title, String subtitle) {
    String url = '';
    if (title.contains('Email')) url = 'mailto:$subtitle';
    if (title.contains('Call')) url = 'tel:${subtitle.replaceAll(' ', '')}';
    if (title.contains('Chat')) url = 'https://wa.me/919876543210';

    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
      ],
    );
  }
}

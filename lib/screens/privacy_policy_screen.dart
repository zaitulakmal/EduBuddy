import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8784A),
        title: Text('Privacy Policy',
            style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header('EduBuddy Privacy Policy'),
            _sub('Last updated: June 2025'),
            const SizedBox(height: 16),
            _section('1. Information We Collect',
                'EduBuddy does not collect any personal information from users. '
                'All data (quiz scores, progress, profiles) is stored locally on your device only. '
                'We do not transmit any data to external servers.'),
            _section('2. Children\'s Privacy',
                'EduBuddy is designed for children aged 4–12. '
                'We do not collect, use, or share personal information from children. '
                'This app complies with the Children\'s Online Privacy Protection Act (COPPA) and '
                'relevant data protection laws.'),
            _section('3. Data Storage',
                'All user data including profiles, quiz scores, and learning progress is stored '
                'locally on the device using a local database (SQLite). '
                'No data is sent to or stored on any external server.'),
            _section('4. Third-Party Services',
                'EduBuddy does not use any third-party analytics, advertising, or tracking services. '
                'The app does not contain advertisements.'),
            _section('5. Internet Usage',
                'EduBuddy may require internet access to load online video content. '
                'No personal data is transmitted during this process.'),
            _section('6. Changes to This Policy',
                'We may update this Privacy Policy from time to time. '
                'Any changes will be reflected in the app with an updated date.'),
            _section('7. Contact Us',
                'If you have any questions about this Privacy Policy, '
                'please contact us at: support@edubuddy.my'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Text(text,
      style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF333333)));

  Widget _sub(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey)));

  Widget _section(String title, String body) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFE8784A))),
        const SizedBox(height: 6),
        Text(body, style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF555555), height: 1.6)),
      ]));
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<dynamic> _announcements = [];
  List<dynamic> _emergencyContacts = [
    {'name': 'Police Emergency', 'phone': '999', 'icon': Icons.shield},
    {'name': 'Ambulance', 'phone': '112', 'icon': Icons.medical_services},
    {'name': 'Fire Brigade', 'phone': '999', 'icon': Icons.local_fire_department},
    {'name': 'County Office', 'phone': '+254700000000', 'icon': Icons.business},
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Demo mode bypass
    final auth = context.read<AuthService>();
    if (auth.user?['phone'] == '712345678') {
      await Future.delayed(const Duration(milliseconds: 500)); // Fake network delay
      if (mounted) {
        setState(() {
          _announcements = [
            {'title': 'MCA PA Announcement', 'content': 'Community meeting at Voo Market Hall on Friday 10am. All residents invited.'},
            {'title': 'Bursary Allocations', 'content': 'First batch of bursary cheques will be distributed next week.'},
          ];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final announcementsRes = await http.get(Uri.parse('${AuthService.baseUrl}/announcements'));
      final contactsRes = await http.get(Uri.parse('${AuthService.baseUrl}/emergency-contacts'));

      if (announcementsRes.statusCode == 200) {
        _announcements = jsonDecode(announcementsRes.body)['announcements'] ?? [];
      }
      if (contactsRes.statusCode == 200) {
        final contacts = jsonDecode(contactsRes.body)['contacts'] ?? [];
        if (contacts.isNotEmpty) _emergencyContacts = contacts;
      }
    } catch (e) {
      // Use default contacts
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showCallDialog(String name, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        title: Text('Call $name', style: const TextStyle(color: Colors.white)),
        content: Text('Dial: $phone', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0f0f23), Color(0xFF1a1a3e)]),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF6366f1),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Services', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Access government services', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 24),

                      // Quick Services Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _buildServiceCard(Icons.badge, 'Lost ID', Colors.red, () => _showLostIdForm(context)),
                          _buildServiceCard(Icons.feedback, 'Feedback', Colors.blue, () => _showFeedbackForm(context)),
                          _buildServiceCard(Icons.phone_in_talk, 'Emergency', Colors.orange, () => _showEmergencyContacts(context)),
                          _buildServiceCard(Icons.info, 'About', Colors.purple, () => _showAbout(context)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Emergency Contacts
                      const Text('Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      ...(_emergencyContacts).take(4).map((c) => Card(
                        color: const Color(0xFF1a1a3e),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            child: Icon(c['icon'] ?? Icons.phone, color: Colors.red),
                          ),
                          title: Text(c['name'] ?? '', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(c['phone'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                          trailing: IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () => _showCallDialog(c['name'], c['phone']),
                          ),
                        ),
                      )),
                      const SizedBox(height: 24),

                      // Announcements
                      if (_announcements.isNotEmpty) ...[
                        const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        ..._announcements.map((a) => Card(
                          color: const Color(0xFF2d1b69).withOpacity(0.5),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.campaign, color: Color(0xFF6366f1), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(a['content'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                              ],
                            ),
                          ),
                        )),
                      ] else ...[
                        // Show sample announcement
                        Card(
                          color: const Color(0xFF2d1b69).withOpacity(0.5),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.campaign, color: Color(0xFF6366f1), size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Welcome to VOO Citizen!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Report community issues, apply for bursaries, and access government services all in one app.', 
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showLostIdForm(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a3e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Lost ID', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('You will be notified when your ID is found', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 20),
              TextField(
                controller: idController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'National ID Number *',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: const Icon(Icons.badge, color: Color(0xFF6366f1)),
                  filled: true,
                  fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Full Name on ID *',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF6366f1)),
                  filled: true,
                  fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (idController.text.isEmpty || nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lost ID reported! You will be notified when found.'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
                  child: const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackForm(BuildContext context) {
    final messageController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a3e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send Feedback', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Share your feedback, suggestions, or complaints', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 20),
              TextField(
                controller: messageController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Your message *',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (messageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your message'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
                  child: const Text('Submit Feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    // Reverted url_launcher due to build issues
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling $number (Dialer not available in this build)')),
      );
    }
  }

  void _showEmergencyContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a3e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emergency Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            ...(_emergencyContacts).map((c) => ListTile(
              leading: Icon(c['icon'] ?? Icons.phone, color: Colors.red),
              title: Text(c['name'] ?? '', style: const TextStyle(color: Colors.white)),
              subtitle: Text(c['phone'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.6))),
              onTap: () {
                Navigator.pop(ctx);
                _callNumber(c['phone']!);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        title: const Text('About VOO Citizen', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 12),
            Text('VOO Citizen App helps you report community issues, apply for bursaries, and access government services.',
                style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))),
        ],
      ),
    );
  }
}

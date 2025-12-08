import 'package:flutter/material.dart';

class IssueDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> issue;

  const IssueDetailsScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final status = (issue['status'] ?? 'pending').toString().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            if (issue['images']?.isNotEmpty == true)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(
                  issue['images'][0],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF2d1b69),
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white54),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          issue['title'] ?? 'Untitled Issue',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getStatusColor(status)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issue['category'] ?? 'General',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    issue['description'] ?? 'No description provided for this reported issue.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // Visual Timeline
                  const Text('Resolution Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  _buildTimelineItem(
                    'Report Received',
                    'Your issue has been logged successfully.',
                    '2023-10-25 09:30 AM',
                    true,
                    isLast: status == 'pending',
                  ),
                  _buildTimelineItem(
                    'Team Assigned',
                    'Maintenace team dispatched for assessment.',
                    '2023-10-26 10:00 AM',
                    status == 'in_progress' || status == 'resolved',
                    isLast: status == 'in_progress',
                    showTeam: true,
                  ),
                  _buildTimelineItem(
                    'Issue Resolved',
                    'Repair works completed and verified.',
                    '2023-10-28 04:15 PM',
                    status == 'resolved',
                    isLast: true,
                    isCompleted: status == 'resolved',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved': return Colors.green;
      case 'in_progress': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildTimelineItem(String title, String desc, String time, bool isActive, {bool isLast = false, bool isCompleted = false, bool showTeam = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? (isCompleted ? Colors.green : const Color(0xFF6366f1)) : Colors.grey.withOpacity(0.3),
                  border: Border.all(color: isActive ? (isCompleted ? Colors.green : const Color(0xFF6366f1)) : Colors.grey.withOpacity(0.5), width: 2),
                ),
                child: isActive && isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isActive ? const Color(0xFF6366f1).withOpacity(0.5) : Colors.grey.withOpacity(0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(time, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  
                  if (showTeam && isActive) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2d1b69).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366f1).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=team'),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Assigned Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('Roads & Infrastructure Unit', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/storage_service.dart';

class BursaryScreen extends StatefulWidget {
  const BursaryScreen({super.key});

  @override
  State<BursaryScreen> createState() => _BursaryScreenState();
}

class _BursaryScreenState extends State<BursaryScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  bool _showForm = false;
  int _currentStep = 0;
  bool _isSubmitting = false;
  String _institutionType = 'university';
  String _guardianRelation = 'parent';

  // Theme colors
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color bgDark = Color(0xFF000000); // Pure Black
  static const Color cardDark = Color(0xFF1C1C1C); // Dark Gray
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);
  static const Color inputBg = Color(0xFF2A2A2A); // Matches ReportIssue

  // Controllers
  final _institutionController = TextEditingController();
  final _admissionController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();
  final _annualFeesController = TextEditingController();
  final _sponsorshipDetailsController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _reasonController = TextEditingController();
  
  bool _hasHelb = false;
  bool _hasGoKSponsorship = false;
  
  final List<String> _institutions = [
    'University of Nairobi',
    'Kenyatta University',
    'JKUAT',
    'Moi University',
    'Egerton University',
    'Maseno University',
    'Other'
  ];

  @override
  void dispose() {
    _institutionController.dispose();
    _admissionController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _annualFeesController.dispose();
    _sponsorshipDetailsController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    
    // Check if online first
    final isOnline = await StorageService.isOnline();
    if (!isOnline) {
       setState(() => _isLoading = false);
       return;
    }

    try {
      final apps = await DashboardService.getMyBursaryApplications();
      if (mounted) {
        setState(() {
          _applications = apps;
        });
      }
    } catch (e) {
      debugPrint('Error loading bursaries: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitApplication() async {
    if (_institutionController.text.isEmpty || _annualFeesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Color(0xFFEF4444)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      final userId = user?['id']?.toString() ?? user?['userId']?.toString();
      final phone = user?['phone']?.toString();
      final name = user?['full_name'] ?? user?['fullName'] ?? '';

      await DashboardService.applyForBursary(
        institutionName: _institutionController.text,
        course: _courseController.text,
        yearOfStudy: _yearController.text,
        institutionType: _institutionType,
        reason: _reasonController.text,
        amountRequested: double.tryParse(_annualFeesController.text) ?? 0,
        phoneNumber: phone,
        userId: userId,
        fullName: name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application Submitted Successfully!'), backgroundColor: Color(0xFF10B981)));
        setState(() {
          _showForm = false;
          _currentStep = 0;
          _clearForm();
        });
        _loadApplications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _institutionController.clear();
    _admissionController.clear();
    _courseController.clear();
    _yearController.clear();
    _annualFeesController.clear();
    _sponsorshipDetailsController.clear();
    _guardianNameController.clear();
    _guardianPhoneController.clear();
    _reasonController.clear();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF10B981); // Green
      case 'rejected': return const Color(0xFFEF4444); // Red
      case 'pending': return const Color(0xFFF59E0B); // Orange
      default: return const Color(0xFF888888); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Background - Pure Black, no blobs
          Container(width: size.width, height: size.height, color: bgDark),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _showForm ? setState(() { _showForm = false; _currentStep = 0; }) : Navigator.pop(context),
                        icon: Icon(_showForm ? Icons.arrow_back_ios : Icons.arrow_back_ios, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          _showForm ? 'New Application' : 'Bursary Applications',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (!_showForm)
                        Container(
                          decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
                          child: IconButton(
                            onPressed: () => setState(() => _showForm = true),
                            icon: const Icon(Icons.add, color: primaryOrange),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                // Body
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: cardDark, // cardDark
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: _showForm ? _buildApplicationForm() : _buildApplicationsList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _buildApplicationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryOrange));
    }

    if (_applications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: bgDark, shape: BoxShape.circle),
                child: const Icon(Icons.school_outlined, size: 50, color: primaryOrange),
              ),
              const SizedBox(height: 24),
              const Text('No Applications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textLight)),
              const SizedBox(height: 8),
              Text('Apply for a bursary to fund your education', style: TextStyle(color: textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() => _showForm = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Apply Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _applications.length,
        itemBuilder: (ctx, i) {
          final app = _applications[i];
          final status = (app['status'] ?? 'pending').toString().toLowerCase();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF333333), // inputBg
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(app['applicationNumber'] ?? app['ref_code'] ?? '#${i + 1}', style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(app['institutionName'] ?? app['institution'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textLight)),
                const SizedBox(height: 4),
                Text(app['course'] ?? '', style: TextStyle(color: textMuted)),
                if (status == 'approved') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                        const SizedBox(width: 6),
                        Text('Approved: KES ${app['amount_approved'] ?? app['amountApproved'] ?? app['amountRequested'] ?? 0}', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                if (status == 'rejected') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(app['admin_notes'] ?? 'Application was not approved', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
                // Show admin notes if available (for any status)
                if (app['admin_notes'] != null && app['admin_notes'].toString().isNotEmpty && status != 'rejected') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: primaryOrange, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(app['admin_notes'], style: const TextStyle(color: textLight, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationForm() {
    return Column(
      children: [
        // Numbered Step Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) {
              final isActive = i <= _currentStep;
              return Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isActive ? primaryOrange : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isActive ? primaryOrange : Colors.grey.shade700, width: 2),
                    ),
                    child: Center(
                      child: isActive 
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text('${i + 1}', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (i < 3)
                    Container(
                      width: 40, height: 2,
                      color: i < _currentStep ? primaryOrange : Colors.grey.shade800,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                ],
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(['Applicant Details', 'Financial Info', 'Guardian Details', 'Reason'][_currentStep], 
            style: const TextStyle(color: primaryOrange, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: _buildCurrentStep(),
          ),
        ),
        
        // Buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textLight,
                      side: BorderSide(color: Colors.grey.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _currentStep < 3 ? _nextStep : (_isSubmitting ? null : _submitApplication),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_currentStep < 3 ? 'Continue' : (_isSubmitting ? 'Submitting...' : 'Submit Amount'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildInstitutionStep();
      case 1: return _buildFinancialStep();
      case 2: return _buildGuardianStep();
      case 3: return _buildReasonStep();
      default: return const SizedBox();
    }
  }

  Widget _buildInstitutionStep() {
    // Track selected institution separately for dropdown
    final bool isOtherSelected = _institutionController.text == 'Other' || 
        (_institutionController.text.isNotEmpty && !_institutions.contains(_institutionController.text));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Institution'),
        _buildDropdownField(
          _institutions, 
          isOtherSelected ? 'Other' : (_institutionController.text.isEmpty ? null : _institutionController.text), 
          (v) {
            if (v == 'Other') {
              setState(() => _institutionController.text = 'Other');
            } else {
              setState(() => _institutionController.text = v ?? '');
            }
          }
        ),
        if (isOtherSelected) ...[
          const SizedBox(height: 12),
          _buildTextField(
            _institutionController, 
            'Enter your institution name', 
            Icons.edit_outlined
          ),
        ],
        const SizedBox(height: 16),
        _buildLabel('Type'),
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildLabel('Admission Number'),
        _buildTextField(_admissionController, 'Enter admission no.', Icons.badge_outlined),
        const SizedBox(height: 16),
        _buildLabel('Course'),
        _buildTextField(_courseController, 'Enter course name', Icons.book_outlined),
        const SizedBox(height: 16),
        _buildLabel('Year of Study'),
        _buildTextField(_yearController, '1', Icons.calendar_today_outlined, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildFinancialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Annual Fees (KES)'),
        _buildTextField(_annualFeesController, 'Enter amount', Icons.payments_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        _buildSwitch('Do you have HELB Loan?', _hasHelb, (v) => setState(() => _hasHelb = v)),
        _buildSwitch('Any other GoK Sponsorship?', _hasGoKSponsorship, (v) => setState(() => _hasGoKSponsorship = v)),
        if (_hasGoKSponsorship) ...[
          const SizedBox(height: 16),
          _buildTextField(_sponsorshipDetailsController, 'Specify sponsorship', Icons.info_outline),
        ],
      ],
    );
  }

  Widget _buildGuardianStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Guardian Name'),
        _buildTextField(_guardianNameController, 'Enter full name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildLabel('Guardian Phone'),
        _buildTextField(_guardianPhoneController, 'Enter phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildLabel('Relationship'),
        _buildRelationSelector(),
      ],
    );
  }

  Widget _buildReasonStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Why do you need this bursary?'),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A), // Dark black
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: TextField(
            controller: _reasonController,
            maxLines: 6,
            style: const TextStyle(color: Colors.white), // White text
            decoration: InputDecoration(
              hintText: 'Explain your situation...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Be specific about your needs for better chances', style: TextStyle(color: Colors.amber.shade900, fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textLight)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark black
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white), // White text
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: primaryOrange, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField(List<String> items, String? value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark black
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text('Select institution', style: TextStyle(color: Colors.grey.shade600)),
        dropdownColor: cardDark,
        style: const TextStyle(color: textLight),
        icon: const Icon(Icons.keyboard_arrow_down, color: primaryOrange),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.school_outlined, color: primaryOrange, size: 22),
          prefixIconConstraints: BoxConstraints(minWidth: 40),
          border: InputBorder.none,
        ),
        items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = ['university', 'college', 'polytechnic', 'secondary'];
    final labels = ['Uni', 'College', 'Poly', 'School'];
    return Row(
      children: List.generate(types.length, (i) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _institutionType = types[i]),
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _institutionType == types[i] ? primaryOrange : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _institutionType == types[i] ? primaryOrange : Colors.grey.shade800),
            ),
            child: Text(
              labels[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _institutionType == types[i] ? Colors.white : textMuted,
                fontWeight: _institutionType == types[i] ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildSwitch(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark black
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: textLight))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildRelationSelector() {
    final relations = ['parent', 'guardian', 'sibling', 'other'];
    final icons = [Icons.family_restroom, Icons.person_outline, Icons.people_outline, Icons.more_horiz];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(relations.length, (i) {
        final isSelected = _guardianRelation == relations[i];
        return GestureDetector(
          onTap: () => setState(() => _guardianRelation = relations[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? primaryOrange : inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? primaryOrange : Colors.grey.shade800),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[i], color: isSelected ? Colors.white : textMuted, size: 18),
                const SizedBox(width: 6),
                Text(
                  relations[i][0].toUpperCase() + relations[i].substring(1),
                  style: TextStyle(color: isSelected ? Colors.white : textMuted),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

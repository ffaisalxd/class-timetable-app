import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';
import '../models/programme.dart';
import '../utils/academic_options.dart';
import 'splash_page.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'lecturer';
  String? _selectedProgrammeCode;
  int? _selectedSemester;
  int? _selectedSection;
  bool _isLoading = false;

  bool get _needsProgrammeInfo => _selectedRole == 'student';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAddUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await credential.user!.updateDisplayName(_nameController.text.trim());

      final userData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_needsProgrammeInfo) {
        userData['programmeCode'] = _selectedProgrammeCode ?? '';
        userData['semester'] = _selectedSemester ?? 0;
        userData['section'] = _selectedSection ?? 0;
      }

      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set(userData);

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      await showAppDialog(
        context: context,
        title: 'User Created',
        message: 'The account was created successfully. Please log back in as Admin to continue.',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.primary,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SplashPage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Could not create the account.';
      if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'weak-password') {
        message = 'That password is too weak.';
      }

      if (!mounted) return;
      showAppDialog(
        context: context,
        title: 'Failed',
        message: message,
        icon: Icons.error_outline,
        iconColor: AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter an email';
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Temporary Password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (value) {
                    if (value == null || value.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'lecturer', child: Text('Lecturer')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      if (!_needsProgrammeInfo) {
                        _selectedProgrammeCode = null;
                        _selectedSemester = null;
                        _selectedSection = null;
                      }
                    });
                  },
                ),
                if (_needsProgrammeInfo) ...[
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('programmes').snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final programmes = docs
                          .map((doc) => Programme.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
                          .toList();

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedProgrammeCode,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Programme', prefixIcon: Icon(Icons.school_outlined)),
                        items: programmes
                            .map((p) => DropdownMenuItem(value: p.code, child: Text('${p.code} - ${p.name}')))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProgrammeCode = value;
                          });
                        },
                        validator: (value) => (_needsProgrammeInfo && value == null) ? 'Please select a programme' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedSemester,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Semester'),
                          items: kSemesterOptions
                              .map((s) => DropdownMenuItem(value: s, child: Text('Semester $s')))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSemester = value;
                            });
                          },
                          validator: (value) => (_needsProgrammeInfo && value == null) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedSection,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Section'),
                          items: kSectionOptions
                              .map((s) => DropdownMenuItem(value: s, child: Text('Section $s')))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSection = value;
                            });
                          },
                          validator: (value) => (_needsProgrammeInfo && value == null) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAddUser,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
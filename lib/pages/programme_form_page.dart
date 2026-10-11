import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/programme.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';

class ProgrammeFormPage extends StatefulWidget {
  final Programme? existingProgramme;

  const ProgrammeFormPage({super.key, this.existingProgramme});

  @override
  State<ProgrammeFormPage> createState() => _ProgrammeFormPageState();
}

class _ProgrammeFormPageState extends State<ProgrammeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  bool _isLoading = false;

  bool get _isEditing => widget.existingProgramme != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProgramme;
    _codeController = TextEditingController(text: existing?.code ?? '');
    _nameController = TextEditingController(text: existing?.name ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final data = {
      'code': _codeController.text.trim().toUpperCase(),
      'name': _nameController.text.trim(),
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('programmes')
            .doc(widget.existingProgramme!.id)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('programmes').add(data);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showAppDialog(
        context: context,
        title: 'Error',
        message: 'Something went wrong while saving. Please try again.',
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Programme' : 'Add Programme')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Programme Code (e.g. CC101)',
                    prefixIcon: Icon(Icons.qr_code_2),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Programme Name (e.g. Diploma in Computer Science)',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(_isEditing ? 'Save Changes' : 'Add Programme'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
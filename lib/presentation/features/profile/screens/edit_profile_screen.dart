import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/user_remote_datasource.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserRemoteDataSource _userDataSource = sl<UserRemoteDataSource>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  String? _selectedField;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _fieldOptions = [
    'Web Development',
    'Mobile Development',
    'UI/UX Design',
    'Data Science & Analytics',
    'AI & Machine Learning',
    'Digital Marketing & Product',
    'Cybersecurity',
    'Cloud Computing',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final user = await _authRepo.getSavedUser();
      if (!mounted) return;
      if (user != null) {
        _populateFields(user);
      }
      // Also fetch latest profile
      final latest = await _userDataSource.getProfile();
      if (!mounted) return;
      _nameController.text = latest['name'] ?? _nameController.text;
      _phoneController.text = latest['phone'] ?? _phoneController.text;
      _bioController.text = latest['bio'] ?? _bioController.text;
      if (latest['selectedField'] != null && _fieldOptions.contains(latest['selectedField'])) {
        _selectedField = latest['selectedField'];
      }
    } catch (_) {
      // Fallback already populated from savedUser if any
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateFields(UserModel user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone ?? '';
    _bioController.text = user.bio ?? '';
    if (user.selectedField != null && _fieldOptions.contains(user.selectedField)) {
      _selectedField = user.selectedField;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        if (_selectedField != null) 'selectedField': _selectedField,
      };

      await _userDataSource.updateProfile(payload);
      // Refresh local cache
      await _authRepo.refreshProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Profil berhasil diperbarui'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Photo Avatar
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'M',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surface, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Nama Lengkap
                    _buildLabel('Nama Lengkap'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Masukkan nama lengkap', Icons.person_outline_rounded),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Nomor WhatsApp
                    _buildLabel('Nomor WhatsApp'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Contoh: 081234567890', Icons.phone_android_rounded),
                    ),

                    const SizedBox(height: 18),

                    // Bidang Minat
                    _buildLabel('Bidang Minat Belajar'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedField,
                      decoration: _inputDecoration('Pilih bidang minat', Icons.school_outlined),
                      items: _fieldOptions.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedField = val;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    // Bio Singkat
                    _buildLabel('Bio Singkat'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: _inputDecoration('Tuliskan sepatah kata tentang Anda...', Icons.notes_rounded),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/profile_model.dart' show Profile;
import '../provider/profile_provider.dart' show profileProvider;


class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _avatarFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile?.name ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    if (profile?.avatarPath != null && profile!.avatarPath.isNotEmpty) {
      _avatarFile = File(profile.avatarPath);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return;

      // Copy to app documents directory for long-term access
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(picked.path);
      final savedPath = p.join(appDir.path, fileName);

      final savedFile = await File(picked.path).copy(savedPath);

      if (!mounted) return;

      setState(() {
        _avatarFile = savedFile;
      });

      // Update immediate in provider (keeps UI and storage in sync)
      ref.read(profileProvider.notifier).updateProfile(avatarPath: savedFile.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() {
      _saving = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final avatarPath = _avatarFile?.path ?? '';

      final existing = ref.read(profileProvider);

      if (existing == null) {
        final newProfile = Profile(
          name: name,
          email: email,
          avatarPath: avatarPath,
        );
        ref.read(profileProvider.notifier).saveProfile(newProfile);
      } else {
        ref.read(profileProvider.notifier).saveProfile(
          existing.copyWith(name: name, email: email, avatarPath: avatarPath),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      } 
    }
  }

  Future<void> _removeAvatar() async {
    if (!mounted) return;
    setState(() {
      _avatarFile = null;
    });
    ref.read(profileProvider.notifier).updateProfile(avatarPath: '');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withAlpha((0.25 * 255).round()),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: cs.surface,
                        backgroundImage: _avatarFile != null
                            ? FileImage(_avatarFile!) as ImageProvider
                            : (profile?.avatarPath != null && profile!.avatarPath.isNotEmpty)
                                ? FileImage(File(profile.avatarPath))
                                : null,
                        child: (_avatarFile == null && (profile?.avatarPath == null || profile!.avatarPath.isEmpty))
                            ? Icon(Icons.person, size: 56, color: cs.onSurfaceVariant)
                            : null,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.edit),
                          tooltip: 'Change avatar',
                          color: cs.primary,
                        ),
                        if (_avatarFile != null || (profile?.avatarPath != null && profile!.avatarPath.isNotEmpty))
                          IconButton(
                            onPressed: _removeAvatar,
                            icon: const Icon(Icons.delete),
                            tooltip: 'Remove avatar',
                            color: cs.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: cs.surface,
                      ),
                      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Please enter a name';
                        if (val.length < 2) return 'Name too short';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: cs.surface,
                      ),
                      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Please enter email';
                        final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
                        if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Profile'),
                    ),

                    const SizedBox(height: 8),

                    OutlinedButton(
                      onPressed: () {
                        // Reset form to last saved values
                        final p = ref.read(profileProvider);
                        _nameController.text = p?.name ?? '';
                        _emailController.text = p?.email ?? '';
                        setState(() {
                          _avatarFile = (p?.avatarPath != null && p!.avatarPath.isNotEmpty) ? File(p.avatarPath) : null;
                        });
                      },
                      child: const Text('Reset'),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Tip: Avatar image is stored locally; picking an image will copy it into the app documents folder.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
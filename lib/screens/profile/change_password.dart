import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;


  final String _currentPassword = "admin123";

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: isSuccess
            ? const Color.fromARGB(255, 33, 150, 83) 
            : const Color.fromARGB(255, 172, 45, 45), 
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleChangePassword() {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all password fields.');
      return;
    }
    if (oldPassword != _currentPassword) {
      _showSnackBar('The old password you entered is incorrect.');
      return;
    }
    if (newPassword.length < 6) {
      _showSnackBar('New password must be at least 6 characters long.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match.');
      return;
    }
    _showSnackBar('Password changed successfully!', isSuccess: true);
    
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
    });
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isVisible,
    ValueSetter<bool> onVisibilityToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Color.fromARGB(178, 0, 0, 0)),
        prefixIcon: const Icon(
          Icons.lock,
          color: Color.fromARGB(197, 0, 0, 0),
        ),
        filled: true,
        fillColor: const Color.fromRGBO(217, 193, 159, 1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color.fromARGB(221, 17, 17, 17), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black26, width: 1),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.black54,
          ),
          onPressed: () {
            onVisibilityToggle(!isVisible);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(190, 101, 54, 1),
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 100, 40, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Security Settings',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),

              // Old Password
              _buildPasswordField(
                "Old Password",
                _oldPasswordController,
                _isOldPasswordVisible,
                (value) { setState(() => _isOldPasswordVisible = value); },
              ),
              const SizedBox(height: 20),

              // New Password
              _buildPasswordField(
                "New Password",
                _newPasswordController,
                _isNewPasswordVisible,
                (value) { setState(() => _isNewPasswordVisible = value); },
              ),
              const SizedBox(height: 20),

              // Confirm New Password
              _buildPasswordField(
                "Confirm New Password",
                _confirmPasswordController,
                _isConfirmPasswordVisible,
                (value) { setState(() => _isConfirmPasswordVisible = value); },
              ),
              const SizedBox(height: 40),

              // Change Password Button
                Center( 
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(190, 101, 54, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Update Password",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

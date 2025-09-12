import 'package:flutter/material.dart';

class AuthStyles {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF059669);

  static InputDecoration getInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    minimumSize: const Size(double.infinity, 50),
  );

  static ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    minimumSize: const Size(double.infinity, 50),
  );

  static const TextStyle headingStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

 static const TextStyle accountheadingStyle = TextStyle(
    fontSize: 16,
    color: Colors.blueGrey,
  );

}
// Vibe — Social & Messaging App
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Themed text field that supports password visibility toggle, prefix icons,
/// validation, and respects dark mode via [Theme.of(context).brightness].
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool isPassword;
  final bool readOnly;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      readOnly: widget.readOnly,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: 20,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              )
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: widget.readOnly
            ? (isDark ? AppColors.elevatedDark : AppColors.bgLight)
            : (isDark ? AppColors.elevatedDark : Colors.white),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ── Stat Card (replaces GradientCard) ────────────────────────────────────────
class GradientCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String? subtitle;

  const GradientCard({
    super.key, required this.title, required this.value,
    required this.icon, required this.gradient, this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.textMuted, size: 18),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'pending': return AppColors.warning;
      case 'in_progress': return AppColors.info;
      case 'submitted': return AppColors.textSecondary;
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.textMuted;
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'in_progress': return 'In Progress';
      default: return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withOpacity(0.25)),
      ),
      child: Text(_label, style: TextStyle(
        color: _color, fontSize: 11, fontWeight: FontWeight.w600,
      )),
    );
  }
}

// ── Priority Badge ────────────────────────────────────────────────────────────
class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  Color get _color {
    switch (priority.toLowerCase()) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      case 'low': return AppColors.success;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}

// ── Loading Shimmer ──────────────────────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 8});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceVariant,
              AppColors.surfaceElevated,
              AppColors.surfaceVariant,
            ],
            stops: [0, _anim.value, 1],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 14,
          fontWeight: FontWeight.w700, letterSpacing: 0.2,
        )),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12,
              decoration: TextDecoration.underline,
            )),
          ),
      ],
    );
  }
}

// ── Primary Button (replaces GradientButton) ──────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color> colors;
  final double height;
  final IconData? icon;

  const GradientButton({
    super.key, required this.label, this.onPressed,
    this.isLoading = false, this.colors = AppColors.primaryGradient,
    this.height = 48, this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isLoading ? AppColors.surfaceVariant : AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 7)],
                  Text(label, style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
        ),
      ),
    );
  }
}

// ── Custom TextField ──────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key, required this.controller, required this.label,
    this.prefixIcon, this.obscureText = false, this.suffix,
    this.keyboardType, this.maxLines = 1, this.hint,
    this.readOnly = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
        suffixIcon: suffix,
      ),
    );
  }
}

// ── Snackbars ────────────────────────────────────────────────────────────────
void showErrorSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13))),
    ]),
    backgroundColor: AppColors.error,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(16),
  ));
}

void showSuccessSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13))),
    ]),
    backgroundColor: AppColors.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(16),
  ));
}

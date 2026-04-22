import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _nameCtrl       = TextEditingController();
  final _ageCtrl        = TextEditingController();
  final _dobCtrl        = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _cityCtrl       = TextEditingController();
  final _stateCtrl      = TextEditingController();
  final _pincodeCtrl    = TextEditingController();
  final _aadharCtrl     = TextEditingController();
  final _panCtrl        = TextEditingController();
  final _bankNameCtrl   = TextEditingController();
  final _bankAccCtrl    = TextEditingController();
  final _bankIfscCtrl   = TextEditingController();
  final _bankBranchCtrl = TextEditingController();
  final _upiCtrl        = TextEditingController();
  String? _gender;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(profileProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose(); _ageCtrl.dispose(); _dobCtrl.dispose();
    _phoneCtrl.dispose(); _addressCtrl.dispose(); _cityCtrl.dispose();
    _stateCtrl.dispose(); _pincodeCtrl.dispose(); _aadharCtrl.dispose();
    _panCtrl.dispose(); _bankNameCtrl.dispose(); _bankAccCtrl.dispose();
    _bankIfscCtrl.dispose(); _bankBranchCtrl.dispose(); _upiCtrl.dispose();
    super.dispose();
  }

  void _populateFields(profile) {
    if (_populated) return;
    _populated = true;
    _nameCtrl.text       = profile.fullName;
    _ageCtrl.text        = profile.age?.toString() ?? '';
    _dobCtrl.text        = profile.dateOfBirth ?? '';
    _phoneCtrl.text      = profile.phone ?? '';
    _addressCtrl.text    = profile.address ?? '';
    _cityCtrl.text       = profile.city ?? '';
    _stateCtrl.text      = profile.state ?? '';
    _pincodeCtrl.text    = profile.pincode ?? '';
    _aadharCtrl.text     = profile.aadharNumber ?? '';
    _panCtrl.text        = profile.panNumber ?? '';
    _bankNameCtrl.text   = profile.bankName ?? '';
    _bankAccCtrl.text    = profile.bankAccountNumber ?? '';
    _bankIfscCtrl.text   = profile.bankIfsc ?? '';
    _bankBranchCtrl.text = profile.bankBranch ?? '';
    _upiCtrl.text        = profile.upiId ?? '';
    _gender              = profile.gender;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth   = ref.watch(authProvider);
    final profSt = ref.watch(profileProvider);
    if (profSt.profile != null) _populateFields(profSt.profile!);

    final user = profSt.profile ?? auth.user;
    final name = user?.fullName ?? 'User';
    final role = user?.role ?? '';
    final balance = user?.walletBalance ?? 0.0;
    final initials = name.split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.surface,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(child: Text(initials, style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 20, fontWeight: FontWeight.w700,
                        ))),
                      ),
                      const SizedBox(height: 10),
                      Text(name, style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17, fontWeight: FontWeight.w700,
                      )),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(role.toUpperCase(), style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                          )),
                        ),
                        const SizedBox(width: 8),
                        Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12, fontWeight: FontWeight.w600,
                        )),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(text: 'Personal'),
                Tab(text: 'KYC'),
                Tab(text: 'Bank'),
              ],
            ),
          ),
        ],
        body: profSt.isLoading
            ? const Center(child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2))
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _personalTab(),
                  _kycTab(),
                  _bankTab(),
                ],
              ),
      ),
    );
  }

  Widget _personalTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      _card('Basic', [
        AppTextField(controller: _nameCtrl, label: 'Full Name',
            prefixIcon: Icons.person_outline),
        const SizedBox(height: 10),
        AppTextField(controller: _ageCtrl, label: 'Age',
            prefixIcon: Icons.cake_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        AppTextField(controller: _dobCtrl, label: 'Date of Birth (DD/MM/YYYY)',
            prefixIcon: Icons.calendar_today_outlined),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _gender,
          dropdownColor: AppColors.surface,
          decoration: const InputDecoration(labelText: 'Gender',
              prefixIcon: Icon(Icons.wc_outlined, size: 18)),
          items: ['Male', 'Female', 'Other', 'Prefer not to say']
              .map((g) => DropdownMenuItem(value: g,
                  child: Text(g, style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14))))
              .toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: 10),
        AppTextField(controller: _phoneCtrl, label: 'Phone',
            prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
      ]),
      const SizedBox(height: 14),
      _card('Address', [
        AppTextField(controller: _addressCtrl, label: 'Address',
            prefixIcon: Icons.home_outlined, maxLines: 2),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: AppTextField(controller: _cityCtrl, label: 'City',
              prefixIcon: Icons.location_city_outlined)),
          const SizedBox(width: 10),
          Expanded(child: AppTextField(controller: _stateCtrl, label: 'State',
              prefixIcon: Icons.map_outlined)),
        ]),
        const SizedBox(height: 10),
        AppTextField(controller: _pincodeCtrl, label: 'Pincode',
            prefixIcon: Icons.pin_drop_outlined, keyboardType: TextInputType.number),
      ]),
      const SizedBox(height: 20),
      _saveBtn(),
      const SizedBox(height: 10),
      _logoutBtn(),
    ]),
  );

  Widget _kycTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withOpacity(0.2)),
        ),
        child: const Row(children: [
          Icon(Icons.lock_outline, color: AppColors.warning, size: 14),
          SizedBox(width: 8),
          Expanded(child: Text(
            'KYC details are kept private and used only for verification.',
            style: TextStyle(color: AppColors.warning, fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 14),
      _card('Identity', [
        AppTextField(controller: _aadharCtrl, label: 'Aadhar Number',
            prefixIcon: Icons.credit_card_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        AppTextField(controller: _panCtrl, label: 'PAN Number',
            prefixIcon: Icons.article_outlined),
      ]),
      const SizedBox(height: 20),
      _saveBtn(),
    ]),
  );

  Widget _bankTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      _card('Bank Account', [
        AppTextField(controller: _bankNameCtrl, label: 'Bank Name',
            prefixIcon: Icons.account_balance_outlined),
        const SizedBox(height: 10),
        AppTextField(controller: _bankAccCtrl, label: 'Account Number',
            prefixIcon: Icons.pin_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        AppTextField(controller: _bankIfscCtrl, label: 'IFSC Code',
            prefixIcon: Icons.code_outlined),
        const SizedBox(height: 10),
        AppTextField(controller: _bankBranchCtrl, label: 'Branch',
            prefixIcon: Icons.location_on_outlined),
      ]),
      const SizedBox(height: 14),
      _card('UPI', [
        AppTextField(controller: _upiCtrl, label: 'UPI ID',
            prefixIcon: Icons.phone_android_outlined),
      ]),
      const SizedBox(height: 20),
      _saveBtn(),
    ]),
  );

  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(
        color: AppColors.textMuted, fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 0.5,
      )),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  Widget _saveBtn() {
    final profSt = ref.watch(profileProvider);
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        label: 'Save Changes',
        isLoading: profSt.isSaving,
        onPressed: _saveAll,
      ),
    );
  }

  Widget _logoutBtn() => SizedBox(
    width: double.infinity,
    child: GestureDetector(
      onTap: () async {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: const Center(child: Text('Sign Out', style: TextStyle(
          color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600,
        ))),
      ),
    ),
  );

  Future<void> _saveAll() async {
    final data = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      if (_ageCtrl.text.isNotEmpty) 'age': int.tryParse(_ageCtrl.text),
      if (_dobCtrl.text.isNotEmpty) 'date_of_birth': _dobCtrl.text.trim(),
      if (_gender != null) 'gender': _gender,
      if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
      if (_cityCtrl.text.isNotEmpty) 'city': _cityCtrl.text.trim(),
      if (_stateCtrl.text.isNotEmpty) 'state': _stateCtrl.text.trim(),
      if (_pincodeCtrl.text.isNotEmpty) 'pincode': _pincodeCtrl.text.trim(),
      if (_aadharCtrl.text.isNotEmpty) 'aadhar_number': _aadharCtrl.text.trim(),
      if (_panCtrl.text.isNotEmpty) 'pan_number': _panCtrl.text.trim(),
      if (_bankNameCtrl.text.isNotEmpty) 'bank_name': _bankNameCtrl.text.trim(),
      if (_bankAccCtrl.text.isNotEmpty) 'bank_account_number': _bankAccCtrl.text.trim(),
      if (_bankIfscCtrl.text.isNotEmpty) 'bank_ifsc': _bankIfscCtrl.text.trim(),
      if (_bankBranchCtrl.text.isNotEmpty) 'bank_branch': _bankBranchCtrl.text.trim(),
      if (_upiCtrl.text.isNotEmpty) 'upi_id': _upiCtrl.text.trim(),
    };
    final ok = await ref.read(profileProvider.notifier).update(data);
    if (mounted) {
      ok
          ? showSuccessSnack(context, 'Profile saved!')
          : showErrorSnack(context, 'Failed to save profile');
    }
  }
}

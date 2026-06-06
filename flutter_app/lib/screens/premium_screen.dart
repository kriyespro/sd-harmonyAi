import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class PremiumScreen extends StatefulWidget {
  final String? featureBlocked;
  const PremiumScreen({super.key, this.featureBlocked});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _loading = false;
  Map<String, dynamic>? _billingStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await ApiService.getBillingStatus();
    if (mounted) setState(() => _billingStatus = status);
  }

  Future<void> _activateTest() async {
    setState(() { _loading = true; _error = null; });
    final ok = await ApiService.activateTestPremium();
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        await context.read<AuthProvider>().refreshPremiumStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✦ Premium activated! All features unlocked.'), backgroundColor: Color(0xFF7c3aed)),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() => _error = 'Activation failed. Try again.');
      }
    }
  }

  Future<void> _subscribe() async {
    setState(() { _loading = true; _error = null; });
    final order = await ApiService.createOrder();
    setState(() => _loading = false);
    if (order == null) {
      setState(() => _error = 'Could not create order. Check connection.');
      return;
    }
    // Show order confirmation sheet
    if (mounted) _showPaymentSheet(order);
  }

  void _showPaymentSheet(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(
        order: order,
        onSuccess: () async {
          await context.read<AuthProvider>().refreshPremiumStatus();
          if (mounted) Navigator.pop(context, true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AuthProvider>().isPremium;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('HarmonyAI Premium'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _HeroCard(featureBlocked: widget.featureBlocked),
            const SizedBox(height: 20),
            _FeaturesCard(),
            const SizedBox(height: 20),
            _PricingCard(),
            const SizedBox(height: 24),
            if (isPremium) ...[
              _PremiumBadgeCard(billingStatus: _billingStatus),
            ] else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFef4444), fontSize: 14)),
                ),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF7c3aed)))
                  : Column(children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _subscribe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7c3aed),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Subscribe ₹199/month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _activateTest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7c3aed),
                          side: const BorderSide(color: Color(0xFF7c3aed)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Activate Test Premium (Dev)'),
                      ),
                    ]),
            ],
            const SizedBox(height: 20),
            _CounselingSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String? featureBlocked;
  const _HeroCard({this.featureBlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7c3aed), Color(0xFF4f46e5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: [
        const Text('✦', style: TextStyle(color: Colors.white, fontSize: 40)),
        const SizedBox(height: 12),
        const Text('HarmonyAI Premium', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          featureBlocked != null
              ? 'You\'ve reached your free limit for $featureBlocked. Upgrade to continue.'
              : 'Unlimited AI insights for healthier relationships.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFe0d7ff), fontSize: 14, height: 1.5),
        ),
      ]),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const free = [
      '2 conflict analyses / month',
      '1 pattern detection / month',
      '1 weekly report / month',
      '10 AI coach messages / month',
    ];
    const premium = [
      'Unlimited conflict analyses',
      'Unlimited pattern detection',
      'Unlimited weekly reports',
      'Unlimited AI coach',
      'Priority insights',
      'Counselor referrals',
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('What you get', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _FeatureColumn(title: 'Free', features: free, isPremium: false)),
          const SizedBox(width: 16),
          Expanded(child: _FeatureColumn(title: 'Premium', features: premium, isPremium: true)),
        ]),
      ]),
    );
  }
}

class _FeatureColumn extends StatelessWidget {
  final String title;
  final List<String> features;
  final bool isPremium;
  const _FeatureColumn({required this.title, required this.features, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final color = isPremium ? const Color(0xFF7c3aed) : const Color(0xFF6B7280);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 12),
      ...features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(isPremium ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(f, style: TextStyle(fontSize: 12, color: isPremium ? const Color(0xFF374151) : const Color(0xFF9CA3AF)))),
        ]),
      )),
    ]);
  }
}

class _PricingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7c3aed).withOpacity(0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Premium Plan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF4c1d95))),
          const SizedBox(height: 4),
          const Text('Billed monthly · Cancel anytime', style: TextStyle(fontSize: 12, color: Color(0xFF7c3aed))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('₹199', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7c3aed))),
          const Text('/month', style: TextStyle(fontSize: 12, color: Color(0xFF7c3aed))),
        ]),
      ]),
    );
  }
}

class _PremiumBadgeCard extends StatelessWidget {
  final Map<String, dynamic>? billingStatus;
  const _PremiumBadgeCard({this.billingStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF4f46e5)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        const Text('✦', style: TextStyle(color: Colors.white, fontSize: 28)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('You\'re Premium!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('All AI features unlocked.', style: TextStyle(color: Color(0xFFe0d7ff), fontSize: 13)),
        ])),
      ]),
    );
  }
}

class _CounselingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Professional Support', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 4),
        const Text('Sometimes AI isn\'t enough. Reach a real counselor.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const SizedBox(height: 14),
        _CounselorTile(name: 'iCall', type: 'Online Therapy', country: 'India 🇮🇳', url: 'https://icallhelpline.org'),
        _CounselorTile(name: 'Vandrevala Foundation', type: '24/7 Helpline', country: 'India 🇮🇳', url: 'https://vandrevalafoundation.com'),
        _CounselorTile(name: 'BetterHelp', type: 'Online Therapy', country: 'Global 🌍', url: 'https://betterhelp.com'),
        _CounselorTile(name: 'Talkspace', type: 'Online Therapy', country: 'Global 🌍', url: 'https://talkspace.com'),
      ]),
    );
  }
}

class _CounselorTile extends StatelessWidget {
  final String name;
  final String type;
  final String country;
  final String url;
  const _CounselorTile({required this.name, required this.type, required this.country, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _launch(context, url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              Text('$type · $country', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF9CA3AF)),
          ]),
        ),
      ),
    );
  }

  void _launch(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $url'),
        action: SnackBarAction(label: 'Copy', onPressed: () {}),
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onSuccess;
  const _PaymentSheet({required this.order, required this.onSuccess});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  bool _processing = false;

  Future<void> _simulatePay() async {
    setState(() => _processing = true);
    final ok = await ApiService.verifyPayment(
      widget.order['order_id'],
      'pay_test_${DateTime.now().millisecondsSinceEpoch}',
      'test_signature',
    );
    if (mounted) {
      setState(() => _processing = false);
      if (ok) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Try again.'), backgroundColor: Color(0xFFef4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('Complete Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('HarmonyAI Premium', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Text('₹199', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7c3aed))),
            ]),
            const SizedBox(height: 4),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Monthly subscription', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              Text('Billed today', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ]),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Order: ${widget.order['order_id']}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 20),
        _processing
            ? const CircularProgressIndicator(color: Color(0xFF7c3aed))
            : SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _simulatePay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7c3aed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Pay ₹199 (Test)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
        const SizedBox(height: 12),
        const Text('100% secure · SSL encrypted · Cancel anytime', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ]),
    );
  }
}

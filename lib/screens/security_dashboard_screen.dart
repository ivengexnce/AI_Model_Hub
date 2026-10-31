import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/security_engine.dart';
import '../theme/app_theme.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _unlockAccountController = TextEditingController();
  final TextEditingController _totpVerifyController = TextEditingController();

  String? _generatedMfaSecret;
  bool _showMfaSetup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _unlockAccountController.dispose();
    _totpVerifyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final metrics = SecurityAuditLogger.getMetrics();
    final events = SecurityAuditLogger.events;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17), // Dark slate terminal background
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 10),
            Text(
              'BROML // THREAT DEFENSE PLATFORM',
              style: AppTheme.mono(size: 14, color: Colors.white, weight: FontWeight.w700),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 2,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: AppTheme.mono(size: 12, weight: FontWeight.w600),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'THREAT MONITOR'),
            Tab(text: 'ACCOUNT SECURITY & MFA'),
            Tab(text: 'IP INTELLIGENCE'),
            Tab(text: 'SECURITY ANALYTICS'),
            Tab(text: 'ADMINISTRATION'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(metrics, events),
          _buildThreatMonitorTab(events),
          _buildAccountSecurityTab(auth),
          _buildIpIntelligenceTab(events),
          _buildSecurityAnalyticsTab(metrics),
          _buildAdministrationTab(auth),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Overview Tab
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(Map<String, dynamic> metrics, List<SecurityEvent> events) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Philosophy Banner: "It's not X, it's Y"
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131D2E),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, color: Color(0xFF38BDF8), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "It's not about simply blocking suspicious requests.",
                        style: AppTheme.mono(size: 13, color: const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "It's about distinguishing legitimate researchers from automated threats with adaptive Cloudflare edge security.",
                        style: AppTheme.mono(size: 13, color: const Color(0xFFF1F5F9), weight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bento Metric Cards Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _metricTile('TOTAL EVENTS', '${metrics['totalEvents']}', Icons.history, const Color(0xFF38BDF8)),
              _metricTile('SUCCESSFUL LOGINS', '${metrics['loginsSuccess']}', Icons.check_circle_outline, const Color(0xFF34D399)),
              _metricTile('FAILED ATTEMPTS', '${metrics['loginsFailed']}', Icons.error_outline, const Color(0xFFF87171)),
              _metricTile('ACTIVE LOCKOUTS', '${metrics['lockoutsTriggered']}', Icons.lock_outline, const Color(0xFFFBBF24)),
              _metricTile('MFA VERIFICATIONS', '${metrics['mfaEvents']}', Icons.vpn_key_outlined, const Color(0xFF818CF8)),
              _metricTile('CAPTCHA CHALLENGES', '${metrics['turnstileChallenges']}', Icons.verified_user_outlined, const Color(0xFF2DD4BF)),
            ],
          ),
          const SizedBox(height: 30),

          // Features Checkmark List
          Text('PLATFORM DEFENSE CAPABILITIES', style: AppTheme.mono(size: 14, color: Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              children: const [
                _CheckmarkRow('Argon2id & PBKDF2 robust credential hashing with breach dictionary lookups'),
                _CheckmarkRow('RFC 6238 TOTP Two-Factor Authentication with replay window rejection'),
                _CheckmarkRow('Dual-tier account and IP rate limiting mitigating distributed brute-force'),
                _CheckmarkRow('Cloudflare Turnstile token validation preventing automated credential stuffing'),
                _CheckmarkRow('Edge WAF origin shielding rejecting requests bypassing Cloudflare infrastructure'),
                _CheckmarkRow('Progressive backoff delays protecting user accounts from systematic lockouts'),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 3 Clearly Differentiated Tiers
          Text('PROTECTION TIERS', style: AppTheme.mono(size: 14, color: Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _tierCard('RESEARCHER TIER', 'Essential individual protection', 'Free', [
                'Argon2id credential safety',
                'Email verification workflows',
                'Client IP rate limiting',
                'Session revocation',
              ])),
              const SizedBox(width: 14),
              Expanded(child: _tierCard('ENTERPRISE MLOPS', 'Advanced multi-user security', '\$49 / mo', [
                'Full RFC 6238 TOTP MFA',
                'Single-use recovery codes',
                'Cloudflare Turnstile challenges',
                'Account-based brute-force defense',
              ], isFeatured: true)),
              const SizedBox(width: 14),
              Expanded(child: _tierCard('SOVEREIGN CLOUD', 'High-assurance zero-trust defense', '\$249 / mo', [
                'Dedicated Cloudflare Edge WAF',
                'Zero-Trust origin secret verification',
                'Real-time threat risk scoring',
                'SOC2 compliant immutable audit logs',
              ])),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Threat Monitor Tab (Live Security Event Stream)
  // ---------------------------------------------------------------------------
  Widget _buildThreatMonitorTab(List<SecurityEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          'NO THREAT EVENTS RECORDED YET. SYSTEM NOMINAL.',
          style: AppTheme.mono(size: 13, color: const Color(0xFF64748B)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: events.length,
      separatorBuilder: (_, _) => const Divider(color: Color(0xFF1E293B), height: 1),
      itemBuilder: (context, index) {
        final ev = events[index];
        final color = ev.severity == SecuritySeverity.critical
            ? const Color(0xFFEF4444)
            : ev.severity == SecuritySeverity.warning
                ? const Color(0xFFF59E0B)
                : const Color(0xFF38BDF8);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          color: index % 2 == 0 ? const Color(0xFF0F172A) : const Color(0xFF0B0F17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: color),
                ),
                child: Text(
                  ev.severity.name.toUpperCase(),
                  style: AppTheme.mono(size: 10, color: color, weight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ev.summary, style: AppTheme.mono(size: 13, color: Colors.white, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Account: ${ev.accountIdentifier}  |  IP: ${ev.ipAddress}  |  RayID: ${ev.rayId}  |  Risk: ${ev.riskScore}',
                      style: AppTheme.mono(size: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Text(
                '${ev.timestamp.hour.toString().padLeft(2, '0')}:${ev.timestamp.minute.toString().padLeft(2, '0')}:${ev.timestamp.second.toString().padLeft(2, '0')}',
                style: AppTheme.mono(size: 11, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Account Security & MFA Tab
  // ---------------------------------------------------------------------------
  Widget _buildAccountSecurityTab(AuthProvider auth) {
    final user = auth.currentUser;
    final isMfaOn = auth.isMfaActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TWO-FACTOR AUTHENTICATION (TOTP)', style: AppTheme.mono(size: 14, color: Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MFA Status: ${isMfaOn ? "ACTIVE & ENFORCED" : "NOT ENROLLED"}',
                      style: AppTheme.mono(
                        size: 13,
                        color: isMfaOn ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        weight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMfaOn ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: () async {
                        if (isMfaOn) {
                          await auth.disableMfa();
                          setState(() => _showMfaSetup = false);
                        } else {
                          final secret = await auth.initiateMfaEnrollment();
                          setState(() {
                            _generatedMfaSecret = secret;
                            _showMfaSetup = true;
                          });
                        }
                      },
                      child: Text(
                        isMfaOn ? 'DISABLE 2FA' : 'ENROLL AUTHENTICATOR APP',
                        style: AppTheme.mono(size: 12, color: Colors.white, weight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (_showMfaSetup && !isMfaOn) ...[
                  const Divider(color: Color(0xFF1E293B), height: 30),
                  Text('1. ADD SECRET KEY TO AUTHENTICATOR APP:', style: AppTheme.mono(size: 12, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 8),
                  SelectableText(
                    _generatedMfaSecret ?? '',
                    style: AppTheme.mono(size: 15, color: const Color(0xFF38BDF8), weight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('2. ENTER 6-DIGIT CODE TO ACTIVATE:', style: AppTheme.mono(size: 12, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 180,
                        child: TextField(
                          controller: _totpVerifyController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: AppTheme.mono(size: 16, color: Colors.white),
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: '123456',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () async {
                          final success = await auth.confirmAndActivateMfa(_totpVerifyController.text);
                          if (success && mounted) {
                            setState(() => _showMfaSetup = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('2FA successfully verified and activated!')),
                            );
                          }
                        },
                        child: Text('VERIFY & ACTIVATE', style: AppTheme.mono(size: 12, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),

          Text('SINGLE-USE RECOVERY CODES', style: AppTheme.mono(size: 14, color: Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: auth.recoveryCodes.isEmpty
                ? Text('No recovery codes generated. Enroll 2FA to generate codes.', style: AppTheme.mono(size: 12, color: const Color(0xFF64748B)))
                : Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      for (final code in auth.recoveryCodes)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF334155)),
                            color: const Color(0xFF0F172A),
                          ),
                          child: SelectableText(code, style: AppTheme.mono(size: 13, color: const Color(0xFFE2E8F0))),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 30),

          Text('ACTIVE SESSIONS & REVOCATION', style: AppTheme.mono(size: 14, color: Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Device: Primary Workstation', style: AppTheme.mono(size: 13, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Authenticated as: ${user?.email ?? "Guest"}', style: AppTheme.mono(size: 12, color: const Color(0xFF94A3B8))),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: () => auth.logout(),
                  child: Text('TERMINATE ALL SESSIONS', style: AppTheme.mono(size: 11, weight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. IP Intelligence Tab
  // ---------------------------------------------------------------------------
  Widget _buildIpIntelligenceTab(List<SecurityEvent> events) {
    // Distinct IP aggregation
    final Map<String, int> ipCounts = {};
    for (final e in events) {
      ipCounts[e.ipAddress] = (ipCounts[e.ipAddress] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OBSERVED IP ACTIVITY & RISK INDICATORS', style: AppTheme.mono(size: 14, color: Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: ipCounts.isEmpty
                ? Text('No external IP traffic recorded.', style: AppTheme.mono(size: 12, color: const Color(0xFF64748B)))
                : Column(
                    children: [
                      for (final entry in ipCounts.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.language_rounded, color: Color(0xFF38BDF8), size: 18),
                                  const SizedBox(width: 10),
                                  Text(entry.key, style: AppTheme.mono(size: 13, color: Colors.white)),
                                ],
                              ),
                              Text('${entry.value} Events Recorded', style: AppTheme.mono(size: 12, color: const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Security Analytics Tab
  // ---------------------------------------------------------------------------
  Widget _buildSecurityAnalyticsTab(Map<String, dynamic> metrics) {
    final total = (metrics['totalEvents'] as int?) ?? 1;
    final failed = (metrics['loginsFailed'] as int?) ?? 0;
    final failureRate = total > 0 ? (failed / total * 100).toStringAsFixed(1) : '0.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THREAT ANALYTICS & EDGE MITIGATION METRICS', style: AppTheme.mono(size: 14, color: Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Authentication Failure Ratio: $failureRate%', style: AppTheme.mono(size: 13, color: Colors.white)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (double.tryParse(failureRate) ?? 0.0) / 100.0,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF87171)),
                  minHeight: 8,
                ),
                const SizedBox(height: 20),
                Text('Edge WAF Challenge Response Rate: 100% enforce', style: AppTheme.mono(size: 13, color: Colors.white)),
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Color(0xFF1E293B),
                  valueColor: AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                  minHeight: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Administration Tab
  // ---------------------------------------------------------------------------
  Widget _buildAdministrationTab(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INCIDENT RESPONSE & LOCKOUT OVERRIDE', style: AppTheme.mono(size: 14, color: Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UNLOCK RESTRICTED ACCOUNT', style: AppTheme.mono(size: 12, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _unlockAccountController,
                        style: AppTheme.mono(size: 13, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'user@broml.ai',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: () {
                        final email = _unlockAccountController.text.trim();
                        if (email.isNotEmpty) {
                          RateLimitEngine.unlockAccount(email);
                          SecurityAuditLogger.logEvent(
                            type: SecurityEventType.adminAction,
                            severity: SecuritySeverity.info,
                            accountIdentifier: email,
                            ipAddress: '127.0.0.1',
                            summary: 'Administrative unlock executed for account $email',
                          );
                          _unlockAccountController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Account restriction cleared for $email')),
                          );
                        }
                      },
                      child: Text('CLEAR LOCKOUT', style: AppTheme.mono(size: 11, weight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper UI Builders
  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTheme.mono(size: 10, color: const Color(0xFF94A3B8), weight: FontWeight.w600)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTheme.mono(size: 26, color: Colors.white, weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tierCard(String title, String subtitle, String price, List<String> features, {bool isFeatured = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isFeatured ? const Color(0xFF132238) : const Color(0xFF111827),
        border: Border.all(color: isFeatured ? const Color(0xFF38BDF8) : const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.mono(size: 12, color: isFeatured ? const Color(0xFF38BDF8) : Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.mono(size: 11, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 14),
          Text(price, style: AppTheme.mono(size: 22, color: Colors.white, weight: FontWeight.bold)),
          const Divider(color: Color(0xFF1E293B), height: 24),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✓ ', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                  Expanded(child: Text(f, style: AppTheme.mono(size: 11, color: const Color(0xFFE2E8F0)))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckmarkRow extends StatelessWidget {
  final String text;
  const _CheckmarkRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✓ ', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: AppTheme.mono(size: 12, color: const Color(0xFFE2E8F0)))),
        ],
      ),
    );
  }
}

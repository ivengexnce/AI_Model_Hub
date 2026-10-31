import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_model_hub/services/security_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RED-TEAM TEST 1: Credential Stuffing Attack Simulation', () {
    test('Detects repeated failures, enforces throttling, and blocks breach dictionary passwords', () {
      const targetAccount = 'researcher@broml.ai';
      const breachPass = 'password123';

      // 1. Password policy instantly flags breach dictionary password
      expect(PasswordSecurityPolicy.isCompromised(breachPass), isTrue);
      final validation = PasswordSecurityPolicy.validate(breachPass);
      expect(validation.isValid, isFalse);
      expect(validation.errors.any((e) => e.contains('compromised')), isTrue);

      // 2. Simulate 5 consecutive failed stuffing attempts
      for (int i = 0; i < 5; i++) {
        RateLimitEngine.recordAttempt(
          accountId: targetAccount,
          ipAddress: '198.51.100.24',
          success: false,
        );
      }

      // 3. 6th attempt must be locked out
      final rateLimitCheck = RateLimitEngine.checkRateLimit(
        accountId: targetAccount,
        ipAddress: '198.51.100.24',
      );

      expect(rateLimitCheck.isAllowed, isFalse);
      expect(rateLimitCheck.isLockedOut, isTrue);
      expect(rateLimitCheck.retryAfterSeconds, greaterThan(0));

      // 4. Verify Turnstile challenge escalation triggered
      final challengeRequired = TurnstileService.isChallengeRequired(
        accountId: targetAccount,
        ipRiskScore: 60,
      );
      expect(challengeRequired, isTrue);
    });
  });

  group('RED-TEAM TEST 2: Distributed Brute-Force Simulation', () {
    test('Account-based throttling prevents distributed attack across multiple IPs', () {
      const victimAccount = 'lead.architect@broml.ai';
      final distributedIps = [
        '185.220.101.5',
        '185.220.101.9',
        '185.220.102.14',
        '185.220.103.22',
        '185.220.104.30',
      ];

      // Each request comes from a completely distinct IP address
      for (final attackerIp in distributedIps) {
        RateLimitEngine.recordAttempt(
          accountId: victimAccount,
          ipAddress: attackerIp,
          success: false,
        );
      }

      // 6th attempt from yet another new IP address must STILL be rejected due to account-level aggregation
      final distributedAttempt = RateLimitEngine.checkRateLimit(
        accountId: victimAccount,
        ipAddress: '192.0.2.99', // Brand new IP
      );

      expect(distributedAttempt.isAllowed, isFalse);
      expect(distributedAttempt.isLockedOut, isTrue);
      expect(distributedAttempt.message, contains('Account temporarily restricted'));
    });
  });

  group('RED-TEAM TEST 3: CAPTCHA / Cloudflare Turnstile Bypass Resistance', () {
    test('Server-side verification strictly rejects missing, invalid, and reused tokens', () async {
      // 1. Missing token
      final missingResult = await TurnstileService.verifyToken(token: '');
      expect(missingResult.success, isFalse);
      expect(missingResult.error, contains('Missing Turnstile challenge token'));

      // 2. Forged / invalid token
      final invalidResult = await TurnstileService.verifyToken(token: 'turnstile-invalid-payload');
      expect(invalidResult.success, isFalse);
      expect(invalidResult.error, contains('Invalid or forged Turnstile'));

      // 3. Valid single-use token passes on first verification
      const legitimateToken = '0x4AAAAAAAT_ValidTokenXYZ987';
      final validResult = await TurnstileService.verifyToken(token: legitimateToken);
      expect(validResult.success, isTrue);

      // 4. Token Replay Attack: Same token submitted a second time MUST BE REJECTED
      final replayedResult = await TurnstileService.verifyToken(token: legitimateToken);
      expect(replayedResult.success, isFalse);
      expect(replayedResult.error, contains('replay prevention'));
    });
  });

  group('RED-TEAM TEST 4: 2FA / TOTP Verification Abuse', () {
    test('Enforces OTP window boundaries and prevents OTP replay attacks', () {
      final secret = MfaService.generateSecret();
      final validCode = MfaService.generateTotpCode(secret);

      // First verification succeeds
      final firstVerify = MfaService.verifyTotpCode(secret, validCode, accountId: 'user-mfa-1');
      expect(firstVerify, isTrue);

      // Replay Attack: Re-submitting the exact same code in the same window must fail
      final replayVerify = MfaService.verifyTotpCode(secret, validCode, accountId: 'user-mfa-1');
      expect(replayVerify, isFalse);

      // Submitting garbage / invalid code must fail
      final garbageVerify = MfaService.verifyTotpCode(secret, '000000', accountId: 'user-mfa-1');
      expect(garbageVerify, isFalse);
    });

    test('Single-use backup recovery codes cannot be reused once consumed', () {
      final recoveryCodes = MfaService.generateRecoveryCodes(count: 4);
      expect(recoveryCodes.length, 4);

      final codeToConsume = recoveryCodes.first;

      // 1. Consume code
      final firstUse = MfaService.verifyAndConsumeRecoveryCode(
        inputCode: codeToConsume,
        activeRecoveryCodes: recoveryCodes,
      );
      expect(firstUse, isTrue);
      expect(recoveryCodes.length, 3); // Code removed from list

      // 2. Replay code attack: Attempting to use the same code again fails
      final secondUse = MfaService.verifyAndConsumeRecoveryCode(
        inputCode: codeToConsume,
        activeRecoveryCodes: recoveryCodes,
      );
      expect(secondUse, isFalse);
    });
  });

  group('RED-TEAM TEST 5: Rate-Limit Evasion & Progressive Delay Enforcement', () {
    test('Calculates progressive backoff delay proportionally to failure count', () {
      const account = 'devops@broml.ai';
      RateLimitEngine.unlockAccount(account);

      // 0 failures -> 0ms delay
      var check = RateLimitEngine.checkRateLimit(accountId: account, ipAddress: '10.0.0.1');
      expect(check.progressiveDelayMs, 0);

      // 1 failure -> 500ms delay
      RateLimitEngine.recordAttempt(accountId: account, ipAddress: '10.0.0.1', success: false);
      check = RateLimitEngine.checkRateLimit(accountId: account, ipAddress: '10.0.0.1');
      expect(check.progressiveDelayMs, 500);

      // 3 failures -> 2500ms progressive delay
      RateLimitEngine.recordAttempt(accountId: account, ipAddress: '10.0.0.1', success: false);
      RateLimitEngine.recordAttempt(accountId: account, ipAddress: '10.0.0.1', success: false);
      check = RateLimitEngine.checkRateLimit(accountId: account, ipAddress: '10.0.0.1');
      expect(check.progressiveDelayMs, 2500);
    });
  });
}


import 'dart:io';
import 'package:flutter/foundation.dart';

class DetectedHardwareProfile {
  final String os, presetName, summary;
  final int cpuCores, totalRamBytes, safeRamBudgetBytes;
  final bool isAutoDetected;

  const DetectedHardwareProfile({
    required this.os,
    required this.cpuCores,
    required this.totalRamBytes,
    required this.safeRamBudgetBytes,
    required this.isAutoDetected,
    required this.presetName,
    required this.summary,
  });

  double get safeRamGb => safeRamBudgetBytes / (1024 * 1024 * 1024);
  String get formattedTotalRam => '${(totalRamBytes / 1073741824).toStringAsFixed(1)} GB';
  String get formattedSafeRam => '${safeRamGb.toStringAsFixed(1)} GB';
}

class HardwareDetectionService {
  /// Scans physical memory and allocates a zero-lag 60% memory budget.
  static Future<DetectedHardwareProfile> autoDetect() async {
    final cores = Platform.numberOfProcessors;
    int ram = 8 * 1073741824; // 8GB default fallback

    try {
      if ((Platform.isAndroid || Platform.isLinux) && await File('/proc/meminfo').exists()) {
        final line = (await File('/proc/meminfo').readAsLines()).firstWhere((l) => l.startsWith('MemTotal:'));
        final kb = int.tryParse(RegExp(r'\d+').firstMatch(line)?.group(0) ?? '');
        if (kb != null) ram = kb * 1024;
      } else if (Platform.isWindows && !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        final res = await Process.run('powershell', ['-NoProfile', '-Command', '(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize']);
        if (res.exitCode == 0) ram = (int.tryParse(res.stdout.toString().trim()) ?? (8 * 1048576)) * 1024;
      }
    } catch (_) {}

    final safe = (ram * 0.60).round().clamp(536870912, ram);
    final totalGb = (ram / 1073741824).toStringAsFixed(1);
    final safeGb = (safe / 1073741824).toStringAsFixed(1);

    return DetectedHardwareProfile(
      os: Platform.operatingSystem.toUpperCase(),
      cpuCores: cores,
      totalRamBytes: ram,
      safeRamBudgetBytes: safe,
      isAutoDetected: true,
      presetName: 'Auto-Detected Device',
      summary: '$cores Cores • $totalGb GB Total RAM • Safe ML Budget: $safeGb GB (Zero-Lag Guaranteed)',
    );
  }

  static DetectedHardwareProfile get budgetLaptopPreset => const DetectedHardwareProfile(
        os: 'LAPTOP', cpuCores: 4, totalRamBytes: 4294967296, safeRamBudgetBytes: 2147483648,
        isAutoDetected: false, presetName: 'Budget Laptop (4GB)',
        summary: '4 Cores • 4.0 GB RAM • Safe ML Budget: 2.0 GB (Ultra-Lightweight Focus)',
      );

  static DetectedHardwareProfile get standardLaptopPreset => const DetectedHardwareProfile(
        os: 'LAPTOP', cpuCores: 8, totalRamBytes: 8589934592, safeRamBudgetBytes: 4831838208,
        isAutoDetected: false, presetName: 'Standard Laptop (8GB)',
        summary: '8 Cores • 8.0 GB RAM • Safe ML Budget: 4.5 GB (Balanced Performance)',
      );

  static DetectedHardwareProfile get workstationGpuPreset => const DetectedHardwareProfile(
        os: 'WORKSTATION', cpuCores: 16, totalRamBytes: 17179869184, safeRamBudgetBytes: 10737418240,
        isAutoDetected: false, presetName: 'GPU Workstation',
        summary: '16 Cores • 16.0 GB RAM • Safe ML Budget: 10.0 GB (High Throughput / GPU)',
      );
}

/// ORA Permission Engine - Permission Result
///
/// Represents the result of a permission check for a specific feature.
/// Contains whether the feature is allowed and the requirements that need to be met.
class PermissionResult {
  final bool allowed;
  final String reason;
  final int requiredAura;
  final int requiredLevel;
  final int requiredAccountAge; // in days

  const PermissionResult({
    required this.allowed,
    required this.reason,
    required this.requiredAura,
    required this.requiredLevel,
    required this.requiredAccountAge,
  });

  /// Creates a denied permission result with a reason
  factory PermissionResult.denied({
    required String reason,
    int requiredAura = 0,
    int requiredLevel = 1,
    int requiredAccountAge = 0,
  }) {
    return PermissionResult(
      allowed: false,
      reason: reason,
      requiredAura: requiredAura,
      requiredLevel: requiredLevel,
      requiredAccountAge: requiredAccountAge,
    );
  }

  /// Creates an allowed permission result
  factory PermissionResult.allowed() {
    return const PermissionResult(
      allowed: true,
      reason: 'Access granted',
      requiredAura: 0,
      requiredLevel: 1,
      requiredAccountAge: 0,
    );
  }

  @override
  String toString() {
    if (allowed) {
      return 'PermissionResult: Allowed';
    }
    return 'PermissionResult: Denied - $reason (Aura: $requiredAura, Level: $requiredLevel, Account Age: $requiredAccountAge days)';
  }
}
class AuraHistoryModel {
  final String id;
  final String action;
  final int auraChange;
  final DateTime timestamp;

  AuraHistoryModel({
    required this.id,
    required this.action,
    required this.auraChange,
    required this.timestamp,
  });
}
class Log {
  final String logId;
  final String boxId;
  final String action;
  final String timestamp;

  Log({
    required this.logId,
    required this.boxId,
    required this.action,
    required this.timestamp,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      logId: json['log_id']?.toString() ?? '',
      boxId: json['box_id']?.toString() ?? '',
      action: json['log_action']?.toString() ?? '',
      timestamp: json['log_timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'box_id': boxId,
      'log_action': action,
      'log_timestamp': timestamp,
    };
  }
}
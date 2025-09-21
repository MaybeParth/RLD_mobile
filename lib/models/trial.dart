class Trial {
  final String id;
  final DateTime timestamp;
  final double? initialZ;
  final double? finalZ;
  final double? dropAngle;
  final double? dropTimeMs;
  final double? motorVelocity;
  final double? peakDropAngle;
  final bool isKept; // Whether this trial was kept or discarded
  final String? notes;
  final String? discardReason; // For discarded trials
  final Duration? dropTime; // Drop time as Duration

  const Trial({
    required this.id,
    required this.timestamp,
    this.initialZ,
    this.finalZ,
    this.dropAngle,
    this.dropTimeMs,
    this.motorVelocity,
    this.peakDropAngle,
    this.isKept = true,
    this.notes,
    this.discardReason,
    this.dropTime,
  });

  Trial copyWith({
    String? id,
    DateTime? timestamp,
    double? initialZ,
    double? finalZ,
    double? dropAngle,
    double? dropTimeMs,
    double? motorVelocity,
    double? peakDropAngle,
    bool? isKept,
    String? notes,
    String? discardReason,
    Duration? dropTime,
  }) {
    return Trial(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      initialZ: initialZ ?? this.initialZ,
      finalZ: finalZ ?? this.finalZ,
      dropAngle: dropAngle ?? this.dropAngle,
      dropTimeMs: dropTimeMs ?? this.dropTimeMs,
      motorVelocity: motorVelocity ?? this.motorVelocity,
      peakDropAngle: peakDropAngle ?? this.peakDropAngle,
      isKept: isKept ?? this.isKept,
      notes: notes ?? this.notes,
      discardReason: discardReason ?? this.discardReason,
      dropTime: dropTime ?? this.dropTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'initialZ': initialZ,
      'finalZ': finalZ,
      'dropAngle': dropAngle,
      'dropTimeMs': dropTimeMs,
      'motorVelocity': motorVelocity,
      'peakDropAngle': peakDropAngle,
      'isKept': isKept ? 1 : 0,
      'notes': notes,
      'discardReason': discardReason,
      'dropTime': dropTime?.inMilliseconds.toDouble(),
    };
  }

  factory Trial.fromMap(Map<String, dynamic> map) {
    double? _d(dynamic v) => (v == null) ? null : (v as num).toDouble();
    return Trial(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      initialZ: _d(map['initialZ']),
      finalZ: _d(map['finalZ']),
      dropAngle: _d(map['dropAngle']),
      dropTimeMs: _d(map['dropTimeMs']),
      motorVelocity: _d(map['motorVelocity']),
      peakDropAngle: _d(map['peakDropAngle']),
      isKept: (map['isKept'] as int) == 1,
      notes: map['notes'] as String?,
      discardReason: map['discardReason'] as String?,
      dropTime: map['dropTimeMs'] != null ? Duration(milliseconds: (map['dropTimeMs'] as num).toInt()) : null,
    );
  }

  // Helper methods
  bool get hasValidResults => dropAngle != null && dropTimeMs != null;
  String get formattedTimestamp => '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  String get summaryText => 'Trial ${id}: ${dropAngle?.toStringAsFixed(1) ?? 'N/A'}° drop, ${dropTimeMs?.toStringAsFixed(0) ?? 'N/A'}ms';
}

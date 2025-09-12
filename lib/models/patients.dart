class Patient {
  final String id;
  final String name;
  final String age;
  final String gender;
  final String condition;

  // Test results
  final double? initialZ;
  final double? finalZ;
  final double? dropAngle;
  final double? dropTimeMs;
  final double? motorVelocity;

  // Persistent calibration
  final double? calZeroOffsetDeg; // display offset so extended ≈ 180
  final double? calRefX, calRefY, calRefZ; // reference gravity (unit) at extension
  final double? calUX, calUY, calUZ;       // sagittal plane U
  final double? calVX, calVY, calVZ;       // sagittal plane V
  final String? calibratedAtIso;
  final int? dropsSinceCal;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.condition,
    this.initialZ,
    this.finalZ,
    this.dropAngle,
    this.dropTimeMs,
    this.motorVelocity,
    this.calZeroOffsetDeg,
    this.calRefX, this.calRefY, this.calRefZ,
    this.calUX, this.calUY, this.calUZ,
    this.calVX, this.calVY, this.calVZ,
    this.calibratedAtIso,
    this.dropsSinceCal,
  });

  Patient copyWith({
    String? id,
    String? name,
    String? age,
    String? gender,
    String? condition,
    double? initialZ,
    double? finalZ,
    double? dropAngle,
    double? dropTimeMs,
    double? motorVelocity,
    double? calZeroOffsetDeg,
    double? calRefX, double? calRefY, double? calRefZ,
    double? calUX, double? calUY, double? calUZ,
    double? calVX, double? calVY, double? calVZ,
    String? calibratedAtIso,
    int? dropsSinceCal,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      condition: condition ?? this.condition,
      initialZ: initialZ ?? this.initialZ,
      finalZ: finalZ ?? this.finalZ,
      dropAngle: dropAngle ?? this.dropAngle,
      dropTimeMs: dropTimeMs ?? this.dropTimeMs,
      motorVelocity: motorVelocity ?? this.motorVelocity,
      calZeroOffsetDeg: calZeroOffsetDeg ?? this.calZeroOffsetDeg,
      calRefX: calRefX ?? this.calRefX, calRefY: calRefY ?? this.calRefY, calRefZ: calRefZ ?? this.calRefZ,
      calUX: calUX ?? this.calUX, calUY: calUY ?? this.calUY, calUZ: calUZ ?? this.calUZ,
      calVX: calVX ?? this.calVX, calVY: calVY ?? this.calVY, calVZ: calVZ ?? this.calVZ,
      calibratedAtIso: calibratedAtIso ?? this.calibratedAtIso,
      dropsSinceCal: dropsSinceCal ?? this.dropsSinceCal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'condition': condition,
      'initialZ': initialZ,
      'finalZ': finalZ,
      'dropAngle': dropAngle,
      'dropTime': dropTimeMs,
      'motorVelocity': motorVelocity,
      'calZeroOffsetDeg': calZeroOffsetDeg,
      'calRefX': calRefX, 'calRefY': calRefY, 'calRefZ': calRefZ,
      'calUX': calUX, 'calUY': calUY, 'calUZ': calUZ,
      'calVX': calVX, 'calVY': calVY, 'calVZ': calVZ,
      'calibratedAtIso': calibratedAtIso,
      'dropsSinceCal': dropsSinceCal,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    double? _d(dynamic v) => (v == null) ? null : (v as num).toDouble();
    return Patient(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as String,
      gender: map['gender'] as String,
      condition: map['condition'] as String,
      initialZ: _d(map['initialZ']),
      finalZ: _d(map['finalZ']),
      dropAngle: _d(map['dropAngle']),
      dropTimeMs: _d(map['dropTime']),
      motorVelocity: _d(map['motorVelocity']),
      calZeroOffsetDeg: _d(map['calZeroOffsetDeg']),
      calRefX: _d(map['calRefX']), calRefY: _d(map['calRefY']), calRefZ: _d(map['calRefZ']),
      calUX: _d(map['calUX']), calUY: _d(map['calUY']), calUZ: _d(map['calUZ']),
      calVX: _d(map['calVX']), calVY: _d(map['calVY']), calVZ: _d(map['calVZ']),
      calibratedAtIso: map['calibratedAtIso'] as String?,
      dropsSinceCal: (map['dropsSinceCal'] as int?) ?? 0,
    );
  }
}

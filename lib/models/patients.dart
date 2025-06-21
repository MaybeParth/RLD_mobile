class Patient {
  final String id;
  final String name;
  final String age;
  final String gender;
  final String condition;
  final double? initialZ;
  final double? finalZ;
  final double? dropAngle;
  final double? dropTimeMs;
  final double? motorVelocity;

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
  });

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
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as String,
      gender: map['gender'] as String,
      condition: map['condition'] as String,
      initialZ: map['initialZ'] != null ? map['initialZ'] as double : null,
      finalZ: map['finalZ'] != null ? map['finalZ'] as double : null,
      dropAngle: map['dropAngle'] != null ? map['dropAngle'] as double : null,
      dropTimeMs: map['dropTime'] != null ? map['dropTime'] as double : null,
      motorVelocity: map['motorVelocity'] != null ? map['motorVelocity'] as double : null,
    );
  }
}

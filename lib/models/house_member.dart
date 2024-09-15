class HouseMember {
  final int id;
  final int houseId;
  final String userName;
  final String role;

  HouseMember({
    required this.id,
    required this.houseId,
    required this.userName,
    required this.role,
  });

  factory HouseMember.fromJson(Map<String, dynamic> json) {
    return HouseMember(
      id: json['id'],
      houseId: json['house_id'],
      userName: json['user_name'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'house_id': houseId,
      'user_name': userName,
      'role': role,
    };
  }
}

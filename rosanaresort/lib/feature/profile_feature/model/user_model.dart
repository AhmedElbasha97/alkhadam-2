

class UnitDetailsModel {
  final String unId;
  final String? ownerName;
  final String? phone;
  final String? email;
  final String? unitNumber;
  final String? buildingName;
  final String? avatarUrl;

  const UnitDetailsModel({
    required this.unId,
    this.ownerName,
    this.phone,
    this.email,
    this.unitNumber,
    this.buildingName,
    this.avatarUrl,
  });

  String get displayName =>
      (ownerName != null && ownerName!.trim().isNotEmpty)
          ? ownerName!.trim()
          : 'Rosana Resort Resident';

  factory UnitDetailsModel.fromJson(Map<String, dynamic> json) {
    // Tolerates either a flat object or one nested under "data"/"unit".
    final root = (json['data'] ?? json['unit'] ?? json) as Map<String, dynamic>;

    return UnitDetailsModel(
      unId: '${root['un_id'] ?? root['id'] ?? ''}',
      ownerName: root['name'] ?? root['owner_name'] ?? root['un_name'],
      phone: root['phone'] ?? root['un_phone'],
      email: root['email'],
      unitNumber: root['unit_number'] ?? root['un_unit_no'],
      buildingName: root['building_name'] ?? root['un_building'],
      avatarUrl: root['avatar'] ?? root['image'],
    );
  }
}
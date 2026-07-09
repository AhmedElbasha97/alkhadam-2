class PassModel {
  final String id;
  final String name;
  final String qrcode;
  final String caption;
  final String dateFrom;
  final String dateTo;
  final String img;
  final bool isActive;

  const PassModel({
    required this.id,
    required this.name,
    required this.qrcode,
    required this.caption,
    required this.dateFrom,
    required this.dateTo,
    required this.img,
    required this.isActive,
  });

  factory PassModel.fromJson(Map<String, dynamic> json) {
    return PassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      qrcode: json['qrcode'] as String,
      caption: json['caption'] as String,
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      img: json['img'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qrcode': qrcode,
        'caption': caption,
        'date_from': dateFrom,
        'date_to': dateTo,
        'img': img,
        'is_active': isActive,
      };
}

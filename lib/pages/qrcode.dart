class QrCode {
  final int qrCodeId;
  final bool status;
  final String exchangeDateTime;
  final String startDateTime;
  final String endDateTime;

  QrCode({
    required this.qrCodeId,
    required this.status,
    required this.exchangeDateTime,
    required this.startDateTime,
    required this.endDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'qrCodeId': qrCodeId,
      'status': status,
      'exchangeDateTime': exchangeDateTime,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
    };
  }

  factory QrCode.fromMap(Map<String, dynamic> map) {
    return QrCode(
      qrCodeId: map['qrCodeId'],
      status: map['status'],
      exchangeDateTime: map['exchangeDateTime'],
      startDateTime: map['startDateTime'],
      endDateTime: map['endDateTime'],
    );
  }
}

class Product {
  final String docId;
  final String productName;
  final String productNameEng;
  final String alcohol;
  final int price;
  final String description;
  final String descriptionEng;
  final String fineTuningName;
  final String groupId;
  final String imgPath;
  final int order;
  final bool recommended;
  final bool active;
  final String createdDateTime;

  Product({
    required this.docId,
    required this.productName,
    required this.productNameEng,
    required this.alcohol,
    required this.price,
    required this.description,
    required this.descriptionEng,
    required this.fineTuningName,
    required this.groupId,
    required this.imgPath,
    required this.order,
    required this.recommended,
    required this.active,
    required this.createdDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'productName': productName,
      'productNameEng': productNameEng,
      'alcohol': alcohol,
      'price': price,
      'description': description,
      'descriptionEng': descriptionEng,
      'fineTuningName': fineTuningName,
      'groupId': groupId,
      'imgPath': imgPath,
      'order': order,
      'recommended': recommended,
      'active': active,
      'createdDateTime': createdDateTime,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      docId: map['docId'],
      productName: map['productName'],
      productNameEng: map['productNameEng'],
      alcohol: map['alcohol'],
      price: map['price'],
      description: map['description'],
      descriptionEng: map['descriptionEng'],
      fineTuningName: map['fineTuningName'],
      groupId: map['groupId'],
      imgPath: map['imgPath'],
      order: map['order'],
      recommended: map['recommended'],
      active: map['active'],
      createdDateTime: map['createdDateTime'],
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'constant.dart';
import 'database_helper.dart';

class ProductsManage extends StatefulWidget {
  const ProductsManage({super.key});

  @override
  State<ProductsManage> createState() => _ProductsManageState();
}

class _ProductsManageState extends State<ProductsManage> {
  late Future<List<Map<String, dynamic>>> _allProducts;

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  void _loadAllProducts() {
    if (mounted) {
      setState(() {
        _allProducts = DatabaseHelper().getAllProducts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: healDarkGrey,
          title: const Text('Members Manage',
              style: TextStyle(
                  color: colorWhite80,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          leading: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 2.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Image.asset(
                'lib/assets/images/Back.jpg',
                width: 45,
                height: 45,
              ),
            ),
          ),
          toolbarHeight: 80,
        ),
        body: Container(
          width: double.infinity,
          height: 600,
          decoration: const BoxDecoration(
            color: colorTransparent,
          ),
          child: SingleChildScrollView(
            child: Center(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _allProducts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products found'));
                  } else {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          const DataColumn(
                            label: Text(
                              'ProductId',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'ProductName',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Price',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'imgName',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'FormulaString',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Created Date',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          DataColumn(
                            label: IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return addProduct();
                                      });
                                },
                                icon: const Icon(Icons.add_circle_outline,
                                    color: healDarkGrey, size: 40)),
                          ),
                        ],
                        rows: snapshot.data!.map((product) {
                          return DataRow(cells: [
                            DataCell(Text(
                              product['docId'].toString(),
                              style: const TextStyle(
                                  color: healDarkGrey, fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                product['productName'],
                                style: const TextStyle(
                                    color: healDarkGrey, fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              product['price'].toString(),
                              style: const TextStyle(
                                  color: healDarkGrey, fontSize: 18),
                            )),
                            DataCell(Text(
                              product['imgPath'],
                              style: const TextStyle(
                                  color: healDarkGrey, fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                product['formulaString'],
                                style: const TextStyle(
                                    color: healDarkGrey, fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              product['createdDateTime']
                                  .toString()
                                  .substring(0, 19),
                              style: const TextStyle(
                                  color: healDarkGrey, fontSize: 18),
                            )),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: healDarkGrey),
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (builder) =>
                                              editProduct(product));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: healDarkGrey),
                                    onPressed: () {
                                      showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Delete Product',
                                                style: TextStyle(
                                                    color: healDarkGrey,
                                                    fontSize: 24)),
                                            content: const Text('Are you sure?',
                                                style: TextStyle(
                                                    color: healDarkGrey,
                                                    fontSize: 22)),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('Cancel',
                                                    style: TextStyle(
                                                        color: healDarkGrey,
                                                        fontSize: 20)),
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                              ),
                                              TextButton(
                                                child: const Text('Confirm',
                                                    style: TextStyle(
                                                        color: healDarkGrey,
                                                        fontSize: 20)),
                                                onPressed: () => {
                                                  DatabaseHelper().deleteMember(
                                                      product['userId']),
                                                  Navigator.pop(context, true),
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) {
                                        if (value != null && value) {
                                          _loadAllProducts(); // 重新加載產品數據
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget addProduct() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController imgPathController = TextEditingController();
    final TextEditingController formulaStringController =
        TextEditingController();
    return Dialog(
      child: SizedBox(
        width: 400,
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Input the Name',
                        hintStyle:
                            TextStyle(color: healLightGrey, fontSize: 22),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: healDarkGrey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        hintText: 'Input the Price',
                        hintStyle:
                            TextStyle(color: healLightGrey, fontSize: 22),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: healDarkGrey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: imgPathController,
                      decoration: const InputDecoration(
                        hintText:
                            'Input Image Name (With Extension .jpg/.png/.gif)',
                        hintStyle:
                            TextStyle(color: healLightGrey, fontSize: 22),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: healDarkGrey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 80,
                    child: TextField(
                      controller: formulaStringController,
                      decoration: const InputDecoration(
                        hintText: 'Input the Formula String(ex. @g1=10&g2=15)',
                        hintStyle:
                            TextStyle(color: healLightGrey, fontSize: 22),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: healDarkGrey),
                        ),
                      ),
                      style: const TextStyle(fontSize: 26, color: healDarkGrey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 60,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(200, 60),
                        foregroundColor: healDarkGrey,
                        backgroundColor: colorWhite80,
                        side: const BorderSide(
                          color: healDarkGrey,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            priceController.text.isEmpty ||
                            imgPathController.text.isEmpty ||
                            formulaStringController.text.isEmpty) {
                          //取出 最近的 userId 如 U00001 然後 + 1 使其為 U00002
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: const Text(
                                  'All fields are required',
                                  style: TextStyle(fontSize: 24.0),
                                ),
                              ),
                              behavior:
                                  SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10.0), // 可選：設置圓角
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          final Map<String, dynamic> product = {
                            'productName': nameController.text,
                            'price': priceController.text,
                            'imgPath': imgPathController.text,
                            'formulaString': formulaStringController.text
                          };
                          await DatabaseHelper().insertProduct(product);
                          _loadAllProducts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: const Text(
                                  'Product Added Successfully',
                                  style: TextStyle(fontSize: 24.0),
                                ),
                              ),
                              behavior:
                                  SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10.0), // 可選：設置圓角
                              ),
                              backgroundColor: healDarkGrey,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Add Product',
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget editProduct(Map<String, dynamic> product) {
    TextEditingController nameEditController =
        TextEditingController(text: product['productName']);
    TextEditingController priceEditController =
        TextEditingController(text: product['price'].toString());
    TextEditingController imgPathEditController =
        TextEditingController(text: product['imgPath']);
    TextEditingController formulaStringEditController =
        TextEditingController(text: product['formulaString']);

    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 350,
                  height: 80,
                  child: TextField(
                    controller: nameEditController,
                    decoration: const InputDecoration(
                      labelText: 'Input the Name',
                      labelStyle: TextStyle(color: healDarkGrey, fontSize: 18),
                    ),
                    style: const TextStyle(color: healDarkGrey, fontSize: 22),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 80,
                  child: TextField(
                    controller: priceEditController,
                    decoration: const InputDecoration(
                      labelText: 'Input the Price',
                      labelStyle: TextStyle(color: healDarkGrey, fontSize: 18),
                    ),
                    style: const TextStyle(color: healDarkGrey, fontSize: 22),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 80,
                  child: TextField(
                    controller: imgPathEditController,
                    decoration: const InputDecoration(
                      labelText:
                          'Input the Image Name (With Extension .jpg/.png/.gif)',
                      labelStyle: TextStyle(color: healDarkGrey, fontSize: 18),
                    ),
                    style: const TextStyle(color: healDarkGrey, fontSize: 22),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 80,
                  child: TextField(
                    controller: formulaStringEditController,
                    decoration: const InputDecoration(
                      labelText: 'Input the Formula String (ex. @g1=10&g2=15)',
                      labelStyle: TextStyle(color: healDarkGrey, fontSize: 18),
                    ),
                    style: const TextStyle(color: healDarkGrey, fontSize: 22),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  height: 60,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(200, 60),
                      foregroundColor: healDarkGrey,
                      backgroundColor: colorWhite80,
                      side: const BorderSide(
                        color: healDarkGrey,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      try {
                        DatabaseHelper().updateMember({
                          'docId': product['docId'],
                          'productName': nameEditController.text,
                          'pricr': priceEditController.text,
                          'imgPath': imgPathEditController.text,
                          'formulaString': formulaStringEditController.text,
                        }).then((value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: const Text(
                                  'Product Edited Successfully',
                                  style: TextStyle(fontSize: 24.0),
                                ),
                              ),
                              behavior:
                                  SnackBarBehavior.floating, // 可選：使 SnackBar 浮動
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10.0), // 可選：設置圓角
                              ),
                              backgroundColor: healDarkGrey,
                            ),
                          );
                          _loadAllProducts();
                          Navigator.pop(context);
                        });
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    child: const Text(
                      'Edit And Save',
                      style: TextStyle(fontSize: 30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

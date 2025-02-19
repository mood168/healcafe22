// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'constant.dart';
import 'database_helper.dart';

class MemberManage extends StatefulWidget {
  const MemberManage({super.key});

  @override
  State<MemberManage> createState() => _MemberManageState();
}

class _MemberManageState extends State<MemberManage> {
  late Future<List<Map<String, dynamic>>> _allMembers;

  @override
  void initState() {
    super.initState();
    _loadAllMembers();
  }

  void _loadAllMembers() {
    if (mounted) {
      setState(() {
        _allMembers = DatabaseHelper().getAllMembers();
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
                future: _allMembers,
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
                              'Name',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Email',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Password',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Level',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'User Id',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 20),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Phone',
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
                                        return addMember();
                                      });
                                },
                                icon: const Icon(Icons.add_circle_outline,
                                    color: healDarkGrey, size: 40)),
                          ),
                        ],
                        rows: snapshot.data!.map((member) {
                          return DataRow(cells: [
                            DataCell(Text(
                              member['userName'],
                              style: const TextStyle(
                                  color: healDarkGrey, fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                member['userEmail'],
                                style: const TextStyle(
                                    color: healDarkGrey, fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              member['userPassWord'],
                              style: const TextStyle(
                                  color: healDarkGrey, fontSize: 18),
                            )),
                            DataCell(Text(
                              member['userLevel'].toString(),
                              style: const TextStyle(
                                  color: healDarkGrey, fontSize: 18),
                            )),
                            DataCell(Text(
                              member['userId'],
                              style: const TextStyle(
                                  color: healDarkGrey, fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                member['userPhone'],
                                style: const TextStyle(
                                    color: healDarkGrey, fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              member['createdDateTime']
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
                                              editMember(member));
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
                                            title: const Text('Delete Member',
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
                                                      member['userId']),
                                                  Navigator.pop(context, true),
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) {
                                        if (value != null && value) {
                                          _loadAllMembers(); // 重新加載產品數據
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

  Widget addMember() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    int level = 9;
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
                      controller: emailController,
                      decoration: const InputDecoration(
                        hintText: 'Input the Email',
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
                      controller: passwordController,
                      decoration: const InputDecoration(
                        hintText: 'Input the password',
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
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Input Your Name',
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
                      controller: phoneController,
                      decoration: const InputDecoration(
                        hintText: 'Input the Phone',
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
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorWhite80,
                            width: 1,
                          ),
                        ),
                      ),
                      dropdownColor: colorWhite80,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: colorWhite80,
                      ),
                      iconSize: 28,
                      style: const TextStyle(
                        color: colorWhite80,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                      value: level,
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('admin',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 22)),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('owner',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 22)),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('manager',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 22)),
                        ),
                        DropdownMenuItem(
                          value: 9,
                          child: Text('operator',
                              style:
                                  TextStyle(color: healDarkGrey, fontSize: 22)),
                        ),
                      ],
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            level = value!;
                          });
                        }
                      },
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
                        if (emailController.text.isEmpty ||
                            passwordController.text.isEmpty ||
                            nameController.text.isEmpty) {
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
                          String userId =
                              await DatabaseHelper().getLatestUserId();
                          if (userId.isEmpty) {
                            userId = 'U00001';
                          } else {
                            userId =
                                'U${(int.parse(userId.substring(1)) + 1).toString().padLeft(5, '0')}';
                          }

                          final Map<String, dynamic> user = {
                            'userEmail': emailController.text,
                            'userName': nameController.text,
                            'userPassWord': passwordController.text,
                            'userLevel': level,
                            'userId': userId,
                            'createdDateTime': DateTime.now().toString(),
                            'userPhone': phoneController.text,
                          };
                          await DatabaseHelper().insertUser(user);
                          _loadAllMembers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: const Text(
                                  'User Added Successfully',
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
                        'Add Member',
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

  Widget editMember(Map<String, dynamic> member) {
    int level = member['userLevel'] ?? 9;
    TextEditingController nameEditController =
        TextEditingController(text: member['userName']);
    TextEditingController passwordEditController =
        TextEditingController(text: member['userPassWord']);
    TextEditingController phoneEditController =
        TextEditingController(text: member['userPhone']);

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
                    controller: passwordEditController,
                    decoration: const InputDecoration(
                      labelText: 'Input the Password',
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
                    controller: phoneEditController,
                    decoration: const InputDecoration(
                      labelText: 'Input the Phone',
                      labelStyle: TextStyle(color: healDarkGrey, fontSize: 18),
                    ),
                    style: const TextStyle(color: healDarkGrey, fontSize: 22),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 350,
                  // 使用 radio 組件 來呈現選項 1,2,3,9 的選擇
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: colorWhite80,
                          width: 1,
                        ),
                      ),
                    ),
                    dropdownColor: colorDarkGrey,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: colorWhite80,
                    ),
                    iconSize: 28,
                    style: const TextStyle(
                      color: colorWhite80,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                    value: level,
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('admin',
                            style: TextStyle(color: Colors.blue, fontSize: 22)),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('owner',
                            style: TextStyle(color: Colors.blue, fontSize: 22)),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('manager',
                            style: TextStyle(color: Colors.blue, fontSize: 22)),
                      ),
                      DropdownMenuItem(
                        value: 9,
                        child: Text('operator',
                            style: TextStyle(color: Colors.blue, fontSize: 22)),
                      ),
                    ],
                    onChanged: (int? value) {
                      if (mounted) {
                        setState(() {
                          level = value!;
                        });
                      }
                    },
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
                          'userId': member['userId'],
                          'userName': nameEditController.text,
                          'userPassword': passwordEditController.text,
                          'userPhone': phoneEditController.text,
                          'userLevel': level,
                        }).then((value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Container(
                                height: 80.0, // 設置高度
                                alignment: Alignment.center,
                                // color: healDarkGrey,
                                child: const Text(
                                  'User Edited Successfully',
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
                          _loadAllMembers();
                          debugPrint('level: $level');
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

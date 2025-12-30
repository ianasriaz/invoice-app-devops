import 'package:flutter/material.dart';
import 'package:gsheet/constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ManageProducts extends StatefulWidget {
  const ManageProducts({super.key});

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  List datas = [];

  // Logic kept exactly as is
  Future getData() async {
    final url = Uri.parse(
        'https://invoice-maker-283c8-default-rtdb.asia-southeast1.firebasedatabase.app/Products.json');
    var res = await http.get(url);
    if (res.body != 'null') {
      datas = json.decode(res.body);
    }
    return true;
  }

  void deleteItem(int i, String index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                try {
                  final url = Uri.parse(
                      'https://invoice-maker-283c8-default-rtdb.asia-southeast1.firebasedatabase.app/Products/$index.json');
                  var res = await http.delete(url);
                  if (res.statusCode == 200) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Item Deleted Successfully'),
                            backgroundColor: AppColors.success),
                      );
                      Navigator.of(context).pop(true);
                    }
                    setState(() {
                      datas.removeWhere((element) =>
                          element != null && element['index'] == index);
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Something went wrong'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void updateData(int i) async {
    TextEditingController name = TextEditingController();
    TextEditingController size = TextEditingController();
    TextEditingController price = TextEditingController();
    TextEditingController type = TextEditingController();

    name.text = datas[i]["Product Name"];
    size.text = datas[i]["Pack size"];
    price.text = datas[i]["Unit Price"].toString();
    type.text = datas[i]["Type"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Update Product'),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close update dialog first
                deleteItem(i, datas[i]['index']);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: "Delete Item",
            )
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(name, 'Product Name', Icons.shopping_bag),
              const SizedBox(height: 15),
              _buildDropdown(type, (val) => setState(() => type.text = val!)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(size, 'Pack Size', Icons.layers)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildTextField(price, 'Price', Icons.attach_money,
                          isNumber: true)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              try {
                final url = Uri.parse(
                    'https://invoice-maker-283c8-default-rtdb.asia-southeast1.firebasedatabase.app/Products.json');
                var res = await http.patch(url,
                    body: json.encode({
                      i.toString(): {
                        'Product Name': name.text,
                        'Type': type.text,
                        'Pack size': size.text,
                        'Unit Price': price.text,
                        'index': datas[i]['index'] // Preserve index
                      }
                    }));
                if (res.statusCode == 200) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Product Updated'),
                          backgroundColor: AppColors.primary),
                    );
                    Navigator.of(context).pop();
                  }
                  // Refresh list conceptually (or re-fetch)
                  setState(() {
                    datas[i]['Product Name'] = name.text;
                    datas[i]['Type'] = type.text;
                    datas[i]['Pack size'] = size.text;
                    datas[i]['Unit Price'] = price.text;
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Something went wrong')),
                  );
                }
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void addProduct(BuildContext context) async {
    TextEditingController name = TextEditingController();
    TextEditingController size = TextEditingController();
    TextEditingController price = TextEditingController();
    TextEditingController type = TextEditingController();

    type.text = 'Unselected';
    // Logic kept mostly same, cleaned up for async flow
    int target = datas.length;
    final url = Uri.parse(
        'https://invoice-maker-283c8-default-rtdb.asia-southeast1.firebasedatabase.app/Products.json');

    // Optimistic fetching of target index logic from your code
    try {
      var res = await http.get(url);
      if (res.body != 'null') {
        List temp = json.decode(res.body);
        target = temp.length;
      } else {
        target = 0;
      }
    } catch (e) {
      target = datas.length;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(name, 'Product Name', Icons.shopping_bag),
                const SizedBox(height: 15),
                _buildDropdown(type, (val) => setState(() => type.text = val!)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                        child:
                            _buildTextField(size, 'Pack Size', Icons.layers)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildTextField(
                            price, 'Price', Icons.attach_money,
                            isNumber: true)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                try {
                  final addedP = {
                    'Product Name': name.text,
                    'Type': type.text,
                    'Pack size': size.text,
                    'Unit Price': price.text,
                    'index': target.toString()
                  };
                  final url = Uri.parse(
                      'https://invoice-maker-283c8-default-rtdb.asia-southeast1.firebasedatabase.app/Products/$target.json');
                  var res = await http.put(url, body: json.encode(addedP));
                  if (res.statusCode == 200) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Product Added'),
                            backgroundColor: AppColors.success),
                      );
                      Navigator.of(context).pop();
                    }
                    setState(() {
                      datas.add(addedP);
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Something went wrong')),
                    );
                  }
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for TextFields
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        isDense: true,
      ),
    );
  }

  // Helper widget for Dropdown
  Widget _buildDropdown(
      TextEditingController controller, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: controller.text == '' || controller.text == 'Unselected'
          ? 'Unselected'
          : controller.text,
      decoration: InputDecoration(
        labelText: 'Type',
        prefixIcon: const Icon(Icons.category, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        isDense: true,
      ),
      items: ['Unselected', 'Tablet', 'Suspention', 'Syrup', 'PFS', 'Capsul']
          .map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  var myF;
  @override
  void initState() {
    myF = getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Products',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addProduct(context),
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: FutureBuilder(
        future: myF,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (datas.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: datas.length,
            itemBuilder: (context, i) {
              // Handle potential nulls in Firebase lists
              if (datas[i] == null) return const SizedBox.shrink();

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => updateData(i), // Tap card to edit
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Leading Badge (Pack Size)
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.2))),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                datas[i]["Pack size"].toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                              const Text("Size",
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.grey))
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Main Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                datas[i]["Product Name"].toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  datas[i]["Type"].toString(),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Trailing (Price & Edit Icon)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${datas[i]["Unit Price"]} TK',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Icon(Icons.edit,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

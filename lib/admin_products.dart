import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class admin_products extends StatefulWidget {
  const admin_products({super.key});

  @override
  _admin_productsState createState() => _admin_productsState();
}

class _admin_productsState extends State<admin_products> {
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    fetchProductsFromFirestore();
  }

  Future<void> fetchProductsFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('items').get();
      final fetchedProducts =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id, // 🔑 Needed for updating the item
              'name': data['name'],
              'price': data['price'], // Leave it as number
              'image': data['image'],
              'description': data['description'],
              'stocks': data['stocks'],
            };
          }).toList();

      setState(() {
        products = fetchedProducts;
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  void showAddItemModal(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _descController = TextEditingController();
    final _priceController = TextEditingController();
    final _stockController = TextEditingController();
    File? _selectedImage;
    final ImagePicker _picker = ImagePicker();
    Future<void> _pickImage(StateSetter setState) async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }

    Future<String> _uploadImageToCloudinary(File imageFile) async {
      final cloudName = 'dnpi5mbaq'; // Replace with your Cloudinary cloud name
      final uploadPreset =
          'afitness'; // Replace with your unsigned upload preset

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request =
          http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = uploadPreset
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path),
            );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url']; // This is your hosted image URL
      } else {
        throw Exception('Failed to upload image');
      }
    }

    void _submitForm(BuildContext context, StateSetter setState) async {
      if (_formKey.currentState!.validate() && _selectedImage != null) {
        try {
          final id = FirebaseFirestore.instance.collection('items').doc().id;

          // Upload image to Cloudinary
          final imageUrl = await _uploadImageToCloudinary(_selectedImage!);

          await FirebaseFirestore.instance.collection('items').doc(id).set({
            'id': id,
            'name': _nameController.text,
            'description': _descController.text,
            'price': int.tryParse(_priceController.text) ?? 0,
            'stocks': int.tryParse(_stockController.text) ?? 0,
            'image': imageUrl, // Cloudinary image URL
          });

          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Item added!')));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields and select an image')),
        );
      }
      fetchProductsFromFirestore();
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: EdgeInsets.all(16),
                  scrollable: true,
                  content: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Item Name'),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter item name' : null,
                        ),
                        TextFormField(
                          controller: _descController,
                          decoration: InputDecoration(labelText: 'Description'),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter description' : null,
                        ),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                          validator:
                              (value) => value!.isEmpty ? 'Enter price' : null,
                        ),
                        TextFormField(
                          controller: _stockController,
                          decoration: InputDecoration(labelText: 'Stocks'),
                          keyboardType: TextInputType.number,
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter stock count' : null,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Select or Upload an Image:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _pickImage(setState),
                          child:
                              _selectedImage != null
                                  ? Image.file(
                                    _selectedImage!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                  : Icon(
                                    Icons.add_a_photo,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _submitForm(context, setState),
                          child: Text('Add Item'),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void showEditItemModal(BuildContext context, Map<String, dynamic> itemData) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: itemData['name']);
    final _descController = TextEditingController(
      text: itemData['description'],
    );
    final _priceController = TextEditingController(
      text: itemData['price'].toString(),
    );
    final _stockController = TextEditingController(
      text: itemData['stocks'].toString(),
    );
    File? _selectedImage;
    final ImagePicker _picker = ImagePicker();

    Future<void> _pickImage(StateSetter setState) async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }

    Future<String> _uploadImageToCloudinary(File imageFile) async {
      final cloudName = 'your_cloud_name';
      final uploadPreset = 'your_upload_preset';
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request =
          http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = uploadPreset
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path),
            );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      } else {
        throw Exception('Failed to upload image');
      }
    }

    void _submitForm(BuildContext context, StateSetter setState) async {
      if (_formKey.currentState!.validate()) {
        try {
          final updatedData = {
            'name': _nameController.text,
            'description': _descController.text,
            'price': int.tryParse(_priceController.text) ?? 0,
            'stocks': int.tryParse(_stockController.text) ?? 0,
          };

          if (_selectedImage != null) {
            final imageUrl = await _uploadImageToCloudinary(_selectedImage!);
            updatedData['image'] = imageUrl;
          }

          await FirebaseFirestore.instance
              .collection('items')
              .doc(itemData['id'])
              .update(updatedData);

          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Item updated!')));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      }
      fetchProductsFromFirestore();
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: EdgeInsets.all(16),
                  scrollable: true,
                  content: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Item Name'),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter item name' : null,
                        ),
                        TextFormField(
                          controller: _descController,
                          decoration: InputDecoration(labelText: 'Description'),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter description' : null,
                        ),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                          validator:
                              (value) => value!.isEmpty ? 'Enter price' : null,
                        ),
                        TextFormField(
                          controller: _stockController,
                          decoration: InputDecoration(labelText: 'Stocks'),
                          keyboardType: TextInputType.number,
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter stock count' : null,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Update Image (optional):",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _pickImage(setState),
                          child:
                              _selectedImage != null
                                  ? Image.file(
                                    _selectedImage!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                  : itemData['image'] != null
                                  ? Image.network(
                                    itemData['image'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                  : Icon(
                                    Icons.add_a_photo,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _submitForm(context, setState),
                          child: Text('Update Item'),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void deleteItem(BuildContext context, String itemId) async {
    // Show a confirmation dialog
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Item'),
            content: Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    // If the user confirmed the deletion
    if (confirmDelete == true) {
      try {
        // Delete the item from Firestore
        await FirebaseFirestore.instance
            .collection('items')
            .doc(itemId)
            .delete();
        fetchProductsFromFirestore();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Item deleted!')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete item')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              showAddItemModal(context);
              fetchProductsFromFirestore();
            },
            icon: Icon(Icons.add),
          ),
        ],
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: Text("Manage Products", style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ), // Add some spacing between the two texts
            // Strength Training Text
            products.isEmpty
                ? const Center(
                  child: Text(
                    "No product",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                )
                :
                // GridView of Products
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                      ), // Add spacing between items
                      decoration: BoxDecoration(
                        color: const Color((0xFF12476F)),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Product Image
                                Image.network(
                                  product['image'],
                                  height: 70,
                                  width: 70,
                                ),
                                const SizedBox(width: 12),
                                // Product Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "PHP ${product['price'].toString()}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${product['stocks']} Stocks",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    deleteItem(context, product['id']);
                                  },
                                  icon: Icon(
                                    size: 30,
                                    Icons.delete_outline,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    showEditItemModal(context, product);
                                    fetchProductsFromFirestore(); // 🔁 Refresh after update
                                  },
                                  icon: Icon(Icons.edit, color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

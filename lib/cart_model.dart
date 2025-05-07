// cart_model.dart
class CartItem {
  final String name;
  final String price;
  final String image; // Add the image property

  CartItem({
    required this.name,
    required this.price,
    required this.image, // Include image in constructor
  });
}

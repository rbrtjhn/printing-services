import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Simple model for an order returned by the API.
class Order {
  final int orderId;
  final String customerName;
  final String documentType;
  final int pageCount;
  final String colorType;
  final String totalPrice;
  final String orderStatus;
  final DateTime orderDate;

  Order({
    required this.orderId,
    required this.customerName,
    required this.documentType,
    required this.pageCount,
    required this.colorType,
    required this.totalPrice,
    required this.orderStatus,
    required this.orderDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: int.tryParse(json['order_id'].toString()) ?? 0,
      customerName: json['customer_name'],
      documentType: json['document_type'],
      pageCount: int.tryParse(json['page_count'].toString()) ?? 0,
      colorType: json['color_type'],
      totalPrice: json['total_price'],
      orderStatus: json['order_status'],
      orderDate: DateTime.parse(json['order_date']),
    );
  }
}

Future<List<Order>> fetchOrders() async {
  final uri = Uri.parse('http://localhost/printing_api/get_orders.php');
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> list = json.decode(response.body);
    return list.map((e) => Order.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load orders (${response.statusCode})');
  }
}

void main() {
  runApp(const PrintingDashboardApp());
}

class PrintingDashboardApp extends StatelessWidget {
  const PrintingDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Printing Services Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OrdersPage(),
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Order>> _ordersFuture;
  
  // Form controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _documentTypeController = TextEditingController();
  final TextEditingController _pageCountController = TextEditingController();
  final TextEditingController _colorTypeController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchOrders();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _documentTypeController.dispose();
    _pageCountController.dispose();
    _colorTypeController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final uri = Uri.parse('http://localhost/printing_api/add_order.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'customer_name': _customerNameController.text,
          'document_type': _documentTypeController.text,
          'page_count': _pageCountController.text,
          'color_type': _colorTypeController.text,
          'total_price': _totalPriceController.text,
        },
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Close the dialog
          Navigator.of(context).pop();
          
          // Clear form fields
          _customerNameController.clear();
          _documentTypeController.clear();
          _pageCountController.clear();
          _colorTypeController.clear();
          _totalPriceController.clear();
          
          // Refresh the orders list
          setState(() {
            _ordersFuture = fetchOrders();
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order created successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      final uri = Uri.parse('http://localhost/printing_api/update_status.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'order_id': orderId.toString(),
          'order_status': newStatus,
        },
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status updated successfully!')),
          );
          
          // Refresh the orders list
          setState(() {
            _ordersFuture = fetchOrders();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteOrder(int orderId) async {
    try {
      final uri = Uri.parse('http://localhost/printing_api/delete_order.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'order_id': orderId.toString(),
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order deleted successfully!')),
          );
          
          // Refresh the orders list
          setState(() {
            _ordersFuture = fetchOrders();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(int orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Order'),
          content: const Text('Are you sure you want to delete this order?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteOrder(orderId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateOrderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Order'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _documentTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter document type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pageCountController,
                    decoration: const InputDecoration(
                      labelText: 'Page Count',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter page count';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _colorTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Color Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter color type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _totalPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Total Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter total price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _submitOrder,
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printing Orders'),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('No orders available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Card(
                  elevation: 4,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Document')),
                        DataColumn(label: Text('Pages')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: orders
                          .map(
                            (o) => DataRow(cells: [
                              DataCell(Text(o.customerName)),
                              DataCell(Text(o.documentType)),
                              DataCell(Text(o.pageCount.toString())),
                              DataCell(Text('\₱${o.totalPrice}')),
                              DataCell(
                                DropdownButton<String>(
                                  value: o.orderStatus,
                                  items: const [
                                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                    DropdownMenuItem(value: 'Printing', child: Text('Printing')),
                                    DropdownMenuItem(value: 'Done', child: Text('Done')),
                                  ],
                                  onChanged: (String? newStatus) {
                                    if (newStatus != null && newStatus != o.orderStatus) {
                                      _updateOrderStatus(o.orderId, newStatus);
                                    }
                                  },
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(o.orderId);
                                  },
                                ),
                              ),
                            ]),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateOrderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
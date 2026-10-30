import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// 1. SHOPPING LIST MODEL
class ItemListModel extends ChangeNotifier {
  final List<String> _items = ['Milk', 'Bread', 'Eggs'];

  List<String> get items => List.unmodifiable(_items);

  void addItem(String item) {
    final newItem = item.trim();

    if (newItem.isEmpty) return;

    _items.add(newItem);
    notifyListeners();
  }
}

// 2. MAIN FUNCTION
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ItemListModel(),
      child: const MyApp(),
    ),
  );
}

// 3. MAIN APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ListScreen(),
    );
  }
}

// 4. SHOPPING LIST SCREEN
class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemModel = context.watch<ItemListModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Shopping List')),
      body: Column(
        children: [
          Expanded(
            child: itemModel.items.isEmpty
                ? const Center(child: Text('Your shopping list is empty.'))
                : ListView.builder(
                    itemCount: itemModel.items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.shopping_cart),
                        title: Text(itemModel.items[index]),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Shopping Item'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddItemScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('View API Posts'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ApiScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 5. ADD ITEM SCREEN
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem() {
    final item = _controller.text.trim();

    if (item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name.')),
      );
      return;
    }

    // Add through Provider instead of Navigator.pop(result).
    context.read<ItemListModel>().addItem(item);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Shopping Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item name',
                hintText: 'Example: Apples',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addItem(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addItem,
                child: const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. API POST MODEL
class ApiPost {
  final int id;
  final String title;
  final String body;

  const ApiPost({required this.id, required this.title, required this.body});

  factory ApiPost.fromJson(Map<String, dynamic> json) {
    return ApiPost(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

// 7. API SCREEN
class ApiScreen extends StatefulWidget {
  const ApiScreen({super.key});

  @override
  State<ApiScreen> createState() => _ApiScreenState();
}

class _ApiScreenState extends State<ApiScreen> {
  static const String _url = 'https://jsonplaceholder.typicode.com/posts';

  List<ApiPost> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Unable to retrieve posts.');
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;

      final fetchedPosts = decoded.map((item) {
        return ApiPost.fromJson(item as Map<String, dynamic>);
      }).toList();

      if (!mounted) return;

      setState(() {
        _posts = fetchedPosts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load posts. Check your internet connection and try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Posts')),
      body: RefreshIndicator(onRefresh: _fetchPosts, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    // LOADING STATE
    if (_isLoading && _posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 16),
          Center(child: Text('Loading posts...')),
        ],
      );
    }

    // ERROR STATE WITH RETRY
    if (_error != null && _posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 150),
          const Icon(Icons.wifi_off, size: 60),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
          Center(
            child: ElevatedButton(
              onPressed: _fetchPosts,
              child: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    // EMPTY STATE
    if (_posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: Text('No posts found.')),
        ],
      );
    }

    // DATA STATE
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text('${post.id}')),
            title: Text(post.title),
            subtitle: Text(post.body),
          ),
        );
      },
    );
  }
}

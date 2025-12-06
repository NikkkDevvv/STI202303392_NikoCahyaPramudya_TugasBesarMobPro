import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/destination_model.dart';
import '../widgets/destination_card.dart';
import '../screens/detail_screen.dart';
import '../screens/add_destination_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Destination> _allDestinations = [];
  List<Destination> _filteredDestinations = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.readAllDestinations();
    setState(() {
      _allDestinations = data;
      _filteredDestinations = data;
      _isLoading = false;
    });
  }

  void _runFilter(String keyword) {
    List<Destination> results = [];
    if (keyword.isEmpty) {
      results = _allDestinations;
    } else {
      results = _allDestinations
          .where((item) =>
          item.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _filteredDestinations = results;
    });
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper.instance.delete(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destinasi berhasil dihapus')),
      );
    }
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddDestinationScreen(),
              ),
            );

            if (result == true) {
              _refreshData();
            }
          },
          label: const Text('Tambah'),
          icon: const Icon(Icons.add_rounded),
          elevation: 4,
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
        ),
      ),

      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mau liburan\nke mana hari ini?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _runFilter(value),
                      decoration: const InputDecoration(
                        hintText: 'Cari desa, curug, pantai...',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDestinations.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "Belum ada data wisata",
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),

                  itemCount: _filteredDestinations.length,
                  itemBuilder: (context, index) {
                    final item = _filteredDestinations[index];
                    return DestinationCard(
                      destination: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(destination: item),
                          ),
                        );
                      },
                      onEdit: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddDestinationScreen(destination: item),
                          ),
                        );
                        if (result == true) {
                          _refreshData();
                        }
                      },
                      onDelete: () => _deleteItem(item.id!),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
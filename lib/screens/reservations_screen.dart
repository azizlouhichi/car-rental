// lib/screens/reservations_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ReservationsScreen extends StatefulWidget {
  @override
  _ReservationsScreenState createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<dynamic> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('reservations/', token: token);
      setState(() {
        _reservations = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reservations: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Reservations')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
          ? Center(child: Text('No reservations found'))
          : ListView.builder(
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          final reservation = _reservations[index];
          return Card(
            child: ListTile(
              title: Text(
                  '${reservation['voiture']['marque']} ${reservation['voiture']['modele']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'From: ${reservation['date_debut']} to ${reservation['date_fin']}'),
                  Text('Status: ${reservation['etat']}'),
                ],
              ),
              trailing: Icon(Icons.chevron_right),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Reservations',
          ),
        ],
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
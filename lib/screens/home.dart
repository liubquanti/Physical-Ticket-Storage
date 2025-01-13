import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../database/helper.dart';
import 'scan.dart';
import 'package:barcode_widget/barcode_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _dbHelper.getTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tickets yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final ticket = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket #${ticket.id}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Added: ${ticket.dateAdded.toString()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: BarcodeWidget(
                          barcode: Barcode.pdf417(),
                          data: ticket.code,
                          width: 300,
                          height: 100,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final scannedCode = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
          
          if (scannedCode != null) {
            // Check if ticket already exists
            final exists = await _dbHelper.ticketExists(scannedCode);
            
            if (exists) {
              // Show error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This ticket already exists'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              // Add new ticket
              await _dbHelper.insertTicket(
                Ticket(code: scannedCode, dateAdded: DateTime.now()),
              );
              setState(() {});
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ticket added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
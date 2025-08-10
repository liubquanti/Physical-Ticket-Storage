import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../database/helper.dart';
import 'scan.dart';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'ticket.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<String?> _showTitleDialog({String? initialTitle}) async {
    String? title = initialTitle;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(initialTitle == null ? 'Ajouter un titre de billet' : 'Modifier le titre du billet'),
        content: TextField(
          onChanged: (value) => title = value,
          controller: TextEditingController(text: initialTitle),
          decoration: const InputDecoration(
            hintText: 'Billet pour...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, title),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    return title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D131F),
  title: const Text('Billets'),
      ),
      backgroundColor: const Color(0xFF0D131F),
      body: FutureBuilder<List<Ticket>>(
        future: _dbHelper.getTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SvgPicture.asset(
                      'assets/svg/train-path.svg',
                    ),
                  ),
      const Text('Aucun billet pour le moment'),
                ],
              )
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final ticket = snapshot.data![index];
                    return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                    children: [
                    if (index == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SvgPicture.asset(
                          'assets/svg/train.svg',
                        ),
                      ),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: const Color(0xFF242B35),
                      margin: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onLongPress: () => _showBottomSheet(ticket),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TicketDetailsScreen(ticket: ticket),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'Ajouté : ${ticket.dateAdded.toString()}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                    ),
                                  child: BarcodeWidget(
                                  barcode: Barcode.pdf417(),
                                  data: ticket.code,
                                  height: 110,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ), 
                    ],
                  ),
                );
              }),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        backgroundColor: const Color(0xFF8BE9FE),
        onPressed: () async {
          final scannedCode = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
          
          if (scannedCode != null) {
            final exists = await _dbHelper.ticketExists(scannedCode);
            
            if (exists) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ce billet a déjà été ajouté'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              final title = await _showTitleDialog();
              if (title != null && mounted) {
                await _dbHelper.insertTicket(
                  Ticket(
                    code: scannedCode,
                    title: title,
                    dateAdded: DateTime.now(),
                  ),
                );
                setState(() {});
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Billet ajouté avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        },
        child: Icon(Icons.add, color: const Color(0xFF0C121C)),
      ),
    );
  }

  void _showBottomSheet(Ticket ticket) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier le titre'),
            onTap: () {
              Navigator.pop(context);
              _editTicketTitle(ticket);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(ticket);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editTicketTitle(Ticket ticket) async {
    String? newTitle = await _showTitleDialog(initialTitle: ticket.title);
    if (newTitle != null && mounted) {
      await _dbHelper.updateTicketTitle(ticket.id!, newTitle);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Titre modifié'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Ticket ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce billet ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _dbHelper.deleteTicket(ticket.id!);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Billet supprimé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
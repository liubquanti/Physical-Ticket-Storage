import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../database/helper.dart';
import 'scan.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        title: Text(initialTitle == null ? 'Додайте назву квитку' : 'Змініть назву квитка'),
        content: TextField(
          onChanged: (value) => title = value,
          controller: TextEditingController(text: initialTitle),
          decoration: const InputDecoration(
            hintText: 'Квиток до...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, title),
            child: const Text('Зберегти'),
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
        title: const Text('Квитки'),
      ),
      backgroundColor: const Color(0xFF0D131F),
      body: FutureBuilder<List<Ticket>>(
        future: _dbHelper.getTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Поки квитків немає'));
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
                      Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SvgPicture.asset(
                        'assets/svg/train-path.svg',
                        
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
                                'Додано: ${ticket.dateAdded.toString()}',
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
                    content: Text('Цей квиток вже додано'),
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
                    content: Text('Квиток успішно додано'),
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
            title: const Text('Змінити назву'),
            onTap: () {
              Navigator.pop(context);
              _editTicketTitle(ticket);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Видалити', style: TextStyle(color: Colors.red)),
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
            content: Text('Назву змінено'),
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
        title: const Text('Підтвердження'),
        content: const Text('Ви впевнені, що хочете видалити цей квиток?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Видалити'),
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
            content: Text('Квиток видалено'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
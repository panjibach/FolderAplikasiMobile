import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:utsproject/models/transaction.dart';
import 'package:utsproject/services/transaction_service.dart';
import 'package:utsproject/services/category_services.dart';
import 'package:utsproject/pages/transaction_page.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({Key? key}) : super(key: key);

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Pastikan kategori dimuat terlebih dahulu
      await Provider.of<CategoryService>(context, listen: false).fetchCategories();

      // Kemudian muat transaksi
      await Provider.of<TransactionService>(context, listen: false).fetchTransactions();

      // Debug: print semua transaksi setelah fetch
      Provider.of<TransactionService>(context, listen: false).debugPrintAllTransactions();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionService = Provider.of<TransactionService>(context);
    final transactions = transactionService.getTransactionsByMonth(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaksi'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy', 'id').format(_selectedDate),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // Debug buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    transactionService.testBackendConnection();
                  },
                  child: Text('Test Connection'),
                ),
                ElevatedButton(
                  onPressed: () {
                    transactionService.addDummyTransaction();
                  },
                  child: Text('Add Dummy'),
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: transactions.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tidak ada transaksi'),
                  SizedBox(height: 16),
                  Text('Total transaksi: ${transactionService.transactions.length}'),
                  SizedBox(height: 8),
                  Text('Total kategori: ${Provider.of<CategoryService>(context).categories.length}'),
                ],
              ),
            )
                : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaction.category.isExpense
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      child: Icon(
                        transaction.category.isExpense
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: transaction.category.isExpense
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    title: Text(
                      transaction.category.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('dd MMM yyyy', 'id').format(transaction.date)}\n${transaction.description}',
                    ),
                    trailing: Text(
                      transaction.formattedAmount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transaction.category.isExpense
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionPage(
                            transaction: transaction,
                          ),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionPage(
                initialDate: _selectedDate,
              ),
            ),
          ).then((_) => _loadData());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
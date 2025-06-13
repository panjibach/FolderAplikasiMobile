import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:utsproject/services/category_services.dart';
import 'package:utsproject/services/transaction_service.dart';
import 'package:utsproject/models/category.dart';
import 'package:utsproject/models/transaction.dart';
import 'package:flutter/services.dart';

class TransactionPage extends StatefulWidget {
  final Transaction? transaction; // Null for new transaction, non-null for edit
  final DateTime? initialDate; // Initial date for new transactions

  const TransactionPage({
    Key? key,
    this.transaction,
    this.initialDate,
  }) : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Category? _selectedCategory;
  bool _isExpense = true;
  late DateTime _selectedDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Panggil fetchTransactions saat halaman dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionService = Provider.of<TransactionService>(context, listen: false);
      transactionService.fetchTransactions().then((_) {
        // Tambahkan setState jika perlu untuk memperbarui UI
        if (mounted) setState(() {});

        // Debug: print semua transaksi setelah fetch
        transactionService.debugPrintAllTransactions();
      }).catchError((error) {
        print('Error fetching transactions: $error');
        // Tampilkan pesan error ke pengguna jika perlu
      });
    });

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Set the selected date
    if (widget.transaction != null) {
      _selectedDate = widget.transaction!.date;
      debugPrint('Editing transaction with date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
    } else {
      // Pastikan tanggal awal tidak memiliki komponen waktu
      final initialDate = widget.initialDate ?? DateTime.now();
      _selectedDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
      debugPrint('New transaction with initial date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
    }

    // If editing an existing transaction, populate the fields
    if (widget.transaction != null) {
      _isExpense = widget.transaction!.category.isExpense;
      _selectedCategory = widget.transaction!.category;
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        // Set the date without time component
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        debugPrint('Date selected from picker: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryService = Provider.of<CategoryService>(context);
    final transactionService = Provider.of<TransactionService>(context, listen: false);

    final categories = _isExpense
        ? categoryService.getExpenseCategories()
        : categoryService.getIncomeCategories();

    // Format date for display
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id');
    final formattedDate = dateFormat.format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.transaction == null
              ? (_isExpense ? "Add Expense" : "Add Income")
              : (_isExpense ? "Edit Expense" : "Edit Income"),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction type header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isExpense
                        ? [Colors.red.shade700, Colors.red.shade500]
                        : [Colors.green.shade700, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _isExpense
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isExpense ? Icons.upload : Icons.download,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isExpense ? "Expense" : "Income",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _isExpense
                                ? "Money going out of your account"
                                : "Money coming into your account",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isExpense,
                      onChanged: (value) {
                        setState(() {
                          _isExpense = value;
                          _selectedCategory = null;
                        });
                        HapticFeedback.lightImpact();
                      },
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      activeTrackColor: Colors.white.withOpacity(0.3),
                      activeColor: Colors.white,
                      inactiveThumbColor: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form section title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  "Transaction Details",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),

              // Date selector
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.deepPurple[400],
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Date",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.edit_calendar,
                                color: Colors.deepPurple[400],
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Amount field
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Colors.deepPurple[400],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Amount",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 1.5),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "Rp.",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          hintText: "0",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category dropdown
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            color: Colors.deepPurple[400],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Category",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (categories.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red[400],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "No categories available",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Please add categories first before creating a transaction",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.red[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey[50],
                          ),
                          child: DropdownButtonFormField<Category?>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: InputBorder.none,
                              hintText: "Select a category",
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.grey[400],
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.deepPurple[400],
                            ),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            items: categories.map((category) {
                              return DropdownMenuItem<Category?>(
                                value: category,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: category.isExpense
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        category.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                                        color: category.isExpense ? Colors.red : Colors.green,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      category.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                              HapticFeedback.selectionClick();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description field
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            color: Colors.deepPurple[400],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Description (optional)",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descriptionController,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 1.5),
                          ),
                          hintText: "Add notes about this transaction",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: categories.isEmpty || _selectedCategory == null || _amountController.text.isEmpty
                      ? null
                      : () {
                    // Format the amount with currency
                    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
                    final formattedAmount = NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp. ',
                      decimalDigits: 0,
                    ).format(amount);

                    // Make sure we're using a date with no time component
                    final dateWithoutTime = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day
                    );

                    debugPrint('Saving transaction with date: ${DateFormat('yyyy-MM-dd').format(dateWithoutTime)}');

                    if (widget.transaction == null) {
                      // Add new transaction with selected date
                      transactionService.addTransaction(
                        formattedAmount,
                        _selectedCategory,
                        _descriptionController.text,
                        date: dateWithoutTime,
                      );
                    } else {
                      // Edit existing transaction with selected date
                      transactionService.editTransaction(
                        widget.transaction!.id,
                        formattedAmount,
                        _selectedCategory,
                        _descriptionController.text,
                        date: dateWithoutTime,
                      );
                    }

                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Save Transaction",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
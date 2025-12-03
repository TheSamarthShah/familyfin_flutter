import 'package:foundation_app/core/app_theme.dart';
import 'package:foundation_app/services/finance_service.dart';
import 'package:foundation_app/services/user_service.dart';
import 'package:foundation_app/widgets/common_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EditLogScreen extends StatefulWidget {
  final Map<String, dynamic>? log;

  const EditLogScreen({super.key, this.log});

  @override
  State<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends State<EditLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final FinanceService _financeService = FinanceService();

  bool _isLoading = false;
  bool _isInitLoading = true;
  bool _showValidationErrors = false;

  // --- FORM STATE ---
  late String _type;
  late TextEditingController _mainAmountController;
  String _selectedCurrency = 'INR';
  late TextEditingController _rateController;
  late TextEditingController _baseAmountController;
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _locationController;
  late TextEditingController _tagsController;

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String _selectedCategoryName = "Select Category";
  String _selectedCategoryIcon = "📁";
  String? _selectedAccountId;
  String _selectedAccountName = "Select Account";

  // --- DATA ---
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _currencies = [];
  late String _userBaseCurrencyCode;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _userBaseCurrencyCode = UserService().currencyCode;
    _selectedCurrency = _userBaseCurrencyCode;

    _type = 'expense';
    _mainAmountController = TextEditingController();
    _rateController = TextEditingController(text: "1.0");
    _baseAmountController = TextEditingController();
    _nameController = TextEditingController();
    _noteController = TextEditingController();
    _locationController = TextEditingController();
    _tagsController = TextEditingController();

    final results = await Future.wait([
      _financeService.getCategories(),
      _financeService.getAccounts(),
      _financeService.getCurrencies(),
    ]);

    if (mounted) {
      setState(() {
        _allCategories = results[0];
        _accounts = results[1];
        _currencies = results[2];
        if (_accounts.isNotEmpty) _selectAccount(_accounts.first);
      });

      if (widget.log != null) {
        _populateExistingData(widget.log!);
      } else {
        _fetchCurrentLocation();
      }
    }
    setState(() => _isInitLoading = false);
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        String result = place.name ?? '';
        if ((place.locality ?? '').isNotEmpty && result != place.locality) {
          result = "$result, ${place.locality}";
        }
        setState(() => _locationController.text = result);
      }
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  void _populateExistingData(Map<String, dynamic> log) {
    _type = log['type'] ?? 'expense';
    final baseAmt = (log['amount'] as num).toDouble();
    final foreignAmt = (log['foreign_amount'] as num?)?.toDouble();

    if (foreignAmt != null && foreignAmt > 0) {
      _selectedCurrency = log['foreign_currency_code'];
      _mainAmountController.text = _formatNumber(foreignAmt);
      _baseAmountController.text = _formatNumber(baseAmt);
      _rateController.text = (baseAmt / foreignAmt).toStringAsFixed(2);
    } else {
      _selectedCurrency = _userBaseCurrencyCode;
      _mainAmountController.text = _formatNumber(baseAmt);
      _baseAmountController.text = _formatNumber(baseAmt);
      _rateController.text = "1.0";
    }

    _nameController.text = log['item_name'] ?? '';
    _noteController.text = log['original_text'] ?? '';
    _locationController.text = log['location_name'] ?? '';
    if (log['tags'] != null && log['tags'] is List) {
      _tagsController.text = (log['tags'] as List).join(', ');
    }

    _selectedDate = DateTime.parse(
      log['created_at'] ?? DateTime.now().toIso8601String(),
    );

    if (log['category_id'] != null) {
      final cat = _allCategories.firstWhere(
        (e) => e['id'] == log['category_id'],
        orElse: () => {},
      );
      if (cat.isNotEmpty) _selectCategory(cat);
    }
    if (log['account_id'] != null) {
      final acc = _accounts.firstWhere(
        (e) => e['id'] == log['account_id'],
        orElse: () => {},
      );
      if (acc.isNotEmpty) _selectAccount(acc);
    }
  }

  void _selectCategory(Map<String, dynamic> cat) {
    setState(() {
      _selectedCategoryId = cat['id'];
      _selectedCategoryName = cat['name'];
      _selectedCategoryIcon = cat['icon_emoji'] ?? "📁";
    });
  }

  void _selectAccount(Map<String, dynamic> acc) {
    setState(() {
      _selectedAccountId = acc['id'];
      _selectedAccountName = acc['name'];
    });
  }

  void _onMainAmountChanged(String val) {
    if (_selectedCurrency == _userBaseCurrencyCode) return;
    _baseAmountController.text = _formatNumber(
      _parse(val) * _parse(_rateController.text),
    );
  }

  void _onRateChanged(String val) {
    _baseAmountController.text = _formatNumber(
      _parse(_mainAmountController.text) * _parse(val),
    );
  }

  void _onBaseAmountChanged(String val) {
    final base = _parse(val);
    final main = _parse(_mainAmountController.text);
    if (main != 0 &&
        (base / main - _parse(_rateController.text)).abs() > 0.01) {
      _rateController.text = (base / main).toStringAsFixed(2);
    }
  }

  double _parse(String txt) => double.tryParse(txt.replaceAll(',', '')) ?? 0.0;
  String _formatNumber(double val) => NumberFormat.decimalPattern().format(val);

  Future<void> _saveLog() async {
    setState(() => _showValidationErrors = true);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }
    setState(() => _isLoading = true);

    double finalBaseAmount;
    double? finalForeignAmount;
    String? finalForeignCode;
    final mainVal = _parse(_mainAmountController.text);

    if (_selectedCurrency == _userBaseCurrencyCode) {
      finalBaseAmount = mainVal;
    } else {
      finalBaseAmount = _parse(_baseAmountController.text);
      if (finalBaseAmount == 0) finalBaseAmount = mainVal;
      finalForeignAmount = mainVal;
      finalForeignCode = _selectedCurrency;
    }

    List<String> tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final success = await _financeService.upsertLog(
      logId: widget.log?['id'],
      amount: finalBaseAmount,
      type: _type,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId!,
      date: _selectedDate,
      itemName: _nameController.text,
      note: _noteController.text,
      foreignAmount: finalForeignAmount,
      foreignCurrency: finalForeignCode,
      locationName: _locationController.text,
      tags: tags,
    );

    setState(() => _isLoading = false);
    if (success && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 1. Get Theme Data
    final theme = Theme.of(context);
    final isExpense = _type == 'expense';
    final themeColor = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final isForeign = _selectedCurrency != _userBaseCurrencyCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.log == null ? "New Transaction" : "Edit Transaction",
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (widget.log != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: _deleteLog,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. TYPE TABS (Adaptive Color)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest, 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTypeTab("Expense", 'expense', AppTheme.expenseColor),
                    _buildTypeTab("Income", 'income', AppTheme.incomeColor),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. AMOUNT INPUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Amount",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _openCurrencySheet,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _selectedCurrency,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _mainAmountController,
                              inputFormatters: [
                                ThousandsSeparatorInputFormatter(),
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "0",
                                isDense: true,
                                filled: false,
                              ),
                              onChanged: _onMainAmountChanged,
                              validator: (val) => val == null || val.isEmpty
                                  ? "Required"
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 4. FOREIGN CONVERTER (Modern "Math Equation" Style)
              if (isForeign) _buildForeignConverter(theme),

              const SizedBox(height: 30),

              // 5. DETAILS FORM SECTION
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDeco("Description", Icons.edit),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),

                    SelectorButton(
                      label: "Category",
                      icon: Icons.category_outlined,
                      displayValue: _selectedCategoryId == null
                          ? "Select Category"
                          : _selectedCategoryName,
                      leadingEmoji: _selectedCategoryId == null
                          ? null
                          : _selectedCategoryIcon,
                      isEmpty: _selectedCategoryId == null,
                      hasError:
                          _showValidationErrors && _selectedCategoryId == null,
                      onTap: _openCategorySheet,
                    ),
                    const SizedBox(height: 16),

                    SelectorButton(
                      label: "Account",
                      icon: Icons.account_balance_wallet_outlined,
                      displayValue: _selectedAccountName,
                      isEmpty: _selectedAccountId == null,
                      hasError:
                          _showValidationErrors && _selectedAccountId == null,
                      onTap: _openAccountSheet,
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _pickDateTime,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                            text: DateFormat(
                              'MMM dd, yyyy \'at\' h:mm a',
                            ).format(_selectedDate),
                          ),
                          decoration: _inputDeco(
                            "Date & Time",
                            Icons.calendar_today,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: _inputDeco("Notes / Voice Log", Icons.notes),
                    ),

                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          "Additional Details (Optional)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        tilePadding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _locationController,
                            decoration: _inputDeco(
                              "Location",
                              Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _tagsController,
                            decoration: _inputDeco(
                              "Tags",
                              Icons.tag,
                              helperText: "Separate with commas",
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveLog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text(
                                "Save Transaction",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: SENSITBLE CONVERTER WIDGET ---
  Widget _buildForeignConverter(ThemeData theme) {
    final containerColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final iconColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.currency_exchange, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  "Currency Conversion",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildMiniInput(
                    context,
                    controller: _rateController,
                    label: "Rate",
                    onChanged: _onRateChanged,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildMiniInput(
                    context,
                    controller: _baseAmountController,
                    label: "Total ($_userBaseCurrencyCode)",
                    onChanged: _onBaseAmountChanged,
                    isTotal: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, // Inner card color
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTotal
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Center(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters:
                  isTotal ? [ThousandsSeparatorInputFormatter()] : [],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isTotal
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // --- SUB WIDGETS ---

  Widget _buildTypeTab(String label, String value, Color activeColor) {
    final theme = Theme.of(context);
    final isSelected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = value;
          _selectedCategoryId = null;
          _selectedCategoryName = "Select Category";
          _selectedCategoryIcon = "📁";
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(
    String label,
    IconData icon, {
    String? helperText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
    );
  }

  // --- SHEET LOGIC ---

  void _openCategorySheet() {
    FocusScope.of(context).unfocus();
    final theme = Theme.of(context);
    final filtered = _allCategories.where((c) => c['type'] == _type).toList();

    SelectorSheet.show<Map<String, dynamic>>(
      context: context,
      title: "Select Category",
      items: filtered,
      isScrollControlled: true,
      onSelected: (cat) {},
      itemBuilder: (cat) {
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cat['icon_emoji'] ?? "📁",
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(
            cat['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: _selectedCategoryId == cat['id']
              ? const Icon(Icons.check_circle)
              : null,
          onTap: () {
            _selectCategory(cat);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _openAccountSheet() {
    FocusScope.of(context).unfocus();
    SelectorSheet.show<Map<String, dynamic>>(
      context: context,
      title: "Select Account",
      items: _accounts,
      isScrollControlled: false,
      onSelected: (acc) {},
      itemBuilder: (acc) {
        return ListTile(
          leading: const Icon(Icons.account_balance_wallet),
          title: Text(
            acc['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: _selectedAccountId == acc['id']
              ? const Icon(Icons.check_circle)
              : null,
          onTap: () {
            _selectAccount(acc);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _openCurrencySheet() {
    FocusScope.of(context).unfocus();
    SelectorSheet.show<Map<String, dynamic>>(
      context: context,
      title: "Select Currency",
      items: _currencies,
      isScrollControlled: false,
      onSelected: (curr) {},
      itemBuilder: (curr) {
        return ListTile(
          leading: Text(
            curr['symbol'] ?? '\$',
            style: const TextStyle(fontSize: 24),
          ),
          title: Text(curr['code']),
          selected: curr['code'] == _selectedCurrency,
          onTap: () {
            setState(() {
              _selectedCurrency = curr['code'];
              if (_selectedCurrency == _userBaseCurrencyCode) {
                _rateController.text = "1.0";
                _baseAmountController.text = _mainAmountController.text;
              }
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    FocusScope.of(context).unfocus();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null) return;
    setState(
      () => _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }

  Future<void> _deleteLog() async {
    final confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _financeService.deleteLog(widget.log!['id']);
      if (mounted) Navigator.pop(context, true);
    }
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if ('.'.allMatches(newText).length > 1) return oldValue;
    if (newText == '.') return newValue.copyWith(text: '0.');
    List<String> parts = newText.split('.');
    String integerPart = parts[0].isEmpty ? '0' : parts[0];
    final formatter = NumberFormat('#,###');
    String newString = formatter.format(int.parse(integerPart));
    if (parts.length > 1 || newText.endsWith('.'))
      newString += '.${parts.length > 1 ? parts[1] : ""}';
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
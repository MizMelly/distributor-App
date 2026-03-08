import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';
import '../../utils/api.dart';

class TransferPaymentModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const TransferPaymentModal({
    super.key,
    required this.onSubmit,
  });

  @override
  State<TransferPaymentModal> createState() => _TransferPaymentModalState();
}

class _TransferPaymentModalState extends State<TransferPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _referenceNoController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> bankAccounts = [];
  int? selectedBankAccountId;
  bool isLoading = true;
  bool isSubmitting = false;
  int currentStep = 1; // 1 = Select account, 2 = Fill details

  // Image upload state
  File? selectedImage;
  String? uploadedImageUrl;
  bool isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    try {
      final accounts = await Api.getBankAccounts();
      setState(() {
        bankAccounts = accounts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bank accounts: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _referenceNoController.dispose();
    _bankNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (selectedBankAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipient bank account')),
      );
      return;
    }
    setState(() => currentStep = 2);
  }

  void _goBackToStep1() {
    setState(() => currentStep = 1);
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => selectedImage = File(pickedFile.path));
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (selectedImage == null) return;

    setState(() => isUploadingImage = true);

    try {
      final fileBytes = await selectedImage!.readAsBytes();
      final fileName = 'payment_proof_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('Uploading image: $fileName, size: ${fileBytes.length} bytes');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://saintodumo.com/appimages/upload.php'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Upload status: ${response.statusCode}');
      print('Upload response body: $responseBody');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(responseBody);
          final imageUrl = data['imageUrl'] ?? data['url'] ?? data['message'] ?? responseBody.trim();

          setState(() {
            uploadedImageUrl = imageUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment proof uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          setState(() {
            uploadedImageUrl = responseBody.trim();
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment proof uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        throw Exception('Upload failed with status ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUploadingImage = false);
      }
    }
  }

  void _removeImage() {
    setState(() {
      selectedImage = null;
      uploadedImageUrl = null;
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload payment proof image')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final transferDetails = {
        'reference_no': _referenceNoController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'bank_account_id': selectedBankAccountId,
        'payment_proof': uploadedImageUrl,
        'notes': _notesController.text.trim(),
      };

      print('Submitting transfer: $transferDetails');

      widget.onSubmit(transferDetails);
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Map<String, dynamic>? get selectedBankAccount {
    if (selectedBankAccountId == null) return null;
    try {
      return bankAccounts.firstWhere((b) => b['id'] == selectedBankAccountId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentStep == 1 ? 'Bank Transfer - Step 1' : 'Bank Transfer - Step 2',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currentStep == 1 
                    ? 'Select the account to transfer to' 
                    : 'Enter your transfer details',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // STEP 1: Select Recipient Account
              if (currentStep == 1) ...[
                isLoading
                    ? const SizedBox(
                        height: 200,
                        child: Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : bankAccounts.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'No bank accounts available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bankAccounts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final bank = bankAccounts[index];
                              final isSelected = selectedBankAccountId == bank['id'];
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() => selectedBankAccountId = bank['id']);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.account_balance,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bank['bank_name'] ?? 'Unknown Bank',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              bank['account_name'] ?? 'Unknown Account',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              bank['account_number'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: selectedBankAccountId == null ? null : _goToStep2,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue to Next Step'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ]
              
              // STEP 2: Fill Transfer Details
              else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show selected account summary
                      if (selectedBankAccount != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Transferring To:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedBankAccount!['bank_name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                selectedBankAccount!['account_name'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                selectedBankAccount!['account_number'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Reference Number
                      const Text(
                        'Your Transfer Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _referenceNoController,
                        decoration: InputDecoration(
                          labelText: 'Transaction Reference No',
                          hintText: 'e.g., TRF123456789',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.receipt_long_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Reference number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Bank Name (Sender's Bank)
                      TextFormField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          labelText: 'Your Bank Name',
                          hintText: 'e.g., GTBank, Access Bank, UBA',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.account_balance_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Your bank name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Notes (Optional)
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                          hintText: 'e.g., Any payment reference or details',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.note_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Payment Proof Upload
                      const Text(
                        'Payment Proof (Required)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (uploadedImageUrl == null)
                        GestureDetector(
                          onTap: isUploadingImage ? null : _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isUploadingImage ? AppColors.primary : Colors.grey[300]!,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              color: isUploadingImage
                                  ? AppColors.primary.withOpacity(0.05)
                                  : Colors.grey[50],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isUploadingImage)
                                  const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  Icon(
                                    Icons.upload_outlined,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  isUploadingImage ? 'Uploading...' : 'Tap to upload receipt',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isUploadingImage ? AppColors.primary : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'JPG, PNG (Max 5MB)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green[300]!),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.green[50],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Payment proof uploaded',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _removeImage,
                                    child: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              if (selectedImage != null) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    selectedImage!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                              if (uploadedImageUrl != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Uploaded URL: $uploadedImageUrl',
                                  style: const TextStyle(fontSize: 12, color: Colors.green),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          // Back Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _goBackToStep1,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Submit Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSubmitting ? null : _submitForm,
                              icon: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                isSubmitting ? 'Processing...' : 'Confirm',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
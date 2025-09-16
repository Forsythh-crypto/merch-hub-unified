import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/order.dart';
import '../services/order_service.dart';
import 'receipt_upload_screen.dart';

class ReservationFeePaymentScreen extends StatefulWidget {
  final Order order;
  final double totalAmount;

  const ReservationFeePaymentScreen({
    super.key,
    required this.order,
    required this.totalAmount,
  });

  @override
  State<ReservationFeePaymentScreen> createState() =>
      _ReservationFeePaymentScreenState();
}

class _ReservationFeePaymentScreenState
    extends State<ReservationFeePaymentScreen> {
  final bool _isLoading = false;

  double get _reservationFeeAmount {
    return widget.totalAmount * 0.35; // 35% reservation fee
  }

  // Path to your QR code image
  String get _qrCodeImagePath {
    return 'assets/qr_codes/gcash_qr.png'; // Change this to your QR code filename
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reservation Fee Payment',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Success Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Order Created Successfully!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Number:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.order.orderNumber,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservation Fee Payment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Product:',
                                style: TextStyle(fontFamily: 'Montserrat'),
                              ),
                              Expanded(
                                child: Text(
                                  widget.order.listing?.title ?? 'Unknown Product',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quantity:',
                                style: TextStyle(fontFamily: 'Montserrat'),
                              ),
                              Text(
                                '${widget.order.quantity}',
                                style: const TextStyle(fontFamily: 'Montserrat'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(fontFamily: 'Montserrat'),
                              ),
                              Text(
                                '₱${widget.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Reservation Fee (35%):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              Text(
                                '₱${_reservationFeeAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                  fontSize: 16,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // GCash QR Code Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00D4AA)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00D4AA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.qr_code,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'GCash QR Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00D4AA),
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Your QR Code Image
                          Container(
                            width: 280,
                            height: 320,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Your QR Code Image - Bigger Size
                                SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Image.asset(
                                    _qrCodeImagePath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2,
                                            size: 120,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'QR Code Not Found',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                          Text(
                                            'Please add your QR code image',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'GCash QR Code',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₱${_reservationFeeAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF00D4AA),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Payment Instructions
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Instructions:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '1. Open your GCash app',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const Text(
                                  '2. Tap "Scan QR"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const Text(
                                  '3. Scan the QR code above',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                Text(
                                  '4. Enter the exact amount: ₱${_reservationFeeAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const Text(
                                  '5. Complete the payment',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const Text(
                                  '6. Take a screenshot of the receipt',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const Text(
                                  '7. Upload the receipt below',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _proceedToReceiptUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: const Text(
                        'Upload Payment Receipt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _uploadLater,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.schedule),
                    label: const Text(
                        'Upload Receipt Later',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Important Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Important: Your order will remain pending until the reservation fee is paid and confirmed by our admin.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToReceiptUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptUploadScreen(order: widget.order),
      ),
    );
  }

  void _uploadLater() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }
}

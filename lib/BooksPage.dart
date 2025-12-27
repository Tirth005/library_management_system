import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

/// A page that allows users to scan book barcodes to checkout or return books.
///
/// Uses the device camera via [MobileScanner] to read ISBNs/barcodes.
/// Handles the logic for:
/// - Requesting camera permissions.
/// - Querying Firestore for book availability.
/// - Creating borrow/return transactions.
class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool hasPermission = false;
  bool isProcessing = false;
  String? scannedBarcode;
  Map<String, dynamic>? bookData;

  /// Stores the ID of the active transaction if the current user has borrowed this book.
  String?
  activeTransactionId; // Store transaction ID if user has borrowed this book

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeCamera());
  }

  Future<void> _initializeCamera() async {
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      if (!mounted) return;

      if (status.isGranted) {
        setState(() => hasPermission = true);
        try {
          await cameraController.start();
        } catch (_) {}
      } else if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      } else {
        Future.delayed(
          const Duration(milliseconds: 300),
          () => _initializeCamera(),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission plugin not available. Please stop and restart the app (full restart).',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      try {
        await cameraController.start();
        if (mounted) setState(() => hasPermission = true);
      } catch (_) {}
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission error: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Camera init error: $e')));
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera access is required to scan book barcodes. Please enable it in system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() {
      isProcessing = true;
      scannedBarcode = raw;
    });

    try {
      await cameraController.stop();
    } catch (_) {}

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please login first')));
        }
        return;
      }

      // Fetch book details
      final bookDoc = await FirebaseFirestore.instance
          .collection('books')
          .doc(raw)
          .get();

      if (!mounted) return;

      if (!bookDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Book not found')));
        }
        return;
      }

      bookData = bookDoc.data();

      // Check if THIS user has an active transaction for this book
      final userTransactionQuery = await FirebaseFirestore.instance
          .collection('bookTransactions')
          .where('userId', isEqualTo: uid)
          .where('bookId', isEqualTo: raw)
          .where('status', isEqualTo: 'borrowed')
          .limit(1)
          .get();

      if (userTransactionQuery.docs.isNotEmpty) {
        // User has already borrowed this book
        activeTransactionId = userTransactionQuery.docs.first.id;
      } else {
        activeTransactionId = null;
      }

      // Check if ANYONE has borrowed this book (to determine actual availability)
      final anyTransactionQuery = await FirebaseFirestore.instance
          .collection('bookTransactions')
          .where('bookId', isEqualTo: raw)
          .where('status', isEqualTo: 'borrowed')
          .limit(1)
          .get();

      // Override book availability based on actual borrowed status
      if (bookData != null) {
        bookData!['available'] = anyTransactionQuery.docs.isEmpty;
      }

      await _showBookDialog();
    } on FirebaseException catch (fe) {
      if (fe.code == 'permission-denied') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Firestore permission denied. Check rules or authentication.',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Firestore error: ${fe.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching book data')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => isProcessing = false);
      try {
        await cameraController.start();
      } catch (_) {}
    }
  }

  Future<void> _borrowBook(String bookId, Map<String, dynamic> bookData) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Get full user details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userData = userDoc.data();
      if (userData == null) {
        throw 'User data not found';
      }

      final now = Timestamp.now();
      final dueDate = Timestamp.fromDate(
        now.toDate().add(const Duration(days: 14)),
      );

      // Create transaction with expanded details
      await FirebaseFirestore.instance.collection('bookTransactions').add({
        // Book details
        'bookId': bookId,
        'bookName': bookData['title'] ?? '',
        'title': bookData['title'] ?? '', // Added for homepage compatibility
        'author': bookData['author'] ?? '',
        'genre': bookData['genre'] ?? '',
        'isbn': scannedBarcode,

        // User details
        'userId': uid,
        'userName': userData['fullName'] ?? '',
        'userEmail': userData['email'] ?? '',
        'userEnrollment': userData['enrollment'] ?? '',
        'userDepartment': userData['department'] ?? '',

        // Transaction details
        'issueDate': now,
        'dueDate': dueDate,
        'status': 'borrowed',
        'transactionType': 'borrow',
      });

      // Update book availability
      await FirebaseFirestore.instance.collection('books').doc(bookId).update({
        'available': false,
        'lastBorrowed': now,
        'lastBorrowedBy': uid,
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book borrowed successfully! Due in 14 days'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to borrow book: $e')));
      }
    }
  }

  Future<void> _returnBook(String transactionId, String bookId) async {
    try {
      final now = Timestamp.now();

      // Update transaction status
      await FirebaseFirestore.instance
          .collection('bookTransactions')
          .doc(transactionId)
          .update({'status': 'returned', 'returnDate': now});

      // Update book availability
      await FirebaseFirestore.instance.collection('books').doc(bookId).update({
        'available': true,
        'lastReturned': now,
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book returned successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to return book: $e')));
      }
    }
  }

  Future<void> _showBookDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        final bool userHasBorrowed = activeTransactionId != null;
        final bool bookAvailable = bookData?['available'] ?? false;

        return AlertDialog(
          title: const Text('Book Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title: ${bookData?['title'] ?? '-'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Author: ${bookData?['author'] ?? '-'}'),
              Text('Genre: ${bookData?['genre'] ?? '-'}'),
              Text('ISBN: ${scannedBarcode ?? '-'}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: userHasBorrowed
                      ? Colors.orange.shade50
                      : (bookAvailable
                            ? Colors.green.shade50
                            : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      userHasBorrowed
                          ? Icons.library_books
                          : (bookAvailable ? Icons.check_circle : Icons.cancel),
                      size: 16,
                      color: userHasBorrowed
                          ? Colors.orange
                          : (bookAvailable ? Colors.green : Colors.red),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userHasBorrowed
                          ? 'You have borrowed this book'
                          : (bookAvailable ? 'Available' : 'Not Available'),
                      style: TextStyle(
                        color: userHasBorrowed
                            ? Colors.orange.shade900
                            : (bookAvailable
                                  ? Colors.green.shade900
                                  : Colors.red.shade900),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (userHasBorrowed)
              ElevatedButton(
                onPressed: () =>
                    _returnBook(activeTransactionId!, scannedBarcode!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Return Book'),
              )
            else if (bookAvailable)
              ElevatedButton(
                onPressed: () => _borrowBook(scannedBarcode!, bookData!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Borrow Book'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Scan Book', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
            color: Colors.white,
          ),
        ],
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            Container(
              height: 100,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPermission
                  ? MobileScanner(
                      controller: cameraController,
                      onDetect: onDetect,
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Text(
                        'Requesting camera access...',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isProcessing ? 'Processing...' : 'Align barcode within frame',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            if (scannedBarcode != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Last: $scannedBarcode',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

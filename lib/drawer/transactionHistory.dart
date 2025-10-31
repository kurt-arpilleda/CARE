import 'package:flutter/material.dart';
import 'package:care/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _loading = true;
  Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _loadTransactionHistory();
  }

  Future<void> _loadTransactionHistory() async {
    try {
      final response = await _apiService.fetchTransactionHistory();
      if (response['success'] == true) {
        setState(() {
          _transactions = List<dynamic>.from(response['transactions'] ?? []);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load transaction history'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading transaction history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(String dateString) {
    try {
      DateTime messageDate = DateTime.parse(dateString);
      Duration diff = DateTime.now().difference(messageDate);

      if (diff.inSeconds < 60) {
        return "just now";
      } else if (diff.inMinutes < 60) {
        return "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        return "${diff.inHours}h ago";
      } else if (diff.inDays == 1) {
        return "yesterday";
      } else if (diff.inDays < 7) {
        return "${diff.inDays}d ago";
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return "${weeks}w ago";
      } else {
        return "${messageDate.month}/${messageDate.day}/${messageDate.year}";
      }
    } catch (e) {
      return 'just now';
    }
  }

  Future<Uint8List?> _getProfileImage(String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) {
      final ByteData data = await rootBundle.load('assets/images/profilePlaceHolder.png');
      return data.buffer.asUint8List();
    }
    try {
      final String imageUrl = photoUrl.contains('http')
          ? photoUrl
          : '${ApiService.apiUrl}profilePicture/$photoUrl';
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}
    final ByteData data = await rootBundle.load('assets/images/profilePlaceHolder.png');
    return data.buffer.asUint8List();
  }

  String _getInitials(String fullName) {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0].length >= 2 ? names[0].substring(0, 2).toUpperCase() : names[0].toUpperCase();
    }
    return '??';
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction, int index) {
    final type = transaction['type'];
    final otherPartyName = transaction['otherPartyName'] ?? 'Unknown';
    final shopName = transaction['shopName'] ?? 'Unknown Shop';
    final timestamp = transaction['timestamp'] ?? '';
    final photoUrl = transaction['otherPartyPhotoUrl'];
    final cacheKey = photoUrl ?? 'default_${transaction['shopId']}_$index';

    final borderColor = type == 'customer' ? Colors.orange : Colors.blue;
    final roleText = type == 'customer' ? 'As a Customer' : 'As Shop Owner';

    Widget buildImage(Uint8List? imageBytes) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          color: Colors.grey[200],
        ),
        child: ClipOval(
          child: imageBytes != null
              ? Image.memory(imageBytes, fit: BoxFit.cover)
              : Center(
            child: Text(
              _getInitials(otherPartyName),
              style: TextStyle(
                color: borderColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _getProfileImage(photoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _imageCache[cacheKey] = snapshot.data!;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
          ),
          child: ListTile(
            leading: buildImage(snapshot.data),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherPartyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  shopName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                roleText,
                style: TextStyle(
                  fontSize: 12,
                  color: borderColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing: Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3D63).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 64,
              color: const Color(0xFF1A3D63).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No transaction history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your accepted service requests will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A3D63),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A3D63),
        ),
      )
          : _transactions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadTransactionHistory,
        color: const Color(0xFF1A3D63),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionItem(
              Map<String, dynamic>.from(_transactions[index]),
              index,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
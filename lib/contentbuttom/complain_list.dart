import 'package:flutter/material.dart';
import '../content/complaint_form.dart';


class ComplaintList extends StatefulWidget {
  const ComplaintList({super.key});

  @override
  State<ComplaintList> createState() => _ComplaintListState();
}

class _ComplaintListState extends State<ComplaintList> {
  String selectedFilter = 'Semua status';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2A5E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
                child: const Center(
                  child: Text(
                    'DAFTAR PENGADUAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Filter Tabs
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterTab('Semua status', true),
                      const SizedBox(width: 8),
                      _buildFilterTab('Menunggu', false),
                      const SizedBox(width: 8),
                      _buildFilterTab('Diproses', false),
                    ],
                  ),
                ),
              ),

              // Complaint Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildComplaintCard(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComplaintForm()),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A5E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar dihapus — dihandle MainScaffold
    );
  }

  Widget _buildFilterTab(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2A5E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFF1E2A5E), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1E2A5E),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2A5E), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kode pengaduan',
                style: TextStyle(color: Color(0xFF1E2A5E), fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Text(
                'Status',
                style: TextStyle(color: Color(0xFF1E2A5E), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '(Deskripsi pengaduan)',
              style: TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kategori pengaduan',
                style: TextStyle(color: Color(0xFF1E2A5E), fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A5E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Detail',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
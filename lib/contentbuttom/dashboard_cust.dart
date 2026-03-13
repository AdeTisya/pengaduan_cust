import 'package:flutter/material.dart';

class DashboardCust extends StatelessWidget {
  const DashboardCust({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Background biru dengan logo & logout
              Container(
                width: double.infinity,
                color: const Color(0xFF1E2A5E),
                padding: const EdgeInsets.fromLTRB(47, 50, 47, 27),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Transform.translate(
                          offset: const Offset(160, -70),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(255, 55, 66, 111)
                                      .withValues(alpha: 0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_kominfo.png',
                              width: 84,
                              height: 84,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Container(
                          width: 84,
                          height: 250,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2A5E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E2A5E),
                                offset: const Offset(0, 4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                              const Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Fix: Transform.translate untuk efek overlap (negative margin tidak support di Flutter Web)
              Transform.translate(
                offset: const Offset(0, -120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(27, 0, 27, 0),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 8),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            offset: const Offset(0, -2),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.description,
                                        size: 30, color: Colors.black),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Total Pengaduan',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 13),
                                const Text(
                                  '0',
                                  style: TextStyle(
                                    color: Color(0xFF0059FF),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Pengaduan Terdaftar',
                                  style: TextStyle(
                                    color: Color(0xFF464646),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 35),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatusColumn(
                                      count: '0',
                                      label: 'Menunggu',
                                      color: const Color(0xFFDDC000),
                                    ),
                                    _buildStatusColumn(
                                      count: '0',
                                      label: 'Diproses',
                                      color: const Color(0xFF0059FF),
                                    ),
                                    _buildStatusColumn(
                                      count: '0',
                                      label: 'Selesai',
                                      color: const Color(0xFF328E6E),
                                    ),
                                    _buildStatusColumn(
                                      count: '0',
                                      label: 'Ditolak',
                                      color: const Color(0xFFFF0000),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),

                          // Bottom navigation section
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E2A5E),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: () {},
                                  borderRadius: BorderRadius.circular(8),
                                  splashColor:
                                      Colors.white.withValues(alpha: 0.3),
                                  highlightColor:
                                      Colors.white.withValues(alpha: 0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.history,
                                            color: Colors.white, size: 24),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'History pengaduan',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                    width: 2,
                                    height: 30,
                                    color: Colors.white),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pushNamed('/history_rating');
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  splashColor:
                                      Colors.white.withValues(alpha: 0.3),
                                  highlightColor:
                                      Colors.white.withValues(alpha: 0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.white, size: 24),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'History Rating',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // SizedBox dikurangi 60 karena Transform.translate menggeser ke atas 60px
              const SizedBox(height: 110),

              // Graph section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(-4, -4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart, size: 24, color: Colors.black),
                        const SizedBox(width: 8),
                        const Text(
                          'Graph Pengaduan Internet',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Graph akan ditampilkan di sini',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusColumn({
    required String count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF464646),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
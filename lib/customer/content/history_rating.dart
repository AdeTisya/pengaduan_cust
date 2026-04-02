import 'package:flutter/material.dart';

class HistoryRating extends StatelessWidget {
  const HistoryRating({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
          ),
          child: Column(
            children: [
              // Blue header section
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2A5E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(25, 50, 25, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tombol back
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        margin: const EdgeInsets.only(top: 15),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'History Rating',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 36,
                            fontFamily: 'Gidugu',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content card
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 369),
                margin: const EdgeInsets.only(top: 51),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background gray container (shadow effect)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 22),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC5C0C0),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: const SizedBox(height: 100),
                    ),

                    // Main content container
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xF21E2A5E),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.fromLTRB(21, 13, 21, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with category and date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kategori Pengaduan',
                                style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 12,
                                  fontFamily: 'Inclusive Sans',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const Text(
                                '12.06.2023',
                                style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 12,
                                  fontFamily: 'Inclusive Sans',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Rating and service improvement section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      5,
                                      (index) => const Icon(
                                        Icons.star,
                                        color: Colors.yellow,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'perbaikan layanan :',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 11,
                                      fontFamily: 'Inclusive Sans',
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 9),
                              const Expanded(
                                child: Text(
                                  'opsion 1 option 2',
                                  style: TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 12,
                                    fontFamily: 'Inclusive Sans',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Feedback dari teknisi (dipindah ke dalam card, bukan Positioned)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Feedback dari teknisi',
                                style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 12,
                                  fontFamily: 'Inclusive Sans',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                color: Colors.white24,
                                child: const Icon(
                                  Icons.feedback,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
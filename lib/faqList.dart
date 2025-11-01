import 'package:flutter/material.dart';

class FaqListScreen extends StatefulWidget {
  const FaqListScreen({Key? key}) : super(key: key);

  @override
  _FaqListScreenState createState() => _FaqListScreenState();
}

class _FaqListScreenState extends State<FaqListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FaqItem> _evFaqs = [
    FaqItem(
      question: 'Why won\'t my electric vehicle start?',
      answer: 'Possible causes include:\n\n• Low or dead main battery – Check the charge level or try plugging it in.\n• 12V auxiliary battery issue – Even EVs need a small battery to power electronics.\n• Faulty power switch or software glitch – Try restarting or resetting the system.\n• Charging port malfunction – If charging was interrupted, the system may not start.',
    ),
    FaqItem(
      question: 'Why is my EV not charging?',
      answer: '• The charging cable may be damaged or not properly connected.\n• Faulty wall charger or charging station.\n• Battery management system (BMS) issue.\n• Temperature protection – Batteries won\'t charge if too hot or cold.\n\nTry a different charger, and if it still fails, request service through CARES.',
    ),
    FaqItem(
      question: 'What does it mean when a warning light turns on?',
      answer: 'Common EV warning lights include:\n\n• Battery Warning – Low state of charge or charging problem.\n• Powertrain Warning – Electric motor or inverter issue.\n• Service Vehicle Soon – Software or sensor malfunction.',
    ),
    FaqItem(
      question: 'Why is my EV range decreasing faster than usual?',
      answer: '• Driving at high speeds or using air conditioning/heating drains battery faster.\n• Old battery cells may reduce efficiency.\n• Tire pressure or alignment issues affect energy use.',
    ),
    FaqItem(
      question: 'Why is my EV making unusual sounds (whining, clunking, etc.)?',
      answer: '• Whining or humming – Common in EVs due to electric motor, but loud or sudden noises may mean bearing or gearbox issues.\n• Clunking or rattling – Possible suspension or mount problem.',
    ),
    FaqItem(
      question: 'Why is my EV overheating or showing a temperature warning?',
      answer: '• Cooling system failure (yes, EVs still need coolant).\n• Battery thermal management issue.\n• Blocked air vents around the battery or inverter.',
    ),
    FaqItem(
      question: 'Why is my EV charging slowly?',
      answer: '• Using a lower-rated charger (Level 1).\n• High ambient temperature.\n• Battery near full capacity (slows down automatically).\n• Degraded battery performance.',
    ),
    FaqItem(
      question: 'Why is my EV producing a burning smell or smoke?',
      answer: '• Electrical short circuit or overheating component.\n• Burning insulation smell – May indicate wire damage.',
    ),
    FaqItem(
      question: 'Why won\'t my EV move even though it\'s on?',
      answer: '• Parking brake still engaged.\n• Drive mode not selected properly.\n• Traction system fault.',
    ),
    FaqItem(
      question: 'Why is my EV vibrating while driving?',
      answer: '• Motor mount wear.\n• Inverter or power delivery issue.\n• Uneven tire wear.',
    ),
  ];

  final List<FaqItem> _gasolineFaqs = [
    FaqItem(
      question: 'Why won\'t my car start?',
      answer: 'Common reasons include:\n\n• Dead battery or corroded terminals.\n• Empty fuel tank.\n• Faulty starter motor or ignition system.\n• Bad spark plugs or fuel pump.',
    ),
    FaqItem(
      question: 'What does it mean when a warning light turns on (Check Engine, Oil, etc.)?',
      answer: '• Check Engine Light: Emission or sensor problem.\n• Oil Light: Low oil level or pressure.\n• Battery Light: Alternator or charging problem.\n• Temperature Light: Engine overheating.',
    ),
    FaqItem(
      question: 'Why is my car overheating?',
      answer: 'Caused by:\n\n• Low coolant or coolant leak.\n• Broken radiator fan or thermostat.\n• Blocked radiator.',
    ),
    FaqItem(
      question: 'Why does my steering wheel shake while driving or braking?',
      answer: '• Tire imbalance or misalignment.\n• Warped brake rotors.\n• Worn suspension components.',
    ),
    FaqItem(
      question: 'Why is my car making strange noises (squealing, grinding, knocking)?',
      answer: '• Squealing: Worn belts or brake pads.\n• Grinding: Bad brakes or transmission issue.\n• Knocking: Engine misfire or low-quality fuel.',
    ),
    FaqItem(
      question: 'Why does my car pull to one side while driving?',
      answer: '• Wheel misalignment.\n• Uneven tire pressure or wear.\n• Brake caliper sticking.',
    ),
    FaqItem(
      question: 'Why is my brake pedal soft or hard to press?',
      answer: '• Soft: Air in brake lines or fluid leak.\n• Hard: Vacuum assist issue or blocked brake line.',
    ),
    FaqItem(
      question: 'Why is my car leaking fluid?',
      answer: 'Identify by color:\n\n• Brown/black: Oil.\n• Green/orange: Coolant.\n• Red: Transmission fluid.\n• Clear: Air conditioner condensation (harmless).',
    ),
    FaqItem(
      question: 'Why is smoke coming from under the hood or exhaust?',
      answer: '• White smoke: Coolant leak.\n• Blue smoke: Burning oil.\n• Black smoke: Too much fuel or dirty air filter.',
    ),
    FaqItem(
      question: 'Why is my car vibrating at idle or low speeds?',
      answer: '• Dirty spark plugs or air filter.\n• Faulty engine mount.\n• Fuel system issues.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<FaqItem> _getFilteredFaqs(List<FaqItem> faqs) {
    if (_searchQuery.isEmpty) return faqs;
    return faqs.where((faq) =>
    faq.question.toLowerCase().contains(_searchQuery) ||
        faq.answer.toLowerCase().contains(_searchQuery)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D63),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search FAQs...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: 'Electric Vehicles'),
                  Tab(text: 'Gasoline Vehicles'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqList(_getFilteredFaqs(_evFaqs)),
          _buildFaqList(_getFilteredFaqs(_gasolineFaqs)),
        ],
      ),
    );
  }

  Widget _buildFaqList(List<FaqItem> faqs) {
    if (faqs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No FAQs found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return _buildFaqCard(faqs[index], index);
      },
    );
  }

  Widget _buildFaqCard(FaqItem faq, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A3D63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF1A3D63),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3D63),
            ),
          ),
          iconColor: const Color(0xFF1A3D63),
          collapsedIconColor: Colors.grey,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAFD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                faq.answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}
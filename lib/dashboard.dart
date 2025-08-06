import 'package:flutter/material.dart';
import 'drawer/drawerNavigation.dart';
import 'auto_update.dart';
import 'googleMap.dart';
import 'options.dart';
import 'notification/notifList.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController _searchController = TextEditingController();
  List<bool> _selectedServices = List.generate(serviceOptions.length, (index) => false);
  bool _selectAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<String> filteredServices = serviceOptions
                .where((service) =>
                service.toLowerCase().contains(_searchController.text.toLowerCase()))
                .toList();

            return AlertDialog(
              title: Text('Select Services'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: (value) {
                          setState(() {
                            _selectAll = value!;
                            for (int i = 0; i < _selectedServices.length; i++) {
                              _selectedServices[i] = _selectAll;
                            }
                          });
                        },
                      ),
                      Text('Select All'),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            for (int i = 0; i < _selectedServices.length; i++) {
                              _selectedServices[i] = false;
                            }
                            _selectAll = false;
                          });
                        },
                        child: Text('Clear All'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: filteredServices.map((service) {
                          int index = serviceOptions.indexOf(service);
                          return CheckboxListTile(
                            title: Text(service),
                            value: _selectedServices[index],
                            onChanged: (value) {
                              setState(() {
                                _selectedServices[index] = value!;
                                _selectAll = _selectedServices.every((val) => val);
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel')),
                TextButton(
                    onPressed: () {
                      List<String> selected = [];
                      for (int i = 0; i < _selectedServices.length; i++) {
                        if (_selectedServices[i]) {
                          selected.add(serviceOptions[i]);
                        }
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected: ${selected.length} services')),
                      );
                    },
                    child: Text('Apply')),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AutoUpdate.checkForUpdate(context);
    });
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DashboardDrawer(),
      backgroundColor: const Color(0xFFF6FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D63),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer()),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CARES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Find repair shop's near you",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationList()),
                    );
                  },
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Center(
                      child: Text(
                        '10',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1A3D63),
            child: GestureDetector(
              onTap: _showServiceDialog,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Search repair shops...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Icon(
                      Icons.tune,
                      color: const Color(0xFF1A3D63),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: const GoogleMapWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

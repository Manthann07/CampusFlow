import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/faculty_model.dart';
import '../theme/app_theme.dart';
import 'book_appointment_screen.dart';

class FacultyListScreen extends StatefulWidget {
  @override
  _FacultyListScreenState createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends State<FacultyListScreen> {
  List<Faculty> allFaculty = [];
  List<Faculty> filteredFaculty = [];
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    // Small delay for clean state
    await Future.delayed(Duration(milliseconds: 300));
    
    try {
      final data = await ApiService.getFaculty();
      if (mounted) {
        setState(() {
          allFaculty = data;
          filteredFaculty = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Could not connect to database. Make sure your server is running.";
          isLoading = false;
        });
      }
    }
  }

  void _filterList(String query) {
    setState(() {
      filteredFaculty = allFaculty
          .where((f) =>
              f.name.toLowerCase().contains(query.toLowerCase()) ||
              f.department.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Real Faculty Directory"),
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterList,
                  decoration: InputDecoration(
                    hintText: "Search faculty name...",
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? _buildErrorView()
                      : filteredFaculty.isEmpty
                          ? _buildEmptyView()
                          : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text("No faculty found in database", style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Add users with role 'Faculty' in your MongoDB.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: Colors.red[300], size: 70),
            SizedBox(height: 16),
            Text("Connection Failed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            ElevatedButton(onPressed: _fetchData, child: Text("Retry Connection")),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredFaculty.length,
      itemBuilder: (context, index) {
        final faculty = filteredFaculty[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: Colors.black12,
          child: ExpansionTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                (faculty.name.isNotEmpty ? faculty.name[0] : 'F').toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            title: Text(faculty.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            subtitle: Text(faculty.department, style: TextStyle(color: Colors.grey[600])),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _infoRow(Icons.badge_outlined, "ID: ${faculty.idNumber}"),
                    _infoRow(Icons.email_outlined, faculty.email),
                    _infoRow(Icons.phone_outlined, faculty.phone),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const BookAppointmentScreen()));
                            },
                            icon: Icon(Icons.calendar_month, size: 18),
                            label: Text("Book Now"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () => launchUrl(Uri.parse("tel:${faculty.phone}")),
                          icon: Icon(Icons.call),
                          style: IconButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor.withOpacity(0.7)),
          SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}

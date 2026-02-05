import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class HomeCalendarCard extends StatefulWidget {
  final List<Map<String, dynamic>> leaveRequests;
  final List<Map<String, dynamic>> publicHolidays; // 🔴 1. NEW PARAMETER

  const HomeCalendarCard({
    super.key, 
    required this.leaveRequests,
    required this.publicHolidays, // 🔴 Required
  });

  @override
  State<HomeCalendarCard> createState() => _HomeCalendarCardState();
}

class _HomeCalendarCardState extends State<HomeCalendarCard> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Stores both Leave Requests AND Holidays
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _processEvents();
  }

  @override
  void didUpdateWidget(covariant HomeCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _processEvents();
  }

  void _processEvents() {
    _events = {};

    // --- A. PROCESS LEAVE REQUESTS ---
    for (var request in widget.leaveRequests) {
      if (request['start_date'] == null || request['end_date'] == null) continue;
      
      String status = (request['status'] ?? 'Pending').toString();
      if (status == 'Cancelled' || status == 'Rejected') continue; 

      DateTime start = DateTime.parse(request['start_date'].toString()).toLocal();
      DateTime end = DateTime.parse(request['end_date'].toString()).toLocal();

      DateTime current = start;
      while (current.isBefore(end) || isSameDay(current, end)) {
        DateTime dateKey = DateTime(current.year, current.month, current.day);
        
        if (_events[dateKey] == null) _events[dateKey] = [];
        
        // Add Leave Request with a flag
        var event = Map<String, dynamic>.from(request);
        event['isHoliday'] = false; 
        _events[dateKey]!.add(event);
        
        current = current.add(const Duration(days: 1));
      }
    }

    // --- B. 🔴 PROCESS PUBLIC HOLIDAYS ---
    for (var holiday in widget.publicHolidays) {
      if (holiday['holiday_date'] == null) continue;

      try {
        DateTime date = DateTime.parse(holiday['holiday_date'].toString()).toLocal();
        DateTime dateKey = DateTime(date.year, date.month, date.day);

        if (_events[dateKey] == null) _events[dateKey] = [];

        // Add Holiday with a flag
        _events[dateKey]!.add({
          'isHoliday': true,
          'name': holiday['name'] ?? 'Public Holiday',
          'description': holiday['description'] ?? '',
          'status': 'Holiday' 
        });
      } catch (e) {
        print("Error parsing holiday date: $e");
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Schedule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              currentDay: DateTime.now(),
              daysOfWeekHeight: 25,
              
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                leftChevronIcon: Icon(Icons.chevron_left, size: 20),
                rightChevronIcon: Icon(Icons.chevron_right, size: 20),
              ),
              calendarStyle: const CalendarStyle(
                cellMargin: EdgeInsets.all(4),
                todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.blueGrey, shape: BoxShape.circle),
              ),
              
              eventLoader: _getEventsForDay,
              
              // 🔴 UPDATED MARKER BUILDER
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  final requests = events as List<Map<String, dynamic>>;
                  
                  // Color Logic: Red (Holiday) > Green (Approved) > Orange (Pending)
                  Color color = Colors.grey;
                  
                  bool isHoliday = requests.any((r) => r['isHoliday'] == true);
                  bool hasApproved = requests.any((r) => r['status'] == 'Approved');
                  bool hasPending = requests.any((r) => r['status'] == 'Pending');
                  
                  if (isHoliday) color = Colors.redAccent; // Holiday gets Red
                  else if (hasApproved) color = Colors.green;
                  else if (hasPending) color = Colors.orange;
                  else return null;

                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  );
                },
              ),
              
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                
                final events = _getEventsForDay(selectedDay);
                if (events.isNotEmpty) {
                  _showDayDetails(context, selectedDay, events);
                }
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(BuildContext context, DateTime date, List<Map<String, dynamic>> events) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, d MMMM y').format(date),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              
              ...events.map((req) {
                
                // 🔴 1. HANDLE HOLIDAY UI
                if (req['isHoliday'] == true) {
                  return Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50], // Light Red
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.celebration, color: Colors.red, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req['description'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Text("Public Holiday", style: TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 🔵 2. HANDLE LEAVE UI (Existing)
                final status = req['status'] ?? 'Pending';
                final isApproved = status == 'Approved';
                
                if (status == 'Rejected') return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isApproved ? Colors.green[200]! : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isApproved ? Icons.check : Icons.access_time,
                          color: isApproved ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req['leave_type'] ?? 'Leave',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (req['reason'] != null && req['reason'].toString().isNotEmpty)
                              Text(
                                req['reason'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isApproved ? Colors.green[700] : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class HomeCalendarCard extends StatefulWidget {
  final List<Map<String, dynamic>> leaveRequests;

  const HomeCalendarCard({super.key, required this.leaveRequests});

  @override
  State<HomeCalendarCard> createState() => _HomeCalendarCardState();
}

class _HomeCalendarCardState extends State<HomeCalendarCard> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // CHANGED: Now storing the full Request Object, not just a String
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
    for (var request in widget.leaveRequests) {
      if (request['start_date'] == null || request['end_date'] == null) continue;
      
      // 👇 THIS IS THE NEW FILTER
      String status = (request['status'] ?? 'Pending').toString();
      
      // If it's Cancelled (or Rejected), skip it immediately.
      // It won't get added to the calendar, so no dots will appear.
      if (status == 'Cancelled' || status == 'Rejected') continue; 

      // ... The rest of the logic stays the same ...
      DateTime start = DateTime.parse(request['start_date'].toString()).toLocal();
      DateTime end = DateTime.parse(request['end_date'].toString()).toLocal();

      DateTime current = start;
      while (current.isBefore(end) || isSameDay(current, end)) {
        DateTime dateKey = DateTime(current.year, current.month, current.day);
        
        if (_events[dateKey] == null) {
          _events[dateKey] = [];
        }
        _events[dateKey]!.add(request);
        
        current = current.add(const Duration(days: 1));
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
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blueGrey,
                  shape: BoxShape.circle,
                ),
              ),
              
              eventLoader: _getEventsForDay,
              
              // 1. MARKER LOGIC (Updated for Map objects)
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  // Cast events to List of Maps
                  final requests = events as List<Map<String, dynamic>>;
                  
                  // Prioritize colors: Green (Approved) > Orange (Pending)
                  Color color = Colors.grey;
                  bool hasApproved = requests.any((r) => r['status'] == 'Approved');
                  bool hasPending = requests.any((r) => r['status'] == 'Pending');
                  
                  if (hasApproved) color = Colors.green;
                  else if (hasPending) color = Colors.orange;
                  else return null; // Don't show rejected

                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  );
                },
              ),
              
              // 2. INTERACTION LOGIC (Show Bottom Sheet)
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

  // 👇 THE POPUP (Bottom Sheet)
  void _showDayDetails(BuildContext context, DateTime date, List<Map<String, dynamic>> requests) {
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
              // Title Date
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, d MMMM y').format(date),
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              
              // List of requests for that day
              ...requests.map((req) {
                final status = req['status'] ?? 'Pending';
                final isApproved = status == 'Approved';
                
                // Only show Approved or Pending (Hide Rejected)
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
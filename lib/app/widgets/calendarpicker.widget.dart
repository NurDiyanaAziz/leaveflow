import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class CalendarPicker extends StatelessWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool isMedicalLeave;
  final List<DateTime> holidays; 
  final Function(DateTime start, DateTime end) onSelectionChanged;
  final DateTime? minDate; // ✅ This fixes your error

  const CalendarPicker({
    super.key,
    required this.onSelectionChanged,
    required this.isMedicalLeave,
    required this.holidays, 
    this.initialStartDate,
    this.initialEndDate,
    this.minDate, // ✅ Required for the controller to pass the limit
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450, // Increased height slightly for better visibility
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          
          // Header Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMedicalLeave ? "Medical Leave (Past Allowed)" : "Select Dates",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (isMedicalLeave)
                const Icon(Icons.local_hospital, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(height: 10),

          // Calendar
          Expanded(
            child: SfDateRangePicker(
              view: DateRangePickerView.month,
              selectionMode: DateRangePickerSelectionMode.range,
              
              // 1. LIMITS
              minDate: minDate,
              maxDate: isMedicalLeave ? DateTime.now() : DateTime(2030),
              
              initialSelectedRange: (initialStartDate != null) 
                  ? PickerDateRange(initialStartDate, initialEndDate) 
                  : null,

              // 2. STYLING
              headerStyle: const DateRangePickerHeaderStyle(
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                backgroundColor: Colors.white,
              ),
              monthViewSettings: const DateRangePickerMonthViewSettings(
                firstDayOfWeek: 1, // Monday start
                weekendDays: [6, 7],
                enableSwipeSelection: true,
              ),
              monthCellStyle: const DateRangePickerMonthCellStyle(
                weekendTextStyle: TextStyle(color: Colors.redAccent),
                disabledDatesTextStyle: TextStyle(color: Colors.grey),
              ),
              
              // 3. LOGIC TO BLOCK DATES
              selectableDayPredicate: (DateTime date) {
                // Block Weekends
                if (date.weekday == 6 || date.weekday == 7) return false;

                // Block DB Holidays
                for (var h in holidays) {
                  if (date.year == h.year && date.month == h.month && date.day == h.day) {
                    return false; // Grey out if matches DB date
                  }
                }
                return true;
              },

              onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                if (args.value is PickerDateRange) {
                  final DateTime? start = args.value.startDate;
                  final DateTime? end = args.value.endDate;
                  if (start != null) {
                    onSelectionChanged(start, end ?? start);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
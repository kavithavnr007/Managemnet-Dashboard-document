class EmployeeProductivityFilter {
  int? id;
  String? selectedManagerOrEmployee;
  bool? isWeekly;
  bool? isEmployee;
  int? selectedYear;
  int? selectedMonth;
  DateTime? selectedWeek;

  employeeProductivityFilterMap(){
    var mapping = <String, dynamic>{};
    mapping['id'] = id;
    mapping['selectedManagerOrEmployee'] = selectedManagerOrEmployee!;
    mapping['isWeekly'] = isWeekly! ? 1 : 0;
    mapping['isEmployee'] = isEmployee! ? 1 : 0;
    mapping['selectedYear'] = selectedYear!;
    mapping['selectedMonth'] = selectedMonth!;
    mapping['selectedDateOrWeek'] = selectedWeek!.toIso8601String()!;

    return mapping;
  }
}
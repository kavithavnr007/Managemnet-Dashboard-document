import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:heatmap/filter.dart';
import 'package:heatmap/heatmap.dart';
import 'package:heatmap/projectAllocation.dart';
import 'package:heatmap/repository.dart';
import 'package:intl/intl.dart';
import 'package:heatmap/networking.dart';
import 'apiService.dart';
import 'db_service.dart';
import 'model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heat Map Grid',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isWeekly = false;
  bool isEmployee = true;
  bool isEnabled = false;
  DateTime? _currentWeek;
  String selectedManager = '';
  List<Map<String, dynamic>> savedFilters = [];
  List<dynamic> sample = [];
  List<String> managers = [];
  var _EmployeeProductivityFilterService = EmployeeProductivityFilterService();

  final ApiService apiService = ApiService('https://sandstar-dev-api.azurewebsites.net/api');

  Future<void> fetch_manager_Data(empno) async {
    dynamic responseBody = await Networking.fetchData(
      apiUrl:
          'https://sandstar-dev-api.azurewebsites.net/api/ManagementApp/GetManagerHierarchy?reportingManagerCode=$empno',
      headers: {'Content-Type': 'application/json'},
      requestBody: {},
    );
    final managersdata = List<Map<String, dynamic>>.from(responseBody);
    setState(
      () {
        managers = managersdata
            .map<String>((manager) => manager['employeeName'])
            .toList();
      },
    );
  }

  List<String> getAvailableMonths(int year) {
    if (year == DateTime.now().year) {
      return months.sublist(0, DateTime.now().month);
    }
    return months;
  }

  // Modify this function to return data
  Future<void> fetch_employee_Data(userid, fromDate, isWeekly) async {
    sample = [];
    dynamic responseData = await Networking.fetchData(
      apiUrl:
          'https://sandstar-dev-api.azurewebsites.net/api/ManagementApp/EmployeeProductivity',
      headers: {
        'Content-Type': 'application/json',
      },
      requestBody: {
        "userID": userid,
        "OrganizationId": 2,
        "Fromdate": fromDate,
        "Interval": 6,
        "Mode": isWeekly,
        "Option": "employee",
        "TimeOff": 2
      },
    );
    setState(() {
      sample = responseData;
      print('sample $responseData');
    });
  }

  @override
  void initState() {
    super.initState();
    fetch_manager_Data(null);
    var currentDate = DateTime.now();
    var fromDate = DateTime(currentDate.year, currentDate.month - 5, 1);
    fetch_employee_Data(76, fromDate.toString(), 1);
    // Adjust the currentStartMonth
    if (currentStartMonth <= 0) {
      currentStartMonth += 12;
    }
  }

  void _showSavedFilters() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Saved Filters"),
          content: Container(
            width: double.maxFinite,
            height: 200, // You can adjust this or make it dynamic if needed
            child: ListView.builder(
              itemCount: savedFilters.length,
              itemBuilder: (context, index) {
                final filter = savedFilters[index];
                return ListTile(
                  title: Text('Manager: ${filter['selectedManagerOrEmployee']}'),
                  subtitle: Text('Date: ${filter['selectedDateOrWeek']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      var repos = Repository();
                      var table = "EmployeeProductivityFilter";
                      var data = await repos.deleteDataByID(table,filter['id']);
                      if(data == 1){
                        savedFilters.removeAt(index);
                        setState(() {
                          savedFilters;
                        });
                      }
                    },
                  ),
                  // onTap: () {
                  //   setState(() {
                  //     managerController.text = filter['manager'];
                  //     _currentWeek = DateTime.parse(filter['date']);
                  //     selectedManager = filter['manager'];
                  //   });
                  //   Navigator.pop(context);
                  // },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  final TextEditingController managerController = TextEditingController();
  List<int> years =
      List.generate(DateTime.now().year - 1999, (index) => 2000 + index);

  List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  int selectedYear = DateTime.now().year;
  int currentStartMonth = DateTime.now().month - 6;
  String selectedMonth = 'January';
  List<String> getMondays(int year, String month) {
    int monthIndex = months.indexOf(selectedMonth) + 1;

    DateTime firstDateOfMonth = DateTime(year, monthIndex, 1);
    List<String> mondays = [];

    for (int i = 0; i < 31; i++) {
      DateTime date = firstDateOfMonth.add(Duration(days: i));
      if (date.weekday == DateTime.monday && date.month == monthIndex) {
        mondays.add(DateFormat('dd').format(date));
      }
      if (date.month != monthIndex) break;
    }
    return mondays;
  }

  List<String> displayedMonths = [];
  _MyHomePageState() {
    List<String> availableMonths = (selectedYear == DateTime.now().year)
        ? months.sublist(0, DateTime.now().month)
        : months;
// Show all months for previous years
  }

  Widget _buildFilterInfo() {
    return GestureDetector(
      onTap: _showSavedFilters,
      child: Container(
        padding: EdgeInsets.all(8.0),
        color: Color(
            0xFFDEEBFE), // This sets the background color of the saved filters container
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Manager: ${selectedManager ?? 'N/A'}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                'Date: ${isWeekly ? _currentWeek != null ? DateFormat('dd MMM yyyy').format(_currentWeek!) : 'N/A' : '$selectedMonth $selectedYear'}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => FilterLayout(
        onFilterChanged: (selectedManager, newSelectedYear, selectedMonth,
            currentWeek, isWeekly, isEmployee) {
          selectedManager = selectedManager;
          var fromDate = DateTime(newSelectedYear, selectedMonth, 1);
          selectedYear = newSelectedYear;
          currentStartMonth = selectedMonth;
          fetch_employee_Data(selectedManager, fromDate.toString(), 1);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF5FE),
      appBar: AppBar(
        title: Text('Heat Map Grid'),
      ),
      body: Column(
        children: [
          _buildFilterInfo(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: () {
                  var fromDate = DateTime(selectedYear, currentStartMonth, 1);

                  fetch_employee_Data(76, fromDate.toString(), 1);
                  setState(() {
                    if (isWeekly) {
                      _currentWeek = _currentWeek!.subtract(Duration(days: 7));
                    } else {
                      isEnabled = true;
                      currentStartMonth--;
                      if (currentStartMonth < 0) {
                        currentStartMonth = 11;
                        selectedYear--;
                      }
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.arrow_right),
                color: isEnabled ? Colors.black : Colors.grey,
                onPressed: isEnabled
                    ? () {
                        setState(() {
                          if (isWeekly) {
                            _currentWeek = _currentWeek!.add(Duration(days: 7));
                          } else {
                            currentStartMonth++;
                            if (selectedYear == DateTime.now().year) {
                              if ((currentStartMonth + 6) ==
                                  DateTime.now().month) {
                                isEnabled = false;
                              }
                            }
                            if (currentStartMonth > 11) {
                              currentStartMonth -= 12;
                              selectedYear++;
                            }
                          }
                        });
                        var fromDate =
                            DateTime(selectedYear, currentStartMonth + 1, 1);
                        fetch_employee_Data(76, fromDate.toString(), 1);
                      }
                    : null,
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(
                      top: 5.0, bottom: 60.0), // Adjust the top padding here
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: sample.isNotEmpty
                              ? HeatMapGrid(
                                  isWeekly: isWeekly,
                                  isEmployee: isEmployee, // Add this line
                                  selectedYear: selectedYear,
                                  selectedMonth: selectedMonth,
                                  currentWeek: _currentWeek,
                                  currentStartMonth: currentStartMonth,
                                  sample: sample,
                                )
                              : CircularProgressIndicator(),
                        ),
                      ),
                      _buildLegend(),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: FloatingActionButton(
                    onPressed: () {
                      _showBottomSheet();
                    },
                    child: Icon(Icons.filter_alt),
                    backgroundColor: Color(0xFF647DF5),
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  right: 86.0,
                  child: FloatingActionButton(
                    onPressed: () async {
                      await fetchData();
                    },
                    child: Icon(Icons.save),
                    backgroundColor: Color(0xFF647DF5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> fetchData() async {

    var filter = EmployeeProductivityFilter();
    filter.selectedManagerOrEmployee = selectedManager;
    filter.isWeekly = true;
    filter.isEmployee = false;
    filter.selectedYear = selectedYear;
    filter.selectedMonth = 2;
    filter.selectedWeek = isWeekly ? _currentWeek : DateTime(selectedYear, 2, 1);

    var result = await _EmployeeProductivityFilterService.saveRecord(filter);
    print('Database $result');

    var get = await _EmployeeProductivityFilterService.readRecord();
    print('GetAll $get');
    savedFilters = get;

      // final response = await apiService.get('ManagementApp/GetManagerHierarchy?reportingManagerCode=null');
      // print('Response Data: $response');
  }


  Color _getGradientColor(double value) {
    if (value >= 0.75) return Color(0xFF52D7A8);
    if (value >= 0.61) return Color(0xFF8FE3C9);
    if (value >= 0.46) return Color(0xFFC0EDE4);
    if (value >= 0.36) return Color(0xFFEDC3D4);
    if (value >= 0.26) return Color(0xFFEA92A9);
    return Color(0xFFE94F73);
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: 110, // Adjust this height based on your requirement
        child: GridView.count(
          physics:
              NeverScrollableScrollPhysics(), // to prevent the GridView from scrolling
          crossAxisCount: 3,
          childAspectRatio: 2.5, // Adjust for your desired width vs. height
          children: <Widget>[
            _buildLegendItem(_getGradientColor(0.9), "75% to 100%"),
            _buildLegendItem(_getGradientColor(0.65), "61% to 74%"),
            _buildLegendItem(_getGradientColor(0.5), "46% to 60%"),
            _buildLegendItem(_getGradientColor(0.2), "< 25%"),
            _buildLegendItem(_getGradientColor(0.3), "26% to 35%"),
            _buildLegendItem(_getGradientColor(0.4), "36% to 45%"),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Use only required space
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 5),
        Flexible(
            child: Text(label)), // Flexible ensures text respects boundaries
      ],
    );
  }
}

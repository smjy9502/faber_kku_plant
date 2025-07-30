import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime _today = DateTime.now();
  DateTime _startDate = DateTime(2024, 5, 1);
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<String>> _schedules = {};

  int get _dDay => _today.difference(_startDate).inDays;

  final TextEditingController _eventController = TextEditingController();

  void _addSchedule(DateTime date, String event) {
    if (event.trim().isEmpty) return;
    setState(() {
      _schedules[date] = [...?_schedules[date], event];
      _eventController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEFFDEB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                '초록이💛 D+$_dDay',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 12),

              // 캘린더 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 상단 년월 + 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 년월 텍스트에 왼쪽 여백 추가
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              DateFormat('yyyy.MM').format(_focusedDay),
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[900],
                              ),
                            ),
                          ),
                          // TODAY 버튼에 오른쪽 여백 추가
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime.now();
                                  _focusedDay = DateTime.now();
                                });
                              },
                              icon: const Icon(Icons.today, size: 16, color: Colors.white),
                              label: const Text(
                                'TODAY',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[400],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: Size(0, 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TableCalendar(
                        locale: 'ko_KR',
                        firstDay: DateTime.utc(2024, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDate = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        headerVisible: false,
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: Colors.green[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 일정 입력
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy.MM.dd').format(_selectedDate),
                      style: TextStyle(fontSize: 16, color: Colors.brown[700]),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _eventController,
                      decoration: InputDecoration(
                        hintText: '이 날의 일정을 입력하세요',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            _addSchedule(_selectedDate, _eventController.text);
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_schedules[_selectedDate] != null)
                      ..._schedules[_selectedDate]!.map(
                        (event) => ListTile(
                          title: Text(event),
                          leading: const Icon(Icons.check, color: Colors.green),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 하단 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _bottomNavButton(Icons.home, '홈', '/'),
                    _bottomNavButton(Icons.spa, 'Info', '/info'),
                    _bottomNavButton(Icons.edit, 'Diary', '/diary'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavButton(IconData icon, String label, String route) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, route);
          },
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[400],
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MainScreen extends StatefulWidget {
  final String userId; // userId 전달
  const MainScreen({super.key, required this.userId});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime _today = DateTime.now();
  DateTime _startDate = DateTime(2024, 5, 1);
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  final Map<DateTime, List<String>> _schedules = {};
  final Map<DateTime, String> _diaries = {};
  final Map<DateTime, Uint8List> _diaryImages = {};

  final TextEditingController _eventController = TextEditingController();
  final TextEditingController _diaryController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  Uint8List? _plantImageBytes;

  DateTime? _lastDiaryKey;
  int get _dDay => _today.difference(_startDate).inDays;
  String _currentRoute = '/';
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  // ------ Firestore/Storage 연동 -----------

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadDiaryData(_selectedDate),
      _loadSchedules(),
      _loadInfoImage(),
    ]);
  }

  // Diary 로드
  Future<void> _loadDiaryData(DateTime date) async {
    final key = _normalize(date);
    final docId = '${widget.userId}_${DateFormat('yyyyMMdd').format(key)}';
    final doc = await FirebaseFirestore.instance.collection('diaries').doc(docId).get();
    if (doc.exists) {
      setState(() {
        _diaries[key] = doc['text'] ?? '';
      });
      final imgUrl = doc.data()?['imageUrl'];
      if (imgUrl != null && imgUrl != "") {
        final imageBytes = await _downloadImage(imgUrl);
        if (imageBytes != null) setState(() => _diaryImages[key] = imageBytes);
      }
    }
  }

  Future<void> _saveDiary(DateTime date, String text) async {
    final key = _normalize(date);
    final docId = '${widget.userId}_${DateFormat('yyyyMMdd').format(key)}';
    String? imageUrl;
    if (_diaryImages[key] != null) {
      imageUrl = await _uploadDiaryImage(key);
    }
    await FirebaseFirestore.instance.collection('diaries').doc(docId).set({
      'text': text,
      'imageUrl': imageUrl ?? "",
      'userId': widget.userId,
      'date': DateFormat('yyyy-MM-dd').format(key),
    });
    setState(() {
      _diaries[key] = text;
    });
  }

  // Diary 이미지 업로드
  Future<String?> _uploadDiaryImage(DateTime key) async {
    final bytes = _diaryImages[key];
    if (bytes == null) return null;
    final filePath = 'diaries/${widget.userId}_${DateFormat('yyyyMMdd').format(key)}.png';
    final ref = FirebaseStorage.instance.ref(filePath);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    return await ref.getDownloadURL();
  }

  // Storage 이미지 다운로드는 null safety 반영
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      return await ref.getData();
    } catch (e) {
      return null;
    }
  }

  // 일정 전체 불러오기
  Future<void> _loadSchedules() async {
    final snap = await FirebaseFirestore.instance.collection('schedules')
        .where('userId', isEqualTo: widget.userId).get();
    final map = <DateTime, List<String>>{};
    for (var doc in snap.docs) {
      final date = DateTime.parse(doc['date']);
      map[date] = List<String>.from(doc['events'] ?? []);
    }
    setState(() => _schedules.addAll(map));
  }

  // 일정 등록
  Future<void> _addSchedule(DateTime date, String event) async {
    if (event.trim().isEmpty) return;
    final key = _normalize(date);
    final docId = '${widget.userId}_${DateFormat('yyyyMMdd').format(key)}';
    final prev = _schedules[key] ?? [];
    final newEvents = [...prev, event];
    await FirebaseFirestore.instance.collection('schedules').doc(docId).set({
      'userId': widget.userId,
      'date': DateFormat('yyyy-MM-dd').format(key),
      'events': newEvents,
    });
    setState(() {
      _schedules[key] = newEvents;
      _eventController.clear();
    });
  }

  // info 이미지( 다른 부분도 동일하게 적용)
  Future<void> _loadInfoImage() async {
    final ref = FirebaseStorage.instance.ref('info/${widget.userId}_plant.png');
    try {
      final bytes = await ref.getData();
      if (bytes != null) setState(() => _plantImageBytes = bytes);
    } catch (e) { /* ignore */ }
  }

  Future<void> _saveInfoImage(Uint8List bytes) async {
    final ref = FirebaseStorage.instance.ref('info/${widget.userId}_plant.png');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    setState(() => _plantImageBytes = bytes);
  }


  // ---------- Popup ----------
  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFEFFDEB),
          title: Text(
            DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(_selectedDate),
            style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _eventController,
            autofocus: true,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              hintText: '일정을 입력하세요',
              hintStyle: TextStyle(fontSize: 14),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () async {
                await _addSchedule(_selectedDate, _eventController.text);
                Navigator.of(context).pop();
              },
              child: const Text('추가', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _onNavigate(String route) {
    setState(() {
      _currentRoute = route;
      _showInfo = (route == '/info');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFEFFDEB),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              '초록이💛 D+$_dDay',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _iconNavButton(Icons.calendar_today_outlined, '/', isSelected: _currentRoute == '/'),
                  _iconNavButton(Icons.eco_outlined, '/info', isSelected: _currentRoute == '/info'),
                  _iconNavButton(Icons.edit_outlined, '/diary', isSelected: _currentRoute == '/diary'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                        child: _showInfo
                            ? _buildInfoBox()
                            : (_currentRoute == '/diary'
                            ? _buildDiaryScrollable()
                            : _buildCalendarBox()),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),
            Image.asset(
              'assets/images/logo.webp',
              width: 70,
              height: 70,
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _iconNavButton(IconData iconData, String route, {bool isSelected = false}) {
    return InkWell(
      onTap: () => _onNavigate(route),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[400] : Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(iconData, size: 20, color: isSelected ? Colors.white : Colors.green),
      ),
    );
  }

  // ------ 캘린더 ------
  Widget _buildCalendarBox() {
    final k = _normalize(_selectedDate);
    final events = _schedules[k] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ... 기존 캘린더 UI 그대로 ...
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                DateFormat('yyyy.MM').format(_focusedDay),
                style: TextStyle(fontFamily: 'Pretendard', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green[900]),
              ),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                      _focusedDay = DateTime.now();
                    });
                  },
                  icon: const Icon(Icons.today, size: 16, color: Colors.white),
                  label: const Text('TODAY', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: Colors.green[600]),
                  onPressed: _showScheduleDialog,
                ),
              ],
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
          onDaySelected: (selectedDay, focusedDay) async {
            setState(() {
              _selectedDate = selectedDay;
              _focusedDay = focusedDay;
            });
            await _loadDiaryData(selectedDay); // 날짜 이동시 일기/이미지 로드!
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
              _selectedDate = DateTime(focusedDay.year, focusedDay.month, 1);
            });
          },
          eventLoader: (day) => _schedules[_normalize(day)] ?? [],
          headerVisible: false,
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(color: Colors.green[400], shape: BoxShape.circle),
            todayDecoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green, width: 1.5)),
            todayTextStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
            markerDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekendStyle: TextStyle(color: Colors.red),
            weekdayStyle: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, thickness: 1, color: Colors.grey),
        const SizedBox(height: 8),
        Expanded(
          child: events.isEmpty
              ? const Center(child: Text("등록된 일정이 없습니다."))
              : ListView.separated(
            itemCount: events.length,
            itemBuilder: (context, index) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.clover, size: 18, color: Colors.green[600]),
                  const SizedBox(width: 6),
                  Expanded(child: Text(events[index], style: const TextStyle(fontSize: 14))),
                ],
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 6),
          ),
        ),
      ],
    );
  }

  // ------ 인포 ------
  Widget _buildInfoBox() {
    final double maxImg = 220;
    final double imgSize = (MediaQuery.of(context).size.width - 32) * 0.65;
    final double finalSize = imgSize.clamp(160, maxImg);
    const Color fixedColor = Color(0xFF111111);
    TextStyle labelStyle = const TextStyle(
      fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.bold, color: fixedColor,
    );
    TextStyle valueStyle = const TextStyle(
      fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w400, color: fixedColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: GestureDetector(
            onTap: () async {
              final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2400);
              if (picked == null) return;
              final bytes = await picked.readAsBytes();
              await _saveInfoImage(bytes);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: finalSize,
                height: finalSize,
                color: Colors.green[100],
                child: _plantImageBytes != null
                    ? Image.memory(_plantImageBytes!, width: finalSize, height: finalSize, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.image, size: 84, color: Colors.white)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _infoRow('이름', '해바라기', labelStyle, valueStyle),
        _infoRow('심은 날', '2024.05.01', labelStyle, valueStyle),
        _infoRow('종류', '일년초', labelStyle, valueStyle),
        _infoRow('개화시기', '6월~8월', labelStyle, valueStyle),
        _infoRow('물주기', '3일에 1번', labelStyle, valueStyle),
        _infoRow('꽃말', '존경, 자부심', labelStyle, valueStyle),
      ],
    );
  }

  Widget _infoRow(String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 24),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(Icons.circle, size: 6, color: Colors.green[600]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '$label: ', style: labelStyle),
                TextSpan(text: value, style: valueStyle),
              ]),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  // ------ 다이어리 ------
  Widget _buildDiaryScrollable() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset + 24),
      child: _buildDiaryBox(),
    );
  }

  Widget _buildDiaryBox() {
    final DateTime key = _normalize(_selectedDate);
    final String existingText = _diaries[key] ?? '';
    final Uint8List? existingImg = _diaryImages[key];

    if (_lastDiaryKey != key) {
      _lastDiaryKey = key;
      _diaryController.value = TextEditingValue(
        text: existingText,
        selection: TextSelection.collapsed(offset: existingText.length),
      );
    }

    final String dateLabel = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(key);
    final bool canGoNext = !_isTodaySelected && (_nextDiaryDate(key) != null);
    final bool canGoPrev = _prevDiaryDate(key) != null;
    final bool editable = _isTodaySelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '이전 작성된 일기',
              onPressed: canGoPrev
                  ? () {
                final d = _prevDiaryDate(key);
                if (d != null) setState(() => _selectedDate = d);
              }
                  : null,
              icon: const Icon(Icons.chevron_left),
              color: Colors.green[700],
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _selectedDate = DateTime.now());
                    },
                    icon: const Icon(Icons.today, size: 16, color: Colors.white),
                    label: const Text('TODAY', style: TextStyle(color: Colors.white, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(0, 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '다음 작성된 일기',
              onPressed: canGoNext
                  ? () {
                final d = _nextDiaryDate(key);
                if (d != null) setState(() => _selectedDate = d);
              }
                  : null,
              icon: const Icon(Icons.chevron_right),
              color: Colors.green[700],
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: editable
              ? () async {
            final XFile? picked = await _picker.pickImage(
                source: ImageSource.gallery, imageQuality: 85, maxWidth: 2400);
            if (picked == null) return;
            final bytes = await picked.readAsBytes();
            setState(() => _diaryImages[key] = bytes);
          }
              : null,
          child: Container(
            width: double.infinity,
            height: 260, // 정방형 + 세로 확장
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green!),
            ),
            child: existingImg != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(existingImg, fit: BoxFit.cover),
            )
                : Center(
              child: Text(
                editable ? '탭해서 그림을 추가하세요 🎨' : '오늘만 그림을 추가할 수 있어요',
                style: TextStyle(color: Colors.green[700]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _diaryController,
          enabled: editable,
          minLines: 2,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: editable ? '오늘의 초록이 일기를 써주세요 🌿' : '오늘만 작성할 수 있어요',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: editable
              ? () async {
            await _saveDiary(key, _diaryController.text);
            FocusScope.of(context).unfocus();
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[400],
            disabledBackgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: const Size(double.infinity, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: const Text('저장', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  List<DateTime> _sortedDiaryDates() {
    final set = _diaries.keys.map(_normalize).toSet();
    final list = set.toList()..sort();
    return list;
  }

  DateTime? _prevDiaryDate(DateTime from) {
    final list = _sortedDiaryDates();
    final key = _normalize(from);
    final prev = list.where((d) => d.isBefore(key)).toList();
    return prev.isEmpty ? null : prev.last;
  }

  DateTime? _nextDiaryDate(DateTime from) {
    final list = _sortedDiaryDates();
    final key = _normalize(from);
    final next = list.where((d) => d.isAfter(key)).toList();
    return next.isEmpty ? null : next.first;
  }

  bool get _isTodaySelected => _normalize(_selectedDate) == _normalize(DateTime.now());
}

import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDataManager {
  Future<List<Map<String, dynamic>>> _fetchData(
      {required String accessToken, required String path}) async {
    final url = Uri.https('sinhvien1.tlu.edu.vn', path);

    HttpClient client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    IOClient ioClient = IOClient(client);

    try {
      final response = await ioClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json, text/plain, */*',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        // The API can return a List or a Map. If it's a list, cast it.
        return (decodedData as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load: ${response.body}');
      }
    } catch (e) {
      rethrow;
    } finally {
      ioClient.close();
    }
  }

  // --- Public Methods ---

  Future<void> fetchAndSaveSchedule(
      {required String accessToken,
      required String username,
      required String semesterId}) async {
    // path, storage key

    final path =
        '/education/api/StudentCourseSubject/studentLoginUser/$semesterId';
    const storageKey = 'class_schedule_';

    // fetch data
    final rawData = await _fetchData(accessToken: accessToken, path: path);
    final List<Map<String, dynamic>> processedData =
        _parseAndCleanScheduleData(rawData);

    // await saveDataAsPrettyJson(
    //     processedData, "E:\\Work\\Wiki\\exercises\\dart\\schedule.json");

    _saveData(storageKey, username, processedData);
  }

  Future<void> fetchAndSaveExamSchedule({
    required String accessToken,
    required String username,
    required String semesterId,
    required String semesterType,
    required String examAttempt,
  }) async {
    // path, storage key
    final path =
        '/education/api/semestersubjectexamroom/getListRoomByStudentByLoginUser/$semesterId/$semesterType/$examAttempt';
    const storageKey = 'exam_schedule_';

    // fetch data
    final rawData = await _fetchData(accessToken: accessToken, path: path);
    final List<Map<String, dynamic>> processedData =
        _parseAndCleanExamData(rawData);

    // await saveDataAsPrettyJson(
    //     processedData, "E:\\Work\\Wiki\\exercises\\dart\\exam.json");

    _saveData(storageKey, username, processedData);
  }

//   Future<void> _saveDataAsJson(dynamic data, String filePath) async {
//     const JsonEncoder encoder = JsonEncoder.withIndent('  ');
//     final file = File(filePath);
//     await file.parent.create(recursive: true);
//     final jsonString = encoder.convert(data);
//     await file.writeAsString(jsonString);
//   }

  Future<void> _saveData(
      String key, String username, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$key$username', jsonEncode(data));
  }

  // --- Data Loading and Processing Helpers ---

  Future<List<Map<String, dynamic>>> loadLearningSchedule(
      String username) async {
    return _loadData('class_schedule_$username');
  }

  Future<List<Map<String, dynamic>>> loadExamSchedule(String username) async {
    return _loadData('exam_schedule_$username');
  }

  Future<List<Map<String, dynamic>>> _loadData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString(key);
    if (jsonData != null && jsonData.isNotEmpty) {
      return (jsonDecode(jsonData) as List).cast<Map<String, dynamic>>();
    }
    return [];
  } // load data from SharedPreferences by key

  //clean and sort exam schedule data
  List<Map<String, dynamic>> _parseAndCleanExamData(List<dynamic> data) {
    final List<Map<String, dynamic>> subjectsInfo = [];

    for (var item in data) {
      final subjectInfo = {
        "subjectName": item['examRoom']['semesterSubjectExam']['subject']
            ['subjectName'],
        "studentCode": item['examCode'],
        "examDate": item['examRoom']['examDateString'],
        "examHour": {
          "startHour": item['examRoom']['examHour']['startString'],
          "endHour": item['examRoom']['examHour']['endString']
        },
        "room": item['examRoom']['room']['name']
      };
      subjectsInfo.add(subjectInfo);
    }
    // Sort by exam date
    subjectsInfo.sort((a, b) {
      final dateA = _parseDate(a['examDate']);
      final dateB = _parseDate(b['examDate']);
      return dateA.compareTo(dateB);
    });
    return subjectsInfo;
  }

// clean and sort schedule data
  List<Map<String, dynamic>> _parseAndCleanScheduleData(List<dynamic> rawData) {
    if (rawData.isEmpty) {
      return [];
    }

    return rawData.map<Map<String, dynamic>>((subject) {
      // timetables is inside courseSubject
      final rawTimetables =
          subject['courseSubject']?['timetables'] as List? ?? [];

      final cleanedTimetables = rawTimetables.map<Map<String, dynamic>>((tt) {
        return {
          'startHour': tt['startHour']['startString'],
          'endHour': tt['endHour']['endString'],
          'weekIndex': tt['weekIndex'],
          'roomName': tt['roomName'],
          // convert startDate and endDate to DateTime
          'startDate': _formatTimestamp(tt['startDate'] as int?),
          'endDate': _formatTimestamp(tt['endDate'] as int?),
        };
      }).toList();

      return {
        'subjectCode': subject['subjectCode'],
        'timetables': cleanedTimetables,
      };
    }).toList();
  }

  // convert "DD/MM/YYYY" to a DateTime object
  DateTime _parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length != 3) {
        // If it's not in the expected format, return a default past date
        return DateTime(1970);
      }
      // Reassemble in "YYYY-MM-DD" format and parse
      final day = parts[0];
      final month = parts[1];
      final year = parts[2];
      return DateTime(int.parse(year), int.parse(month), int.parse(day));
    } catch (e) {
      return DateTime(1970);
    }
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null || timestamp == 0) {
      return 'N/A';
    }
    try {
      // Create a DateTime object from the milliseconds since epoch
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }
}

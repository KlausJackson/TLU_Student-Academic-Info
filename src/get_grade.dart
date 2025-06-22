import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GradeItem {
  final String subjectName;
  final int numberOfCredits;
  final bool isCalculated; // whether the grade is calculated in GPA
  final double processMark; // Điểm quá trình (markQT)
  final double finalExamMark; // Điểm thi (markTHI)
  final double endMark; // Điểm tổng kết (mark)
  final String charMark; // Điểm chữ (charMark)

  GradeItem({
    required this.subjectName,
    required this.numberOfCredits,
    required this.isCalculated,
    required this.processMark,
    required this.finalExamMark,
    required this.endMark,
    required this.charMark,
  });

  // create from a saved JSON map
  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      subjectName: json['subjectName'],
      numberOfCredits: json['numberOfCredits'],
      isCalculated: json['isCalculated'] ?? true,
      processMark: (json['processMark'] ?? 0.0).toDouble(),
      finalExamMark: (json['finalExamMark'] ?? 0.0).toDouble(),
      endMark: (json['endMark'] ?? 0.0).toDouble(),
      charMark: json['charMark'],
    );
  }

  // convert an instance to a JSON map for saving
  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'numberOfCredits': numberOfCredits,
        'isCalculated': isCalculated,
        'processMark': processMark,
        'finalExamMark': finalExamMark,
        'endMark': endMark,
        'charMark': charMark,
      };
}

class GradeManager {
  Future<List<GradeItem>> fetchGrades({required String accessToken}) async {
    final url = Uri.https('sinhvien1.tlu.edu.vn',
        '/education/api/studentsubjectmark/getListStudentMarkBySemesterByLoginUser/0');

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
        // await saveDataAsJson(_parseAndClean(jsonDecode(utf8.decode(response.bodyBytes))));
        return _parseAndClean(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to load: ${response.body}');
      }
    } catch (e) {
      rethrow;
    } finally {
      ioClient.close();
    }
  }

//   Future<void> saveDataAsJson(dynamic data) async {
//     const JsonEncoder encoder = JsonEncoder.withIndent('  ');
//     final file = File("E:\\Work\\Wiki\\exercises\\dart\\exam.json");
//     await file.parent.create(recursive: true);
//     final jsonString = encoder.convert(data);
//     await file.writeAsString(jsonString);
//   }

  List<GradeItem> _parseAndClean(List<dynamic> data) {
    final List<GradeItem> grades = [];
    for (var item in data) {
      if (item is Map<String, dynamic>) {
        grades.add(
          GradeItem(
            subjectName: item['subject']?['subjectName'],
            numberOfCredits: item['subject']?['numberOfCredit'] ?? 0,
            isCalculated: item['subject']?['isCalculateMark'] ?? false,
            processMark: (item['markQT'] ?? 0.0).toDouble(),
            finalExamMark: (item['markTHI'] ?? 0.0).toDouble(),
            endMark: (item['mark'] ?? 0.0).toDouble(),
            charMark: item['charMark'],
          ),
        );
      }
    }
    return grades;
  }

  // char marks and their corresponding colors and GPA values
  Map<String, dynamic> gradeInfo = {
    'A': {'color': Colors.green, 'gpa': 4.0},
    'B': {'color': Colors.blue, 'gpa': 3.0},
    'C': {'color': Colors.yellow, 'gpa': 2.0},
    'D': {'color': Colors.orange, 'gpa': 1.0},
    'F': {'color': Colors.red, 'gpa': 0.0},
  };

  double calculateGPA(List<GradeItem> grades) {
    double totalPoints = 0.0;
    int totalCredits = 0;

    for (var grade in grades) {
      if (grade.isCalculated && grade.charMark != 'F') {
        totalPoints += gradeInfo[grade.charMark]['gpa'] * grade.numberOfCredits;
        totalCredits += grade.numberOfCredits;
      }
    }

    if (totalCredits == 0) return 0.00;
    return totalPoints / totalCredits;
  }

  /// Saves to local storage
  Future<void> saveGrades(List<GradeItem> grades, String username) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        grades.map((g) => g.toJson()).toList();
    await prefs.setString('grades_$username', jsonEncode(jsonList));
  }

  /// Loads from local storage
  Future<List<GradeItem>> loadGrades(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString('grades_$username');
    if (jsonData != null) {
      final List<dynamic> list = jsonDecode(jsonData);
      return list.map((item) => GradeItem.fromJson(item)).toList();
    }
    return [];
  }
}

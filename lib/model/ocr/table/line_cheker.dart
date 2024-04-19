import 'package:flutter/material.dart';
import 'package:progression_live_upgrade/model/general/function.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'main.dart';

class LineChecker {
  List<TextLine> lines;
  late PdfTable table;

  LineChecker(this.lines) {
    table = _convertLinesToTable();
  }

  PdfTable _convertLinesToTable() {
    List<TextLine> validLines = [];
    Map<Rect, List<TextWord>> wordsLines = {};
    bool isTable = false;
    int currentPage = 0;
    bool isHeader = false;

    PdfTable? result;

    for(var line in lines) {

      isHeader = line.wordCollection.indexWhere((e) => e.text.toLowerCase().contains("desc")) >= 0;
      print("line: ${line.text}, is header : $isHeader");

      if (result == null) {
        if (isHeader) {
          result = PdfTable(line);
          isTable = true;
        }
      } else {
        if (currentPage != line.pageIndex) {
          // Check if we are on a different page.
          // In this case, we restart the process of finding table.
          currentPage = line.pageIndex;
          isTable = false;
          print("new page");
        }

        if (isTable && result.columns.first.bounds == line.wordCollection.firstWhere((element) => element.text.trim() != "").bounds) {
          // If we have found a table in current page AND the first element have correct position to be an element
          TextLine validLine = line;
          result.add(line);
          /*validLine.wordCollection.removeWhere((element) => element.text.trim() == "");
          for(TextWord word in line.wordCollection) {
            Rect? currentRect;
            List<Rect> rects = wordsLines.keys.where((element) {
              return (element.left - word.bounds.left).abs() < 5
                  || (element.right - word.bounds.right).abs() < 5
                  || (element.center.dx - word.bounds.center.dx).abs() < 5;
            }).toList();

            if (rects.isEmpty) {
              currentRect = word.bounds;
              //List<TextWord?> emptyCells = wordsLines.isEmpty ? [] : List.generate(wordsLines.entries.first.value.length, (index) => null);
              wordsLines.addEntries([MapEntry(currentRect, [])]);
            } else {
              currentRect = rects.first;
            }
            wordsLines[currentRect]?.add(word);

          }*/
          //validLines.add(validLine);
          print("page: ${validLine.pageIndex}, RECT: ${validLine.bounds}\n${validLine.wordCollection.map((e) => e.text).join("-")}\n");
        } else if (!isTable) {
          isTable = isHeader;
        }
        if (isNumeric(line.wordCollection.firstWhere((element) => element.text.trim() != "").text.characters.first)) {
          //print("page: ${line.pageIndex}, RECT: ${line.bounds}\n${line.wordCollection.map((e) => e.text).join("-")}\n");
        }
      }

    }

    print(result!.columns.map((e) => e.name.padRight(18)).join());

    for (var row in result) {

      print(row);
    }
    for(MapEntry<Rect, List<TextWord>> entry in wordsLines.entries) {
      print("bound: ${entry.key}, values: ${entry.value.map((e) => e.text).join("*")}");
    }
    return result;

  }
}
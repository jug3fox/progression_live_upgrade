import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../general/list.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'line_cheker.dart';

class PdfTable extends CustomList<PdfRow> {

  final List<PdfColumn> columns = [];

  int lengthAt(int index) {
    return (
        map((e) => (e.row.values.elementAt(index) as TextWord?)?.text.length ?? 0)
          .toList()
          ..sort((a, b) => a.compareTo(b))
    ).last;
  }

  PdfTable(TextLine line) {
    List<TextWord> clearLine = _removeNullCells(line);
    for (int i = 0; i < clearLine.length; i++) {
      TextWord word = clearLine[i];
      columns.add(
          PdfColumn(
              bounds: HorizontalBound(
                  word.bounds.left,
                  i < clearLine.length - 1 ? clearLine[i + 1].bounds.left : word.bounds.right + 5
              ),
              name: word.text.trim()
          )
      );
    }
  }

  PdfTable.empty();

  @override
  void add(dynamic element) {
    // TODO: implement add
    if (element is PdfRow) super.add(element);
    if (element is TextLine) {
      PdfRow row = PdfRow(
          parentTable: this,
          words: element
      );
      super.add(row);
    }
  }

  @override
  String toString() {
    // TODO: implement toString
    return join('\n');
  }

  List<TextWord> _removeNullCells(TextLine line) {
    List<TextWord> result = [];
    List<TextWord> words = line.wordCollection;
    for (int i = 0; i < words.length; i++) {
      TextWord currentWord = words[i];
      if ((i == 0 || result.isEmpty) && words.first.text.trim() != "") {
        result.add(currentWord);
      } else {
        if (words[i].text.trim() != "") {
          if (words[i-1].text.trim() != "" || (i > 1 && words[i-2].text.trim() != "" && !words[i-2].text.trim().endsWith("."))) {
            result.last.text += words[i].text;
            result.last.bounds = result.last.bounds.expandToInclude(words[i].bounds);
          } else {
            result.add(words[i]);
          }
        }
      }
    }
    return result;
  }
}

class PdfColumn<T> {
  HorizontalBound bounds;
  String name;

  PdfColumn({
    required this.bounds,
    required this.name,
    int columnToComplete = 0
  });
}

class PdfRow {
  final Map<PdfColumn, TextWord?> row = {};
  final PdfTable parentTable;

  PdfRow({
    required this.parentTable,
    required TextLine words,
  }) {
    words.wordCollection.removeWhere((element) => element.text.trim() == "");
    row.addEntries((parentTable.columns..sort((a, b) => a.bounds.left.compareTo(b.bounds.left))).map((e)
      => MapEntry(e, null)
    ));
    for (PdfColumn column in parentTable.columns) {
      TextWord? currentWord = words.wordCollection.getWords(column.bounds);
      row[column] = currentWord;
    }
  }

  @override
  String toString() {
    // TODO: implement toString
    return "[${row.entries.map((value) => "${(value.value as TextWord?)?.text}".padRight(18)).join()}]";
  }
}

extension ListExt on List<TextWord> {
  TextWord? getWord(HorizontalBound boundToCheck) {
    for (TextWord word in this) {
      if (boundToCheck == word) {
        return word;
      }
    }
    return null;
  }

  TextWord? getWords(HorizontalBound boundToCheck) {
    TextWord? result;
    for (TextWord word in this) {
      if (boundToCheck == word) {
        if (result == null) {
          result = word;
        } else {
          result.text = result.text += " ${word.text}";
          result.bounds.expandToInclude(word.bounds);
        }
      }
    }
    return result;
  }
}

class HorizontalBound {
  double left, right, center;

  HorizontalBound(this.left, this.right) : center = left + (right - left) / 2;

  @override
  operator ==(other) {
    if (other is List<TextWord>) {
      List<TextWord> words = other;
      words.where((element) => this == element.bounds);
    }

    if (other is TextWord) {
      return this == other.bounds;
    }

    if (other is Rect) {
      return other.center.dx > left && other.center.dx < right;
      return ((other.left - left).abs() < 5
          || (other.right - right).abs() < 5
          || (other.left + (other.right - other.left) / 2 - center).abs() < 5
      );
    }

    if (other is! HorizontalBound) return false;
    return true;
  }

  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;


}

class PdfToTextConverter {
  final PlatformFile file;
  final bool _autoFindTable;
  late final Future<List<TextLine>> future;
  late final Future<PdfTable>? futureTable;

  LineChecker? checker;

  PdfToTextConverter(this.file, {
    bool autoFindTable = true,
  }) : _autoFindTable = autoFindTable {
    future = _convertToText(file);
    if (autoFindTable) {
      futureTable = future.then((lines) {
        return LineChecker(lines).table;
      });
    } else {
      futureTable = null;
    }
  }

  Future<List<TextLine>> _convertToText(PlatformFile pdf) async {
    File newFile = File(pdf.path!);

    final PdfDocument document = PdfDocument(inputBytes: await newFile.readAsBytes());

    //Create PDF text extractor to extract text
    PdfTextExtractor extractor = PdfTextExtractor(document);

    //Extract text
    //String text = extractor.extractText();

    final lines = extractor.extractTextLines();
    lines.sort((a, b) => (a.bounds.top + a.pageIndex * 10000).compareTo(b.bounds.top + b.pageIndex * 10000));
    document.dispose();

    return lines;
  }
}
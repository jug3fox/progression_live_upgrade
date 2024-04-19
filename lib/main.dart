import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:progression_live_upgrade/model/file/main.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:text_analysis/text_analysis.dart';

import 'model/ocr/table/main.dart';

//late final Gemini gemini;

void main() {
  //Gemini.init(apiKey: 'AIzaSyB2PYzkXe2guLyeojQZq5q-f3knzPCdic0');
  //gemini = Gemini.instance;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: true ? const MainPage() : Center(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late PdfDocumentFile filePicker = PdfDocumentFile();
  bool get isLoadingText => text == null;
  String? text = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Flex(
        direction: Axis.vertical,
        children: [
          ElevatedButton(
              onPressed: () async {
                setState(() {
                  text = null;
                });
                PlatformFile? result = await filePicker.getFile();
                if (result != null) {
                  PdfTable? table = await PdfToTextConverter(result).futureTable;
                  setState(() {
                    text = table.toString();
                  });
                }
              },
              child: Text("Test")
          ),
          Text("text: ${text.toString()}")
        ],
      ),
    );
  }

  Future<void> _convertToText(PlatformFile pdf) async {
    File newFile = File(pdf.path!);

    final PdfDocument document = PdfDocument(inputBytes: await newFile.readAsBytes());

    //Create PDF text extractor to extract text
    PdfTextExtractor extractor = PdfTextExtractor(document);

    //Extract text
    //String text = extractor.extractText();

    final lines = extractor.extractTextLines();
    lines.map((line) {
      print("line: $line");
    });
    bool isTable = false;
    int currentPage = 0;
    lines.sort((a, b) => (a.bounds.top + a.pageIndex * 10000).compareTo(b.bounds.top + b.pageIndex * 10000));
    List<TextLine> validLines = [];
    Map<Rect, List<TextWord>> wordsLines = {};
    List<List<TextWord>> words = [];

    for(var line in lines) {
      if (currentPage != line.pageIndex) {
        currentPage = line.pageIndex;
        isTable = false;
        print("new page");
      }
      if (isTable && isNumeric(line.wordCollection.firstWhere((element) => element.text.trim() != "").text.characters.first)) {

        TextLine validLine = line;
        validLine.wordCollection.removeWhere((element) => element.text.trim() == "");
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

        }
        validLines.add(validLine);
        print("page: ${validLine.pageIndex}, RECT: ${validLine.bounds}\n${validLine.wordCollection.map((e) => e.text).join("-")}\n");
      } else if (!isTable) {
        isTable = line.wordCollection.indexWhere((element) => element.text.toLowerCase().contains("desc")) >= 0;

      }
      if (isNumeric(line.wordCollection.firstWhere((element) => element.text.trim() != "").text.characters.first)) {
        //print("page: ${line.pageIndex}, RECT: ${line.bounds}\n${line.wordCollection.map((e) => e.text).join("-")}\n");
      }
    }

    for(MapEntry<Rect, List<TextWord>> entry in wordsLines.entries) {
      print("bound: ${entry.key}, values: ${entry.value.map((e) => e.text).join("*")}");
    }
    // Dispose the document
    document.dispose();

    //Save the file and launch/download
    //SaveFile.saveAndLaunchFile(text, 'output.txt');
  }

}

bool isNumeric(String s) {
  return double.tryParse(s) != null;
}

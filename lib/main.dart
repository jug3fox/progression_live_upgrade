import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:intl/intl.dart';
import 'package:progression_live_upgrade/model/file/main.dart';
import 'package:progression_live_upgrade/model/general/function.dart';
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
  bool get isLoadingText => table == null;
  PdfTable? table;
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
                  table = null;
                });
                PlatformFile? result = await filePicker.getFile();
                if (result != null) {
                  PdfTable? tableResult = await PdfToTextConverter(result).futureTable;
                  setState(() {
                    table = tableResult;
                  });
                }
              },
              child: Text("Test")
          ),
          Column(
            children: table == null ? [] : [
              Row(
                children: table!.columns.map((column) {
                  return Expanded(
                    child: Text(column.name, overflow: TextOverflow.fade, softWrap: false, textAlign: TextAlign.left,),
                  );
                }).toList(),
              ),
              ...table!.map((row) {

                return Row(
                  children: row.row.values.map((value) {
                    String? result;
                    if (value != null) {

                      if (isNumeric(value.text)) {
                        //value.text = value.text.replaceAll(".", ",");
                        double? numResult = double.tryParse(value.text);
                        if (numResult != null && numResult.ceil() != numResult) {
                          result = "${NumberFormat("0.00").format(numResult ?? "TEST")} \$";
                        }
                      }
                      result ??= value.text;
                    }
                    return Expanded(
                      child: Text(result ?? "--", textAlign: result?.contains("\$") != true ? TextAlign.left : TextAlign.right),
                    );
                  }).toList(),
                );
              }).toList()
            ],
          )
        ],
      ),
    );
  }

}

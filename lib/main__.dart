import 'dart:convert';
import 'package:blockchain_docuemnts_notarization/utils/notarization_api_sdk.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(MyApp());
}

/// Widget principale dell'applicazione
class MyApp extends StatelessWidget {
  final NotarizationApi api = NotarizationApi();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notarization API Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NotarizationTestPage(api: api),
    );
  }
}

/// Pagina di test per verificare lo SDK e la comunicazione con l'API
class NotarizationTestPage extends StatefulWidget {
  final NotarizationApi api;
  const NotarizationTestPage({Key? key, required this.api}) : super(key: key);

  @override
  _NotarizationTestPageState createState() => _NotarizationTestPageState();
}

class _NotarizationTestPageState extends State<NotarizationTestPage> {
  String _result = '';

  // Simulazione di un file PDF: codifica in Base64 di una stringa dummy.
  // In una vera applicazione, si potrebbe utilizzare il FilePicker per selezionare un file e codificarlo.
  final String dummyBase64 = base64Encode(utf8.encode("Contenuto dummy del PDF"));
  final String fileName = "test.pdf";
  final String storageId = "test_storage";

  /// Metodo per inviare la richiesta di notarizzazione
  void _notarizeDocument() async {
    setState(() {
      _result = 'Notarizing document...';
    });
    try {
      Map<String, dynamic> response = await widget.api.notarizeDocument(
        documentBase64: dummyBase64,
        fileName: fileName,
        storageId: storageId,
        metadata: {"description": "Documento di test", "author": "Flutter Tester"},
        selectedChain: ["algo"],
      );
      setState(() {
        _result = jsonEncode(response, toEncodable: (e) => e.toString());
      });
    } catch (e) {
      setState(() {
        _result = e.toString();
      });
    }
  }

  /// Metodo per inviare la richiesta di query sul documento
  void _queryDocument() async {
    setState(() {
      _result = 'Querying document...';
    });
    try {
      Map<String, dynamic> response = await widget.api.queryDocument(
        storageId: storageId,
        fileName: fileName,
        selectedChain: ["algo"],
      );
      setState(() {
        _result = jsonEncode(response, toEncodable: (e) => e.toString());
      });
    } catch (e) {
      setState(() {
        _result = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notarization API Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _notarizeDocument,
              child: Text('Notarize Document'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _queryDocument,
              child: Text('Query Document'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _result,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

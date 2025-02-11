import 'dart:convert';
import 'package:http/http.dart' as http;

/// SDK Flutter per comunicare con l'API di Notarizzazione.
class NotarizationApi {
  final String baseUrl;

  /// Costruttore: per default l'API si assume in esecuzione su http://localhost:8100.
  NotarizationApi({this.baseUrl = 'http://localhost:8100'});

  /// Invia una richiesta di notarizzazione allo Scenario 1.
  ///
  /// Parametri:
  /// - [documentBase64]: Il documento codificato in Base64.
  /// - [fileName]: Nome del file (con estensione) da salvare.
  /// - [storageId]: Identificativo della directory di storage.
  /// - [metadata]: Dizionario di metadati opzionali (verranno integrati con i campi aggiuntivi).
  /// - [selectedChain]: Lista di blockchain (es. ["algo"]).
  ///
  /// Ritorna un [Future] che risolve in un [Map<String, dynamic>] contenente la risposta JSON.
  Future<Map<String, dynamic>> notarizeDocument({
    required String documentBase64,
    required String fileName,
    required String storageId,
    required Map<String, dynamic> metadata,
    required List<String> selectedChain,
  }) async {
    final url = Uri.parse('$baseUrl/scenario1/notarize');
    final payload = {
      "document_base64": documentBase64,
      "file_name": fileName,
      "storage_id": storageId,
      "metadata": metadata,
      "selected_chain": selectedChain,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Notarize error: ${response.body}');
    }
  }

  /// Invia una richiesta di query allo Scenario 1 per ottenere i metadati completi del documento.
  ///
  /// Parametri:
  /// - [storageId]: Identificativo della directory di storage.
  /// - [fileName]: Nome del file (con estensione) da ricercare.
  /// - [selectedChain]: Lista di blockchain (es. ["algo"]).
  ///
  /// Ritorna un [Future] che risolve in un [Map<String, dynamic>] contenente i metadati.
  Future<Map<String, dynamic>> queryDocument({
    required String storageId,
    required String fileName,
    required List<String> selectedChain,
  }) async {
    final url = Uri.parse('$baseUrl/scenario1/query');
    final payload = {
      "storage_id": storageId,
      "file_name": fileName,
      "selected_chain": selectedChain,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Query error: ${response.body}');
    }
  }
}

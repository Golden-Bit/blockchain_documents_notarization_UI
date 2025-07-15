import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; 

/// ---------------------------------------------------------------------------
///  NotarizationApi – SDK Flutter/Dart per la Document-Notarization API
///
///  Aggiornato per la **v1.1** dell’API (maggio 2025):
///  • Aggiunto parametro `folder_path` negli endpoint di Scenario 1  
///    – consente di ricreare sul server la stessa gerarchia cartelle della UI.  
///  • Doc-string in italiano con esempi d’uso completi.
/// ---------------------------------------------------------------------------
class NotarizationApi {
  /// URL radice del backend (es. http://localhost:8100).
  ///
  /// Puoi passare un indirizzo diverso quando istanzi la classe:
  /// ```dart
  /// final api = NotarizationApi(baseUrl: 'https://api.mioserver.com');
  /// ```
  final String baseUrl;
  const NotarizationApi({this.baseUrl = 'http://127.0.0.1:8077/notarization-api'});

  // ========================================================================
  //  SCENARIO 1  –  Upload e notarizzazione gestita dal wallet aziendale
  // ========================================================================

  /// Carica e notarizza un documento.
  ///
  /// * [documentBase64]  Contenuto del file in Base64 (puoi usare `base64Encode(bytes)`).
  /// * [fileName]        Nome del file comprensivo di estensione.
  /// * [storageId]       Cartella radice assegnata all’utente/azienda.
  /// * [folderPath]      Percorso relativo dentro lo storage ("" se root),
  ///                     es. `"abc/un altra cartella"`.
  /// * [metadata]        Dizionario opzionale (verrà esteso dal backend).
  /// * [selectedChain]   Blockchain di validazione (oggi solo `["algo"]`).
  ///
  /// Ritorna un `Map<String,dynamic>` con la risposta JSON del backend.
  Future<Map<String, dynamic>> notarizeDocument({
    required String documentBase64,
    required String fileName,
    required String storageId,
    required String folderPath,                // NEW ✔
    required Map<String, dynamic> metadata,
    required List<String> selectedChain,
  }) async {
    final url = Uri.parse('$baseUrl/scenario1/notarize');

    final payload = {
      'document_base64': documentBase64,
      'file_name'      : fileName,
      'storage_id'     : storageId,
      'folder_path'    : folderPath,            // NEW ✔
      'metadata'       : metadata,
      'selected_chain' : selectedChain,
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Notarize error (${res.statusCode}): ${res.body}');
  }

  /// Recupera i metadati completi di un documento notarizzato.
  ///
  /// * [storageId]    Identificativo della radice di storage.
  /// * [folderPath]   Percorso relativo dove si trova il file.
  /// * [fileName]     Nome del file (estensione inclusa).
  /// * [selectedChain] Blockchain richiesta (oggi obbligatoriamente `"algo"`).
  ///
  /// Restituisce il contenuto del file `<file_name>-METADATA.JSON`.
  Future<Map<String, dynamic>> queryDocument({
    required String storageId,
    required String folderPath,                // NEW ✔
    required String fileName,
    required List<String> selectedChain,
  }) async {
    final url = Uri.parse('$baseUrl/scenario1/query');

    final payload = {
      'storage_id'    : storageId,
      'folder_path'   : folderPath,             // NEW ✔
      'file_name'     : fileName,
      'selected_chain': selectedChain,
    };

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Query error (${res.statusCode}): ${res.body}');
  }

  // ------------------------------------------------------------------------
  //  ⬇️ Metodi per Scenari 2 e 3 possono essere implementati con
  //  lo stesso pattern (cambiando path e payload) quando necessario.
  // ------------------------------------------------------------------------

  /// ----------------------------------------------------------------------
  ///  Elenco completo di tutti i file presenti in uno storage – NEW v1.1
  ///
  ///  * [storageId]   Radice dello spazio utente/azienda.
  ///  * [recursive]   Se `true` (default) attraversa gerarchia e sotto-cartelle.
  ///
  ///  Il backend risponde con un JSON del tipo:
  ///  ```json
  ///  {
  ///    "abc/un altra cartella/chatbot_docs_v2_it.html": { ...METADATA... },
  ///    "conferma_ord.pdf": { ...METADATA... }
  ///  }
  ///  ```
  Future<Map<String, dynamic>> listStorage({
    required String storageId,
    bool recursive = true,
  }) async {
    final url = Uri.parse(
      '$baseUrl/storage/$storageId/list?recursive=$recursive',
    );

    final res = await http.get(url);                     // GET perché idempotente

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('List error (${res.statusCode}): ${res.body}');
  }
// -------------------------------------------------------------
//  RINOMINA
// -------------------------------------------------------------
Future<void> renamePath({
  required String storageId,
  required String oldPath,
  required String newName,
}) async {
  final url  = Uri.parse('$baseUrl/storage/rename');
  final body = {
    'storage_id': storageId,
    'path'      : oldPath,        // <--  nome corretto
    'new_name'  : newName,
  };

  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body   : jsonEncode(body),
  );
  if (res.statusCode != 200) {
    throw Exception('Rename error (${res.statusCode}): ${res.body}');
  }
}

// -------------------------------------------------------------
//  SPOSTA
// -------------------------------------------------------------
Future<void> movePath({
  required String storageId,
  required String sourcePath,
  required String destFolder,
}) async {
  final url  = Uri.parse('$baseUrl/storage/move');
  final body = {
    'storage_id' : storageId,
    'path'       : sourcePath,    // <--  nome corretto
    'destination': destFolder,    // <--  nome corretto
  };

  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body   : jsonEncode(body),
  );
  if (res.statusCode != 200) {
    throw Exception('Move error (${res.statusCode}): ${res.body}');
  }
}

// -------------------------------------------------------------
//  ELIMINA
// -------------------------------------------------------------
Future<void> deletePath({
  required String storageId,
  required String targetPath,
  bool recursive = false,
}) async {
  final url  = Uri.parse('$baseUrl/storage/delete');
  final body = {
    'storage_id': storageId,
    'path'      : targetPath,     // <--  nome corretto
    'recursive' : recursive,
  };

  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body   : jsonEncode(body),
  );
  if (res.statusCode != 200) {
    throw Exception('Delete error (${res.statusCode}): ${res.body}');
  }
}

// 🔼 2. ALL’INTERNO della classe `NotarizationApi`, dopo i metodi CRUD
// -------------------------------------------------------------
//  DOWNLOAD  –  NEW v1.1
// -------------------------------------------------------------
  /// Scarica un file **o** una cartella (ritornata come ZIP).
  ///
  /// Restituisce i bytes (`Uint8List`) della risposta HTTP; il chiamante
  /// può salvarli su disco o gestirli in memoria.
  ///
  /// Esempio:
  /// ```dart
  /// final bytes = await api.downloadPath(
  ///   storageId: 'stor001',
  ///   relativePath: 'contratti/contratto.pdf',
  /// );
  /// await File('/tmp/contratto.pdf').writeAsBytes(bytes);
  /// ```
  Future<Uint8List> downloadPath({
    required String storageId,
    required String relativePath,
  }) async {
    // encode sicuro di ogni segmento (spazi, caratteri speciali) preservando gli slash
    final encoded = relativePath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');

    final url = Uri.parse(
      '$baseUrl/storage/$storageId/download/$encoded',
    );

    final res = await http.get(url);

    if (res.statusCode == 200) {
      return res.bodyBytes;              // file bytes (o zip bytes)
    }
    throw Exception('Download error (${res.statusCode}): ${res.body}');
  }


}

import 'dart:async';
import 'dart:io';
import 'package:blockchain_docuemnts_notarization/utils/notarization_api_sdk.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart'; // Pacchetto per selezione file
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';                    // NEW ✔
import 'package:file_saver/file_saver.dart'; // NEW ✔  (dipendenza: file_saver ^0.2.8)
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';       // per encoder ZIP
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

/*void main() {
  runApp(MyDocumentsApp());
}

class MyDocumentsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyDocumentsPage(),
    );
  }
}*/

class MyDocumentsPage extends StatefulWidget {
  @override
  _MyDocumentsPageState createState() => _MyDocumentsPageState();
}

class _MyDocumentsPageState extends State<MyDocumentsPage> {
  // Aggiungi una proprietà per istanziare lo SDK (se non è già presente)
final NotarizationApi api = NotarizationApi();
  /// Struttura iniziale delle cartelle
  final Map<String, dynamic> _folderStructure = <String, dynamic>{
    'I miei documenti': <String, dynamic>{
      
    }
  };

Uint8List _createZipWithSingleFile({
  required String fileName,
  required Uint8List fileBytes,
}) {
  // ➊ Crea un oggetto Archive e vi aggiunge il file
  final archive = Archive();
  archive.addFile(ArchiveFile(fileName, fileBytes.length, fileBytes));
  // ➋ Codifica l’Archive in formato ZIP
  final ZipEncoder encoder = ZipEncoder();
  final List<int> zipData = encoder.encode(archive)!;
  return Uint8List.fromList(zipData);
}
Future<void> _downloadItem({
  required String relativePath,   // "cartellaX/file.pdf" o "cartellaX"
  required bool   isFolder,
}) async {
  try {
    // ───── 1. Scarica i byte dal backend ───────────────────────────────
    final Uint8List fetchedBytes = await api.downloadPath(
      storageId   : _storageId,
      relativePath: relativePath,
    ); // :contentReference[oaicite:6]{index=6}

    // ───── 2. Determina il basename (ultimo segmento) ──────────────────
    final String nameSegment = relativePath.split('/').last; // "file.pdf" o "miaCartella"

    // ───── 3. Se è cartella, usa i byte direttamente (ZIP lato server) ─
    if (isFolder) {
      // Il backend ha già restituito un archivio ZIP se isFolder==true;
      // basta salvarlo con estensione .zip:
      await FileSaver.instance.saveFile(
        name: '$nameSegment',        // ad es. "miaCartella"
        bytes: fetchedBytes,          // byte dell’zip dal backend
        ext: 'zip',                 // suffisso che FileSaver userà per nomeFile.zip
        mimeType: MimeType.zip,// application/zip
      ); // :contentReference[oaicite:7]{index=7}

      _toast('Download cartella completato');
      return;
    }

    // ───── 4. Altrimenti, è un file singolo: creiamo in locale un ZIP ──
    //   4.1. Calcola l’estensione “vera” del file, minuscola, senza punto
    final String origExt = nameSegment.contains('.')
        ? nameSegment.split('.').last.toLowerCase()
        : ''; // es. "pdf" :contentReference[oaicite:8]{index=8}

    //   4.2. Componi l’archivio ZIP in memoria
    final Uint8List zipBytes = _createZipWithSingleFile(
      fileName: nameSegment,
      fileBytes: fetchedBytes,
    ); // :contentReference[oaicite:9]{index=9}

    // ───── 5. Salva il ZIP appena creato con FileSaver ────────────────
    await FileSaver.instance.saveFile(
      name: nameSegment,               // base name: "file.pdf" → salverà "file.pdf.zip"
      bytes: zipBytes,                  // bytes dell’archivio creato
      ext: 'zip',                     // suffisso (risulterà "file.pdf.zip")
      mimeType: MimeType.zip,    // application/zip :contentReference[oaicite:10]{index=10}
    );

    _toast('Download file compresso completato');
  } catch (e) {
    _toast('Errore download: $e');
  }
}



  // in cima alla classe _MyDocumentsPage  (subito dopo la dichiarazione di api)
static const String _storageId = 'fixed_storage_id';           // ➕  reference unica

/// Mostra un banner d’esito (riuso)
void _toast(String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// Restituisce il percorso relativo, esclusa la root ("I miei documenti").
String _currentFolderPath() {
  // Se siamo nella root → cartella vuota ("")
  if (_currentPath.length <= 1) return '';
  // Salta il primo elemento e unisci con "/"
  return _currentPath.sublist(1).join('/');
}
  /// Percorso attuale (root di default: "I miei documenti")
  List<String> _currentPath = ['I miei documenti'];

  /// Recupera il contenuto della cartella corrente
  Map<String, dynamic> get _currentFolder {
    Map<String, dynamic> folder = _folderStructure;
    for (String pathSegment in _currentPath) {
      final dynamic nextLevel = folder[pathSegment];
      if (nextLevel is Map<String, dynamic>) {
        folder = nextLevel;
      } else {
        throw Exception(
          'Il percorso "${_currentPath.join(' / ')}" non è valido o non è una cartella.',
        );
      }
    }
    return folder;
  }

  /// Naviga in una sottocartella
  void _navigateToFolder(String folderName) {
    final dynamic value = _currentFolder[folderName];
    if (value is Map<String, dynamic>) {
      setState(() {
        _currentPath.add(folderName);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La cartella "$folderName" non può essere aperta.'),
        ),
      );
    }
  }

  /// Torna alla cartella superiore
  void _navigateToParentFolder() {
    if (_currentPath.length > 1) {
      setState(() {
        _currentPath.removeLast();
      });
    }
  }

  /// Aggiunge una nuova cartella vuota
  void _addFolder() {
    showDialog(
      context: context,
      builder: (context) {
        String folderName = '';
        return AlertDialog(
          title: const Text('Nuova cartella'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Inserisci il nome della cartella',
            ),
            onChanged: (value) => folderName = value.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                if (folderName.isNotEmpty) {
                  setState(() {
                    _currentFolder[folderName] = <String, dynamic>{};
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );
  }
/// Converte {"cart1/file.txt": {...}, "c2/sf1/doc.pdf": {...}}
/// in {
///   "cart1": { "File": [ {...file.txt...} ] },
///   "c2": { "sf1": { "File": [ {...doc.pdf...} ] } }
/// }
Map<String, dynamic> buildTree(Map<String, dynamic> flat) {
  final tree = <String, dynamic>{};
  flat.forEach((fullPath, meta) {
    final segments = fullPath.split('/');                       // Stack O/F ‐ Path split :contentReference[oaicite:0]{index=0}
    final fileName = segments.removeLast();
    // Naviga/crea i livelli cartella
    Map<String, dynamic> cursor = tree;
    for (final seg in segments) {
      cursor = cursor.putIfAbsent(seg, () => <String, dynamic>{})
                     as Map<String, dynamic>;
    }
    // Assicura lista File
    cursor.putIfAbsent('File', () => <List<dynamic>>[]);
    (cursor['File'] as List).add({
      'type'      : (fileName.split('.').last).toUpperCase(),
      'name'      : fileName,
      'uploadedBy': 'YOU',            // oppure meta['uploader'] se disponibile
      'createdOn' : meta['upload_date'] ?? '',
    });
  });
  return tree;
}

  /// Upload di un file (selezionandolo dal computer)
Future<void> _uploadFile() async {
  // Utilizza FilePicker per selezionare un file
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.any,
  );

  if (result != null && result.files.isNotEmpty) {
    final PlatformFile pickedFile = result.files.first;
    final String fileName = pickedFile.name;

    // Ottieni i byte del file: se pickedFile.bytes è null, prova a leggerlo dal path
    final Uint8List fileBytes = pickedFile.bytes ?? await File(pickedFile.path!).readAsBytes();

    // Codifica il file in Base64
    final String fileBase64 = base64Encode(fileBytes);

    // Definisci uno storage ID fisso
    const String storageId = "fixed_storage_id";

    try {
      // Chiamata all'endpoint di notarizzazione (non vengono passati metadati extra: {} )
final String folderPath = _currentFolderPath();                  // ✅ NEW

await api.notarizeDocument(
  documentBase64: fileBase64,
  fileName      : fileName,
  storageId     : storageId,
  folderPath    : folderPath,                                    // ✅ NEW
  metadata      : {},
  selectedChain : ['algo'],
);

      // Dopo il successo della chiamata, aggiorna la struttura locale per visualizzare il file nella UI
      setState(() {
        // Se la chiave "File" non esiste o non è una lista, inizializzala
        if (!_currentFolder.containsKey('File') || _currentFolder['File'] is! List) {
          _currentFolder['File'] = <Map<String, dynamic>>[];
        }
        // Calcola la data di creazione in formato formattato
        final now = DateTime.now();
        final String createdOn = _formatDateTime(now);
        // Determina il tipo (estensione) del file in maiuscolo, oppure usa "FILE" se non disponibile
        final String fileType = (pickedFile.extension ?? 'FILE').toUpperCase();
        // Aggiungi il nuovo file alla lista locale
        (_currentFolder['File'] as List).add({
          'type': fileType,
          'name': fileName,
          'uploadedBy': 'YOU',
          'createdOn': createdOn,
        });
      });

      // Mostra un messaggio di successo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Documento "$fileName" notarizzato con successo!')),
      );
    } catch (e) {
      // In caso di errore, mostra un messaggio di errore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la notarizzazione: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nessun file selezionato.')),
    );
  }
}

  /// Helper per formattare data e ora (es. "4 Feb 2025, 14:05")
  String _formatDateTime(DateTime dt) {
    final giorno = dt.day.toString();
    final mesi = [
      'Gen',
      'Feb',
      'Mar',
      'Apr',
      'Mag',
      'Giu',
      'Lug',
      'Ago',
      'Set',
      'Ott',
      'Nov',
      'Dic'
    ];
    final meseAbbrev = mesi[dt.month - 1];
    final anno = dt.year.toString();
    final ore = dt.hour.toString().padLeft(2, '0');
    final minuti = dt.minute.toString().padLeft(2, '0');
    return '$giorno $meseAbbrev $anno, $ore:$minuti';
  }

@override
void initState() {
  super.initState();
  _refreshFromBackend();                                         // ✏️ NUOVO
}

/// Scarica tutta la gerarchia dal backend e rimpiazza la root locale
Future<void> _refreshFromBackend() async {
  const storageId = 'fixed_storage_id';
  try {
    final listing = await api.listStorage(storageId: storageId); // ➕
    setState(() {
      _folderStructure['I miei documenti'] = buildTree(listing); // ➕
      _currentPath = ['I miei documenti'];                       // reset view
    });
  } catch (e) {
    // Gestisci l’errore (toast, log…)
  }
}

/* ---------------------------------------------------------------
   Rinomina file o cartella
   -------------------------------------------------------------*/
Future<void> _renameItem({
  required String oldPath,   // "cart1/file.pdf"  oppure "cart1"
  required String newName,
}) async {
  try {
    await api.renamePath(
      storageId: _storageId,
      oldPath  : oldPath,
      newName  : newName,
    );
    await _refreshFromBackend();
    _toast('Rinominato con successo');
  } catch (e) {
    _toast('Errore rinomina: $e');
  }
}

/* ---------------------------------------------------------------
   Sposta file / cartella
   -------------------------------------------------------------*/
Future<void> _moveItem({
  required String sourcePath,
  required String destFolder,  // "" per root
}) async {
  try {
    await api.movePath(
      storageId : _storageId,
      sourcePath: sourcePath,
      destFolder: destFolder,
    );
    await _refreshFromBackend();
    _toast('Spostato con successo');
  } catch (e) {
    _toast('Errore spostamento: $e');
  }
}

/* ---------------------------------------------------------------
   Elimina file / cartella
   -------------------------------------------------------------*/
Future<void> _deleteItem({
  required String targetPath,
  required bool recursive,
}) async {
  try {
    await api.deletePath(
      storageId : _storageId,
      targetPath: targetPath,
      recursive : recursive,
    );
    await _refreshFromBackend();
    _toast('Eliminato');
  } catch (e) {
    _toast('Errore eliminazione: $e');
  }
}

Future<void> _showRenameDialog({
  required String fullPath,      // vecchio path
  required bool isFile,
}) async {
  final oldName = fullPath.split('/').last;
  String newName = oldName;
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Rinomina'),
      content: TextField(
        controller: TextEditingController(text: oldName),
        onChanged: (v) => newName = v.trim(),
        decoration: InputDecoration(
          hintText: isFile ? 'nome.ext' : 'nome cartella',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (newName.isNotEmpty && newName != oldName) {
              _renameItem(oldPath: fullPath, newName: newName);
            }
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Widget _buildPageBody() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* ⬅️  qui dentro rimane *identico* tutto ciò che avevi
           (sezioni Cartelle, Files, ListView, ecc.) */
      ],
    ),
  );
}


Future<void> _showMoveDialog({
  required String sourcePath,
}) async {
  String destFolder = '';
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Sposta in…'),
      content: TextField(
        onChanged: (v) => destFolder = v.trim(),
        decoration: const InputDecoration(
          hintText: 'Percorso cartella di destinazione (es. abc/nuova)',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _moveItem(sourcePath: sourcePath, destFolder: destFolder);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> _showDeleteDialog({
  required String targetPath,
  required bool isFolder,
}) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Conferma eliminazione'),
      content: Text(
        'Vuoi eliminare definitivamente '
        '${isFolder ? "la cartella" : "il file"} “${targetPath.split('/').last}”?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(context);
            _deleteItem(targetPath: targetPath, recursive: true);
          },
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
}

Widget _buildTopBar() {
  return Material(          // per ombra leggera
    elevation: 2,
    color: Colors.white,
    child: SafeArea(        // gestisce notch / status-bar
      bottom: false,        // non serve padding sotto
      child: Container(
        height: 56,         // altezza simile ad AppBar
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // ← pulsante “indietro” solo se non siamo in root
            if (_currentPath.length > 1)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _navigateToParentFolder,
                tooltip: 'Indietro',
              ),

            // titolo (percorso)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Percorso attuale:',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  _currentPath.join(' / '),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Spacer(),      // spinge le azioni a destra

            // pulsante “Nuova cartella”
            TextButton.icon(
              
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF66A3FF), //Colors.blue, //Colors.grey.shade800,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
                    shape: RoundedRectangleBorder(               // <-- qui
      borderRadius: BorderRadius.circular(2),    //    raggio 2 px
    ),
              ),
              onPressed: _addFolder,
              icon: const Icon(Icons.create_new_folder),
              label: const Text('Nuova cartella'),
            ),
            const SizedBox(width: 8),

            // pulsante “Carica file”
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF66A3FF), //Colors.blue, //Colors.grey.shade800,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
                    shape: RoundedRectangleBorder(               // <-- qui
      borderRadius: BorderRadius.circular(2),    //    raggio 2 px
    ),
              ),
              onPressed: _uploadFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Carica file'),
            ),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    // Cartelle presenti (escludendo la chiave "File")
    final folderNames =
        _currentFolder.keys.where((key) => key != 'File').toList();

    // Lista dei file (o vuota se non presente)
    final List files = _currentFolder['File'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white, // Sfondo totale bianco
      /*appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentPath.length > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _navigateToParentFolder,
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Percorso attuale:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              _currentPath.join(' / '),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Pulsante "Nuova cartella" - GRIGIO SCURO, TESTO E ICONA BIANCHE
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
              iconColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: _addFolder,
            icon: const Icon(Icons.create_new_folder),
            label: const Text('Nuova cartella'),
          ),
          const SizedBox(width: 8),

          // Pulsante "Carica file" - GRIGIO SCURO, TESTO E ICONA BIANCHE
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
              iconColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: _uploadFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Carica file'),
          ),
          const SizedBox(width: 16),
        ],
      ),*/
      body: Column(
      children: [
        _buildTopBar(),        // nuova barra personalizzata
        Expanded(child:  Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sezione Cartelle
            const Text(
              'Cartelle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            folderNames.isEmpty
                ? const Text(
                    'Nessuna cartella disponibile',
                    style: TextStyle(color: Colors.grey),
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: folderNames.map((folderName) {
                      return FolderCard(
                        folderName: folderName,
                        onTap: () => _navigateToFolder(folderName),
                          onRename  : () => _showRenameDialog(
                     fullPath : '${_currentFolderPath()}/$folderName'.replaceFirst(RegExp(r'^/'), ''),
                     isFile : false,
                   ),                                           // ➕
  onMove    : () => _showMoveDialog(
                     sourcePath: '${_currentFolderPath()}/$folderName'.replaceFirst(RegExp(r'^/'), ''),
                   ),                                           // ➕
  onDelete  : () => _showDeleteDialog(
                     targetPath: '${_currentFolderPath()}/$folderName'.replaceFirst(RegExp(r'^/'), ''),
                     isFolder : true,
                   ),
  onDownload: () => _downloadItem(                         // NEW ✔
                     relativePath: '${_currentFolderPath()}/$folderName'.replaceFirst(RegExp(r'^/'), ''),
                     isFolder   : true,
                   ),                                           // ➕
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),

            // Sezione Files
            const Text(
              'Files',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Barra di intestazione (5 colonne)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Nome del documento',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Caricato da',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Condiviso con',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Firmato da',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Creato il',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: files.isEmpty
                  ? const Text(
                      'Nessun file disponibile',
                      style: TextStyle(color: Colors.grey),
                    )
                  : ListView.builder(
  itemCount: files.length,
  itemBuilder: (context, index) {
    final file = files[index];
    return FileCard(
      fileType: file['type'],
      fileName: file['name'],
      uploadedBy: file['uploadedBy'],
      createdOn: file['createdOn'],
      onTap: () => _showFileDetailsDialog(context, _currentFolderPath(),file), // Passa l'azione
        onRename: () => _showRenameDialog(
                   fullPath : '${_currentFolderPath()}/${file['name']}'.replaceFirst(RegExp(r'^/'), ''),
                   isFile   : true,
                 ),                                             // ➕
  onMove  : () => _showMoveDialog(
                   sourcePath: '${_currentFolderPath()}/${file['name']}'.replaceFirst(RegExp(r'^/'), ''),
                 ),                                             // ➕
  onDelete: () => _showDeleteDialog(
                   targetPath: '${_currentFolderPath()}/${file['name']}'.replaceFirst(RegExp(r'^/'), ''),
                   isFolder  : false,
                 ),
  onDownload: () => _downloadItem(                         // NEW ✔
                     relativePath: '${_currentFolderPath()}/${file['name']}'.replaceFirst(RegExp(r'^/'), ''),
                     isFolder   : true,
                   ),                                          // ➕
    );
  },
),
            ),
          ],
        ),
      ),
    )]));
  }
}

/// SCHEDA CARTELLA (Stateful) -----------------------------------------------
class FolderCard extends StatefulWidget {
  final String folderName;
  final VoidCallback onTap;
  final VoidCallback onRename;   // ➕
  final VoidCallback onMove;     // ➕
  final VoidCallback onDelete;   // ➕
  final VoidCallback onDownload;     // NEW ✔

  const FolderCard({
    Key? key,
    required this.folderName,
    required this.onTap,
        required this.onRename,
            required this.onMove,
                required this.onDelete,
                required this.onDownload
  }) : super(key: key);

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  bool _isHovered = false;
  bool _isSelected = false;

/// Mostra un dialog con le tre azioni standard.
/// [context] = BuildContext da cui si invoca
/// [onRename] / [onMove] / [onDelete] = callback da eseguire
Future<void> showActionsDialog({
  required BuildContext context,
  required VoidCallback onRename,
  required VoidCallback onMove,
  required VoidCallback onDelete,
  required VoidCallback onDownload, 
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,        // si chiude toccando fuori
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      title: const Text('Azioni'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            ListTile(                               // NEW ✔
    leading: const Icon(Icons.download),
    title  : const Text('Scarica'),
    onTap  : () { Navigator.pop(context); onDownload(); },
  ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: const Text('Rinomina'),
            onTap: () { Navigator.pop(context); onRename(); },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move),
            title: const Text('Sposta'),
            onTap: () { Navigator.pop(context); onMove(); },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Elimina', style: TextStyle(color: Colors.red)),
            onTap: () { Navigator.pop(context); onDelete(); },
          ),
        ],
      ),
    ),
  );
}


void _openActions() {
  showActionsDialog(
    context: context,
    onRename: widget.onRename,
    onMove  : widget.onMove,
    onDelete: widget.onDelete,
    onDownload: widget.onDownload,   // NEW ✔
  );
}



  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        children: [
          // Contenuto principale della card (cartella)
          Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: _isHovered ? 8 : 4,
                  offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
                ),
              ],
            ),
            // Rilevamento tap per navigare nella cartella
            child: InkWell(
              onTap: widget.onTap,
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Colors.blue, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.folderName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Checkbox in alto a sinistra (visibile solo in hover o se selezionato)
          if (_isHovered || _isSelected)
            Positioned(
              top: 4,
              left: 4,
              child: Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: _isSelected,
                  onChanged: (val) {
                    setState(() => _isSelected = val ?? false);
                  },
                  fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.blue; // Colore quando è selezionato
                    }
                    return Colors.white; // Sfondo bianco nel quadratino
                  }),
                  checkColor: Colors.black, // Spunta nera
                  side: const BorderSide(color: Colors.black), // Bordo nero attorno al quadrato
                ),
              ),
            ),

          // Stella e Menu a 3 pallini in alto a destra (visibili in hover o selezionato)
          if (_isHovered || _isSelected)
            Positioned(
              right: 4,
              child: Row(
                children: [
IconButton(
  icon: const Icon(Icons.more_vert),
  onPressed: _openActions,
)

                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// SCHEDA FILE (Stateful) -----------------------------------------------
class FileCard extends StatefulWidget {
  final String fileType;
  final String fileName;
  final String uploadedBy;
  final String createdOn;
  final VoidCallback onTap; // Aggiungi parametro onTap
  final VoidCallback onRename;   // ➕
  final VoidCallback onMove;     // ➕
  final VoidCallback onDelete;   // ➕
  final VoidCallback onDownload;     // NEW ✔

  const FileCard({
    Key? key,
    required this.fileType,
    required this.fileName,
    required this.uploadedBy,
    required this.createdOn,
    required this.onTap, // Inizializza onTap
    required this.onRename,
    required this.onMove,
    required this.onDelete, 
    required this.onDownload,
  }) : super(key: key);

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  bool _isHovered = false;
  bool _isSelected = false;

  /// Metodo per mostrare il dialog con i dettagli
  /*void _showFileDetailsDialog(BuildContext context, Map<String, dynamic> file) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Angoli arrotondati a 4
        ),
        child: Stack(
          children: [
            // Contenitore principale
            Container(
              color: Colors.white, // Sfondo bianco
              padding: const EdgeInsets.all(16), // Margine interno uniforme
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonna sinistra
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Firme video biometriche
                        const Text(
                          'Firme video biometriche',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                alignment: Alignment.centerLeft,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Ancora nessuna firma applicata',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {}, // Placeholder per azione "Firma"
                              child: const Text('Firma'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Firme grafiche
                        const Text(
                          'Firme grafiche',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                alignment: Alignment.centerLeft,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Ancora nessuna firma applicata',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {}, // Placeholder per azione "Firma"
                              child: const Text('Firma'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Registro attività
                        const Text(
                          'Registro attività',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Visualizzazioni
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      '0',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Visualizzazioni',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Download
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      '0',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Download',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Firme
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      '0',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Firme',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16), // Spaziatura tra colonne

                  // Colonna destra
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dettagli
                        const Text(
                          'Dettagli',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Hash (SHA256):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  '640a6...acd5d',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy,
                                      color: Colors.grey, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(const ClipboardData(
                                        text: "640a6...acd5d"));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Hash copiato negli appunti'),
                                      ),
                                    );
                                  },
                                  tooltip: 'Copia',
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Caricato da:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'simone.sansalone@cyberneid.com (io)',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Caricato il:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '4 Feb 2025, 05:27',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Validazioni
                        const Text(
                          'Validazioni',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildValidationCard('Solana', '4 Feb 2025, 05:28'),
                        const SizedBox(height: 8),
                        _buildValidationCard('Ton', '4 Feb 2025, 07:00'),
                        const SizedBox(height: 16),

                        // Certificato
                        const Text(
                          'Certificato',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Certificato di autenticità',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextButton.icon(
                              onPressed: () {}, // Placeholder per download
                              icon: const Icon(Icons.download,
                                  color: Colors.blue),
                              label: const Text(
                                'Scarica',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pulsante di chiusura in alto a destra
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Helper per creare una scheda di validazione
Widget _buildValidationCard(String name, String date) {
  return Container(
    height: 40,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(date),
      ],
    ),
  );
}*/


/// Mostra un dialog con le tre azioni standard.
/// [context] = BuildContext da cui si invoca
/// [onRename] / [onMove] / [onDelete] = callback da eseguire
Future<void> showActionsDialog({
  required BuildContext context,
  required VoidCallback onRename,
  required VoidCallback onMove,
  required VoidCallback onDelete,
  required VoidCallback onDownload, 
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,        // si chiude toccando fuori
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      title: const Text('Azioni'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            ListTile(                               // NEW ✔
    leading: const Icon(Icons.download),
    title  : const Text('Scarica'),
    onTap  : () { Navigator.pop(context); onDownload(); },
  ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: const Text('Rinomina'),
            onTap: () { Navigator.pop(context); onRename(); },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move),
            title: const Text('Sposta'),
            onTap: () { Navigator.pop(context); onMove(); },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Elimina', style: TextStyle(color: Colors.red)),
            onTap: () { Navigator.pop(context); onDelete(); },
          ),
        ],
      ),
    ),
  );
}


void _openActions() {
  showActionsDialog(
    context: context,
    onRename: widget.onRename,
    onMove  : widget.onMove,
    onDelete: widget.onDelete,
    onDownload: widget.onDownload
  );
}


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap, // Apri dialog al clic
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Stack(
          children: [
            // Contenuto principale della card (file)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: _isHovered ? 8 : 4,
                    offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Prima colonna (flex:3) -> Icona + Nome file
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.fileType == 'HTML'
                                ? Colors.orange.shade100
                                : (widget.fileType == 'PDF'
                                    ? Colors.red.shade100
                                    : Colors.green.shade100),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.fileType,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.fileName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Seconda colonna (flex:1) -> Caricato da
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        radius: 16,
                        child: Text(
                          widget.uploadedBy,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Terza colonna (flex:1) -> Condiviso con
                  const Expanded(
                    flex: 1,
                    child: Text(
                      '-',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Quarta colonna (flex:1) -> Firmato da
                  const Expanded(
                    flex: 1,
                    child: Text(
                      '-',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Quinta colonna (flex:1) -> Creato il
                  Expanded(
                    flex: 1,
                    child: Text(
                      widget.createdOn,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox in alto a sinistra (visibile in hover o se selezionato)
            if (_isHovered || _isSelected)
              Positioned(
                top: 4,
                left: 4,
                child: Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: _isSelected,
                    onChanged: (val) {
                      setState(() => _isSelected = val ?? false);
                    },
                    fillColor: MaterialStateProperty.resolveWith<Color>(
                      (states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.blue; // Colore quando è selezionato
                        }
                        return Colors.white; // Sfondo bianco nel quadratino
                      },
                    ),
                    checkColor: Colors.black, // Spunta nera
                    side: const BorderSide(
                      color: Colors.black,
                    ), // Bordo nero attorno al quadrato
                  ),
                ),
              ),

            // Stella e Menu a 3 pallini in alto a destra (visibili in hover o selezionato)
            if (_isHovered || _isSelected)
              Positioned(
                right: 4,
                child: Row(
                  children: [
IconButton(
  icon: const Icon(Icons.more_vert),
  onPressed: _openActions,
)

                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}



/* ════════════════════════════════════════════════════════════════════ */
/* 1. FUNZIONE DI UTILITÀ – da chiamare dove prima usavi _showFileDetailsDialog */
void _showFileDetailsDialog(
  BuildContext context,
  String folderPath,
  Map<String, dynamic> file,
) {
  showDialog(
    context: context,
    barrierDismissible: false,          // click fuori non chiude
    builder: (_) => _FileDetailsDialog(
      storageId : _MyDocumentsPageState._storageId,   // costante già definita
      folderPath: folderPath,
      fileName  : file['name'],
    ),
  );
}

/* ════════════════════════════════════════════════════════════════════ */
/* 2. WIDGET STATEFUL CON POLLING E UI COMPLETA */
class _FileDetailsDialog extends StatefulWidget {
  final String storageId;
  final String folderPath;
  final String fileName;
  const _FileDetailsDialog({
    Key? key,
    required this.storageId,
    required this.folderPath,
    required this.fileName,
  }) : super(key: key);

  @override
  State<_FileDetailsDialog> createState() => _FileDetailsDialogState();
}

class _FileDetailsDialogState extends State<_FileDetailsDialog> {
  final NotarizationApi _api = NotarizationApi();
  late Timer _timer;
  Map<String, dynamic>? _meta;           // ultimo JSON ricevuto

  @override
  void initState() {
    super.initState();
    _fetch();                            // prima chiamata immediata
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetch(),                   // polling ogni 3 s
    );
  }

  Future<void> _fetch() async {
    try {
      final data = await _api.queryDocument(
        storageId    : widget.storageId,
        folderPath   : widget.folderPath,
        fileName     : widget.fileName,
        selectedChain: const ['algo'],
      );
      if (!mounted) return;
      setState(() => _meta = data);

      // se almeno una validazione presente → stop polling
      if ((data['validations'] as List).isNotEmpty) _timer.cancel();
    } catch (e) {
      // gestisci errore di rete qui se vuoi (snackbar, ecc.)
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }


void _showTxDetail(Map<String, dynamic> tx) {
  showDialog(
    context: context,
    builder: (_) {
      final rows = <List<String>>[
        ['TxID',            tx['txid']?.toString()           ?? '—'],
        ['Round conferma',  tx['confirmed_round']?.toString()?? '—'],
        ['Fee (µAlgo)',     tx['fee']?.toString()            ?? '—'],
        ['First valid',     tx['first_valid']?.toString()    ?? '—'],
        ['Last valid',      tx['last_valid']?.toString()     ?? '—'],
        ['Round time',      tx['round_time']?.toString()     ?? '—'],
        ['Sender',          tx['sender']?.toString()         ?? '—'],
        ['Receiver',        tx['receiver']?.toString()       ?? '—'],
        ['Note',            tx['note']?.toString()           ?? '—'],
      ];

      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /* coppie chiave-valore */
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          row[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: SelectableText(
                          row[1],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              /* link DataXplore */
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://dataxplore.net/?documentHash='),
                    mode: LaunchMode.platformDefault,      // OK per web
                    webOnlyWindowName: '_blank',           // nuova scheda
                  ),
                  child: const Text(
                    'Apri in DataXplore',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      );
    },
  );
}

  /* ───────────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    // ➊ Spinner finché non arriva il primo risultato
    if (_meta == null) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // ➋ Dati di comodo
    final List validations = _meta!['validations'] ?? [];
    final String hash      = _meta!['document_hash'] ?? '---';
    final String uploadDt  = _meta!['upload_date']   ?? '---';

    return Dialog(
            insetPadding: EdgeInsets.symmetric(                // ⬅︎ UPDATE
        horizontal: MediaQuery.of(context).size.width * .08,
        vertical:   32,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Stack(
        children: [
          /* ───────────────── CONTENITORE PRINCIPALE ───────────────── */
          Container(                                     // ⬅︎ UPDATE
            color: Colors.white,
            padding: const EdgeInsets.all(64),           // stesso margine della tua UI originaria
            width: MediaQuery.of(context).size.width
                   .clamp(860, double.infinity),         // riempie, minimo 860 px
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /* COLONNA SINISTRA (come tua UI precedente) */
                /*Expanded(
                  flex: 2,
                  child: _buildLeftColumn(),
                ),
                const SizedBox(width: 24),*/
                /* COLONNA DESTRA – hash, validazioni dinamiche */
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dettagli',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      _infoRow('Hash (SHA256):', hash),
 _infoRow('Caricato il:', uploadDt),
  _infoRow('Caricato da:',                           // ⬅︎ ADD
           _meta!['uploader'] ??                     // se in metadata
           'simone.sansalone@cyberneid.com (io)'),   // fallback stesso testo di prima
                      const SizedBox(height: 24),
                      const Text('Validazioni',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (validations.isEmpty)
                        const ListTile(
                          leading: Icon(Icons.hourglass_empty),
                          title: Text('Algorand'),
                          subtitle: Text('In attesa di conferma…'),
                        )
                      else
                        ...validations.map<ListTile>((tx) {
                          final bool confirmed =
                              tx['confirmed_round'] != null;
                          final String subtitle = confirmed
                              ? 'Round ${tx['confirmed_round']}'
                              : 'In attesa di conferma…';
                          return ListTile(
                            leading: Icon(
                              confirmed
                                  ? Icons.check_circle
                                  : Icons.hourglass_empty,
                              color: confirmed ? Colors.green : null,
                            ),
                            title: const Text('Algorand'),
                            subtitle: Text(subtitle),
                            onTap: () => _showTxDetail(tx),
                          );
                        }).toList(),
                      const SizedBox(height: 24),
                      /* Sezione certificato come prima */
                      const Text('Certificato',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Certificato di autenticità'),
                          TextButton.icon(
                            onPressed: () {},       // TODO: download
                            icon: const Icon(Icons.download, color: Colors.blue),
                            label: const Text('Scarica',
                                style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /* ────────────────── PULSANTE CHIUSURA ────────────────── */
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  /* Helper UI – riga info */
  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                flex: 2,
                child: Text(label,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(                                          // ⬅︎ UPDATE
        flex: 3,
        child: Row(
          children: [
            Flexible(                               // ✅ sostituisce Expanded
                          child: SelectableText(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,                        // tronca comunque a una riga
              ),
            ),
            if (value != '---')                          // mostra copia solo se c’è valore
              IconButton(                                // ⬅︎ ADD
                icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                splashRadius: 20,
                tooltip: 'Copia',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copiato negli appunti')),
                  );
                },
              ),
          ],
        ),
      ),
         ],
        ),
      );

  /* Stub grafico per la colonna sinistra: ri-usa la tua vecchia UI */
  Widget _buildLeftColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Firme video biometriche',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Container(
                height: 40,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Ancora nessuna firma applicata',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4))),
              child: const Text('Firma'),
            ),
          ]),
          const SizedBox(height: 24),
          const Text('Firme grafiche',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Container(
                height: 40,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Ancora nessuna firma applicata',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4))),
              child: const Text('Firma'),
            ),
          ]),
          const SizedBox(height: 24),
          const Text('Registro attività',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(children: [
            _statBox('0', 'Visualizzazioni'),
            const SizedBox(width: 8),
            _statBox('0', 'Download'),
            const SizedBox(width: 8),
            _statBox('0', 'Firme'),
          ]),
        ],
      );

  /* mini card statistica */
  Widget _statBox(String num, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(num,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}


/// Helper per creare una scheda di validazione
Widget _buildValidationCard(String name, String date) {
  return Container(
    height: 40,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(date),
      ],
    ),
  );
}




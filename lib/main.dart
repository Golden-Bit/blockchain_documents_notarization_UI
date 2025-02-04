import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart'; // Pacchetto per selezione file

void main() {
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
}

class MyDocumentsPage extends StatefulWidget {
  @override
  _MyDocumentsPageState createState() => _MyDocumentsPageState();
}

class _MyDocumentsPageState extends State<MyDocumentsPage> {
  /// Struttura iniziale delle cartelle
  final Map<String, dynamic> _folderStructure = <String, dynamic>{
    'I miei documenti': <String, dynamic>{
      'abc': <String, dynamic>{}, // Cartella vuota
      'un altra cartella': <String, dynamic>{}, // Cartella vuota
      'File': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'HTML',
          'name': 'chatbot_docs_v2_it.html',
          'uploadedBy': 'SS',
          'createdOn': '4 Feb 2025, 05:30',
        },
        <String, dynamic>{
          'type': 'PDF',
          'name': 'conferma_ord.pdf',
          'uploadedBy': 'SS',
          'createdOn': '4 Feb 2025, 05:27',
        },
      ],
    }
  };

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

  /// Upload di un file (selezionandolo dal computer)
  Future<void> _uploadFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      final PlatformFile pickedFile = result.files.first;
      final String fileName = pickedFile.name;
      final String? extension = pickedFile.extension;
      final String fileType = (extension ?? 'FILE').toUpperCase();

      setState(() {
        // Assicuriamoci che la chiave "File" sia presente e sia una lista
        if (!_currentFolder.containsKey('File') ||
            _currentFolder['File'] is! List) {
          _currentFolder['File'] = <Map<String, dynamic>>[];
        }

        final now = DateTime.now();
        final createdOn = _formatDateTime(now);

        (_currentFolder['File'] as List).add(<String, dynamic>{
          'type': fileType,
          'name': fileName,
          'uploadedBy': 'YOU',
          'createdOn': createdOn,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File "$fileName" caricato con successo!')),
      );
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
  Widget build(BuildContext context) {
    // Cartelle presenti (escludendo la chiave "File")
    final folderNames =
        _currentFolder.keys.where((key) => key != 'File').toList();

    // Lista dei file (o vuota se non presente)
    final List files = _currentFolder['File'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white, // Sfondo totale bianco
      appBar: AppBar(
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
      ),
      body: Padding(
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
      onTap: () => _showFileDetailsDialog(context, file), // Passa l'azione
    );
  },
),
            ),
          ],
        ),
      ),
    );
  }
}

/// SCHEDA CARTELLA (Stateful) -----------------------------------------------
class FolderCard extends StatefulWidget {
  final String folderName;
  final VoidCallback onTap;

  const FolderCard({
    Key? key,
    required this.folderName,
    required this.onTap,
  }) : super(key: key);

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  bool _isHovered = false;
  bool _isSelected = false;

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
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      // Placeholder per possibili azioni
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selezionata: $value')),
                      );
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'Opzione 1',
                        child: Text('Opzione 1'),
                      ),
                      const PopupMenuItem(
                        value: 'Opzione 2',
                        child: Text('Opzione 2'),
                      ),
                    ],
                  ),
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

  const FileCard({
    Key? key,
    required this.fileType,
    required this.fileName,
    required this.uploadedBy,
    required this.createdOn,
    required this.onTap, // Inizializza onTap
  }) : super(key: key);

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  bool _isHovered = false;
  bool _isSelected = false;

  /// Metodo per mostrare il dialog con i dettagli
  void _showFileDetailsDialog(BuildContext context, Map<String, dynamic> file) {
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
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        // Placeholder per possibili azioni
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selezionata: $value')),
                        );
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'Opzione 1',
                          child: Text('Opzione 1'),
                        ),
                        const PopupMenuItem(
                          value: 'Opzione 2',
                          child: Text('Opzione 2'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showFileDetailsDialog(BuildContext context, Map<String, dynamic> file) {
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
              padding: const EdgeInsets.all(64), // Margine interno uniforme
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
}

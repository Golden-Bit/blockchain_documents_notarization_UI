import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

/// Una pagina che espone i principali casi d'uso in griglia fluida,
/// con vero drag‑and‑drop (web e desktop) e dialog di istruzioni.
class UseCasesPage extends StatelessWidget {
  const UseCasesPage({Key? key}) : super(key: key);

  static const double _borderRadius = 4;

  @override
  Widget build(BuildContext context) {
    final cases = [
      _UseCase(
        icon: Icons.videocam,
        title: 'Notarizza un video',
        description: 'Verifica video d’identità su blockchain',
      ),
      _UseCase(
        icon: Icons.description,
        title: 'Notarizza un contratto',
        description: 'Carica il tuo contratto legale',
      ),
      _UseCase(
        icon: Icons.image,
        title: 'Notarizza un’immagine',
        description: 'Documenta visivamente prove fotografiche',
      ),
      _UseCase(
        icon: Icons.insert_drive_file,
        title: 'Notarizza un documento',
        description: 'PDF, Word, testo e altro',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: cases.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 600,   // max 300px
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 3 / 2,
          ),
          itemBuilder: (context, index) {
            final uc = cases[index];

            // controller per il dropzone
            return _UseCaseCard(useCase: uc);
          },
        ),
      ),
    );
  }
}

/// Widget che incapsula una singola scheda con Dropzone
class _UseCaseCard extends StatefulWidget {
  final _UseCase useCase;
  const _UseCaseCard({required this.useCase, Key? key}) : super(key: key);

  @override
  State<_UseCaseCard> createState() => _UseCaseCardState();
}

class _UseCaseCardState extends State<_UseCaseCard> {
  late DropzoneViewController _dz;
  bool _highlight = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400),
      child: Stack(
        children: [
          // DropzoneView dietro la carta

        // DropzoneView *sopra* la carta, invisibile ma cattura il drop
        Positioned.fill(
          child: DropzoneView(
             onCreated: (ctrl) => _dz = ctrl,
             onLoaded: () {},
             onError: (e) => debugPrint('Dropzone error: $e'),
             onHover: () => setState(() => _highlight = true),
             onLeave: () => setState(() => _highlight = false),
             onDrop: (ev) async {
               final name = await _dz.getFilename(ev);
               Navigator.of(context).pop();
               _showUseCaseDialog(context, widget.useCase.title, name);
             },
            // IMPORTANT: fai sì che il widget sia "hitTestable" e invisibile
            mime: ['*/*'],
            operation: DragOperation.copy,
           ),
        ),

          // Material card con elevazione
          Material(
            elevation: _highlight ? 8 : 2,
            borderRadius: BorderRadius.circular(UseCasesPage._borderRadius),
            color: Colors.white,
            child: InkWell(
              onTap: () => _showUseCaseDialog(context, widget.useCase.title, null),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.useCase.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.useCase.description,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(widget.useCase.icon, size: 32, color: Colors.blue),
                                const SizedBox(width: 16),
                                Icon(Icons.upload_file, size: 48, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Trascina qui il file o clicca per avviare',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUseCaseDialog(BuildContext context, String title, String? fileName) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UseCasesPage._borderRadius),
        ),
        backgroundColor: Colors.white,
        title: Text(title),
        content: Text(
          fileName != null
              ? 'Hai rilasciato: $fileName\n\nProcedi con la notarizzazione.'
              : 'Rilascia il file qui per iniziare.\n\nRiceverai istruzioni.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UseCasesPage._borderRadius),
              ),
            ),
            onPressed: () {
              // TODO: collegare flusso concreto
              Navigator.of(context).pop();
            },
            child: const Text('Continua'),
          ),
        ],
      ),
    );
  }
}

class _UseCase {
  final IconData icon;
  final String title;
  final String description;
  const _UseCase({
    required this.icon,
    required this.title,
    required this.description,
  });
}

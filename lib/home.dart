// main.dart
import 'package:blockchain_docuemnts_notarization/use_cases_page.dart';
import 'package:blockchain_docuemnts_notarization/user_manager/components/settings_dialog.dart';
import 'package:blockchain_docuemnts_notarization/user_manager/pages/login_page_1.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_content.dart';           // <-  contiene MyDocumentsPage()
import 'dart:html' as html;

enum _SideItem { home, myDocs, safebox, shared, recent, important, trash }
enum _TopTab   { docs, templates, contacts }

class HomeScaffold extends StatefulWidget {
   final String accessToken;

   const HomeScaffold({
     Key? key,
     required this.accessToken,
   }) : super(key: key);

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  _SideItem _selectedSide = _SideItem.home;
  _TopTab   _selectedTab  = _TopTab.docs;
  final TextEditingController _search = TextEditingController();

  /* ---------------- TOP-BAR ---------------- */
  Widget _buildTopBar() {
    Widget topTab(String label, _TopTab tab,
        {bool lock = false}) {
      final bool active = _selectedTab == tab;
      return InkWell(
        onTap: () => setState(() => _selectedTab = tab),
        splashFactory: NoSplash.splashFactory,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: active
                ? Border.all(color: Colors.white, width: 1)
                : null,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade200,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  )),
              if (lock)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.lock_outline,
                      size: 15, color: Colors.white70),
                ),
            ],
          ),
        ),
      );
    }

    Widget vDivider() => Container(
          width: 1,
          height: 40,
          color: Colors.white.withOpacity(.4),
        );

    return Material(
      color: const Color(0xFF66A3FF),
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              /* ------------- Logo ------------- */
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .5),
                  children: [
                    const TextSpan(text: 'App Name', style: TextStyle(color: Colors.white))
                  ],
                ),
              ),
              const SizedBox(width: 32),

              /* ------------- Tabs ------------- */
              topTab('Documenti', _TopTab.docs),
              const SizedBox(width: 24),
              topTab('Modelli', _TopTab.templates),
              //const SizedBox(width: 24),
              //topTab('Contatti', _TopTab.contacts, lock: true),

              const Spacer(),

              /* ------------- Search ------------- */
              SizedBox(
                width: 260,
                height: 40,
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: Colors.black),
                  onSubmitted: (v) => debugPrint('search: $v'),
                  decoration: InputDecoration(
                    hintText: 'Cerca file o cartelle',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: Icon(Icons.search,
                        size: 20, color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              /* ------------- Lingua ------------- */
              vDivider(),
              const SizedBox(width: 16),
_LanguageMenu(
  current: 'it',               // o la variabile di stato che usi
  onChange: (lang) {
    debugPrint('cambia lingua → $lang');
    // TODO: aggiorna lo stato / provider / localizzazione
    setState(() {/* memorizza nuova lingua */});
  },
),

              const SizedBox(width: 16),
              vDivider(),

              /* ------------- Help & Bell ------------- */
              IconButton(
                icon: const Icon(Icons.help_outline,
                    color: Colors.white, size: 24),
                tooltip: 'Aiuto',
                onPressed: () => debugPrint('help'),
              ),
              vDivider(),
              IconButton(
                icon: const Icon(Icons.notifications_none,
                    color: Colors.white, size: 24),
                tooltip: 'Notifiche',
                onPressed: () => debugPrint('notifiche'),
              ),
              vDivider(),

              /* ------------- Avatar + Nome ------------- */
              const SizedBox(width: 12),
              _UserMenu(accessToken: widget.accessToken),
            ],
          ),
        ),
      ),
    );
  }

  /* ---------------- SIDEBAR ---------------- */
  Widget _buildSideMenu() {
    TextStyle itemStyle(bool active) => TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: active ? Colors.black : Colors.grey.shade700,
        );

    Widget tile(String label, IconData icon, _SideItem item) {
      final active = _selectedSide == item;
      return InkWell(
        splashFactory: NoSplash.splashFactory,
        onTap: () => setState(() => _selectedSide = item),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: active ? Colors.grey.shade200 : Colors.transparent,
          child: Row(
            children: [
              Icon(icon,
                  color: active ? Colors.blue : Colors.grey.shade600, size: 22),
              const SizedBox(width: 12),
              Text(label, style: itemStyle(active)),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 300,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          tile('Home', Icons.grid_view, _SideItem.home),
          tile('I miei documenti', Icons.insert_drive_file, _SideItem.myDocs),
          tile('La mia cassaforte', Icons.lock, _SideItem.safebox),
          tile('Condivisi con me', Icons.people, _SideItem.shared),
          tile('Recenti', Icons.access_time, _SideItem.recent),
          tile('Importanti', Icons.star_border, _SideItem.important),
          tile('Cestino', Icons.delete_outline, _SideItem.trash),

      const Spacer(),                       // 🔹 spinge in basso il box

      const Divider(height: 1),            // 🔹 linea di separazione

      _buildStorageInfo(),                 // 🔹 nuovo blocco],
      ]),
    );
  }

  /* ---------------- CONTENUTO ---------------- */
  Widget _buildContent() {
    switch (_selectedSide) {
      case _SideItem.home:
  return const UseCasesPage();
      case _SideItem.myDocs:
        return MyDocumentsPage(); // widget reale
      default:
        return const Center(child: Text('Sezione in costruzione'));
    }
  }

// ➊  INFO SPAZIO IN FONDO ALLA SIDEBAR
Widget _buildStorageInfo() {
  // --- valori DEMO: sostituiscili con quelli reali -----------------
  const double usedKB   = 8.4;
  const double quotaMB  = 48.83;
  const int     filesUp = 1;
  const int     filesOK = 2;
  const double co2g     = 0;
  final double usedFrac = (usedKB / 1024) / quotaMB;             // 0-1
  // -----------------------------------------------------------------

  TextStyle smallGrey = TextStyle(color: Colors.grey.shade600, fontSize: 13);

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Spazio di archiviazione',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 4),

        // barra progresso sottile
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: usedFrac.clamp(0, 1),
            minHeight: 4,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                AlwaysStoppedAnimation<Color>(const Color(0xFF4CAF50)),
          ),
        ),
        const SizedBox(height: 8),

        Text('Utilizzati ${usedKB.toStringAsFixed(1)} KB di '
             '${quotaMB.toStringAsFixed(2)} MB', style: smallGrey),
        Text('Caricati $filesUp file di $filesOK', style: smallGrey),
        Text('${co2g.toStringAsFixed(0)} g di CO₂ risparmiati',
            style: smallGrey),

        const SizedBox(height: 12),

        // link azioni
        Row(
          children: [
            InkWell(
              onTap: () => debugPrint('upgrade'),
              child: const Text('Upgrade',
                  style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 24),
            InkWell(
              onTap: () => debugPrint('invite friend'),
              child: const Text('Invita un amico',
                  style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(),                          // barra superiore
          Expanded(
            child: Row(
              children: [
                _buildSideMenu(),                  // colonna sinistra
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(child: _buildContent()),  // contenuto
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- Avatar + Menu popup ---------- */ 
class _UserMenu extends StatelessWidget {
   final String accessToken;

   const _UserMenu({
     Key? key,
     required this.accessToken,
   }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      color: Colors.white,
      tooltip: 'Account',
      offset: const Offset(0, 50),
onSelected: (v) {
  switch (v) {
    case 0: // “Il mio profilo”
 showDialog(
   context: context,
   builder: (_) => SettingsDialog(
     accessToken: accessToken,
     onArchiveAll: () async { /* TODO */ },
     onDeleteAll: () async { /* TODO */ },
   ),
 );
      break;
  case 4: // “Esci”
      {
        // 1) rimuovi tutti i token dall’localStorage
        html.window.localStorage.remove('token');
        html.window.localStorage.remove('refreshToken');
        html.window.localStorage.remove('user');
        // 2) naviga alla LoginPage, resettando lo stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
      break;
    default:
      debugPrint('selezione menu: $v');
  }
},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      itemBuilder: (_) => [
        _item(0, 'Il mio profilo', Icons.person_outline),
        _item(1, 'Abbonamento', Icons.description_outlined),
        _item(2, 'Le mie identità', Icons.face_retouching_natural_outlined),
        _item(3, 'Invita un amico', Icons.person_add_alt_outlined),
        const PopupMenuDivider(),
        _item(4, 'Esci', Icons.logout_outlined),
      ],
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade400,
            child: const Text('S',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const Text('Simone Sansalone',
              style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  PopupMenuItem<int> _item(int v, String label, IconData icon) =>
      PopupMenuItem<int>(
        value: v,
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      );
}

/* ---------- Lingua + Menu popup ---------- */
class _LanguageMenu extends StatelessWidget {
  final String current;                 // es.: 'it'  o  'en'
  final ValueChanged<String> onChange;  // callback al parent

  const _LanguageMenu({
    super.key,
    required this.current,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    /// mapping lingua → etichetta
    const Map<String, String> label = {'it': 'Italiano', 'en': 'English'};

    return PopupMenuButton<String>(
      tooltip: 'Lingua',
      color: Colors.white,
      offset: const Offset(0, 46),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      onSelected: onChange,
      itemBuilder: (_) => [
        for (final code in label.keys)
          PopupMenuItem<String>(
            value: code,
            child: Row(
              children: [
                Icon(Icons.flag_outlined,
                    size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                Text(label[code]!),
                if (code == current) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18, color: Colors.blue)
                ],
              ],
            ),
          ),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Lingua',
              style: TextStyle(color: Colors.white, fontSize: 11)),
          Row(
            children: [
              Text(label[current]!,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              const Icon(Icons.arrow_drop_down,
                  color: Colors.white, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:word_search_app/features/word_search/domain/puzzle_theme.dart';

/// Italian word pools, one list per [PuzzleTheme]. All uppercase and
/// without accents (CAFE not CAFFÈ-style final-vowel marks) — see the
/// note in fr_words.dart; a grid cell shows one glyph.
final wordsByThemeIt = <PuzzleTheme, List<String>>{
  PuzzleTheme.animals: [
    'GATTO', 'CANE', 'VOLPE', 'TOPO', 'CAVALLO', 'PECORA', 'CAPRA',
    'CONIGLIO', 'AQUILA', 'APE', 'LUPO', 'ORSO', 'LEONE', 'TIGRE', 'ZEBRA',
    'CAMMELLO', 'DELFINO', 'PANTERA', 'GIRAFFA', 'PINGUINO', 'SCOIATTOLO',
    'ELEFANTE', 'COCCODRILLO',
  ],
  PuzzleTheme.food: [
    'PANE', 'FORMAGGIO', 'LATTE', 'MIELE', 'MINESTRA', 'TORTA', 'BURRO',
    'MELA', 'PERA', 'LIMONE', 'BANANA', 'PATATA', 'POMODORO', 'CAFFE',
    'BISCOTTO', 'CIOCCOLATO', 'FRAGOLA', 'ANGURIA', 'FRITTELLA',
  ],
  PuzzleTheme.nature: [
    'SOLE', 'CIELO', 'MARE', 'GHIACCIO', 'NEBBIA', 'PIOGGIA', 'VENTO',
    'FOGLIA', 'ALBERO', 'NUVOLA', 'FIUME', 'PIETRA', 'SPIAGGIA', 'BOSCO',
    'DESERTO', 'ISOLA', 'GHIACCIAIO', 'VULCANO', 'PRATO', 'ARCOBALENO',
    'MONTAGNA', 'CASCATA',
  ],
  PuzzleTheme.home: [
    'LETTO', 'TAPPETO', 'TAZZA', 'PORTA', 'LAMPADA', 'DIVANO', 'SEDIA',
    'TAVOLO', 'SCAFFALE', 'SPECCHIO', 'CUSCINO', 'FINESTRA', 'CUCINA',
    'COPERTA', 'GIARDINO', 'CAMERA', 'BAGNO', 'CAMINETTO',
  ],
  PuzzleTheme.body: [
    'BRACCIO', 'GAMBA', 'ORECCHIO', 'OCCHIO', 'MANO', 'PIEDE', 'TESTA',
    'COLLO', 'MENTO', 'GINOCCHIO', 'DITO', 'SPALLA', 'GOMITO', 'CAVIGLIA',
    'STOMACO', 'SOPRACCIGLIO', 'FRONTE',
  ],
  PuzzleTheme.clothes: [
    'CAPPELLO', 'CRAVATTA', 'CALZINO', 'CINTURA', 'CAPPOTTO', 'GUANTO',
    'SCIARPA', 'VESTITO', 'GIACCA', 'MAGLIONE', 'PANTALONE', 'SANDALI',
    'SCARPETTE', 'PANTOFOLE', 'IMPERMEABILE', 'COLLANA', 'BRACCIALETTO',
  ],
  PuzzleTheme.travel: [
    'MAPPA', 'BUS', 'AUTO', 'NAVE', 'TAXI', 'TRENO', 'AEREO', 'BIGLIETTO',
    'AEROPORTO', 'STAZIONE', 'PASSAPORTO', 'VALIGIA', 'ZAINO',
    'AUTOSTRADA', 'VIAGGIO', 'PORTO', 'BICICLETTA', 'VACANZA',
  ],
  PuzzleTheme.sports: [
    'CORSA', 'GOL', 'SQUADRA', 'NUOTO', 'SCACCHI', 'CALCIO', 'TENNIS',
    'HOCKEY', 'BOXE', 'CICLISMO', 'ATLETA', 'STADIO', 'ARBITRO',
    'MARATONA', 'PALLACANESTRO', 'PALLAVOLO',
  ],
};

import 'package:crossword_app/features/crossword/domain/clue_category.dart';

// Maps easy-tier answers onto broad, language-independent categories.
//
// Only the EASY tier is categorized: picture clues are an aid for the
// gentlest puzzles, and the harder tiers are mostly abstract vocabulary
// that no icon could honestly represent.
//
// Listed as answer sets per category rather than annotated onto every
// WordClue, so adding a language means adding one block here instead of
// touching every line of a word bank. Anything not listed simply gets no
// icon, which is the right outcome for abstract words.

/// Inverts the authored `category -> answers` shape into the
/// `answer -> category` lookup the generator needs.
Map<String, ClueCategory> _invert(Map<ClueCategory, Set<String>> byCategory) {
  return {
    for (final entry in byCategory.entries)
      for (final answer in entry.value) answer: entry.key,
  };
}

final categoriesEn = _invert({
  ClueCategory.animal: {
    'CAT', 'DOG', 'FISH', 'BIRD', 'HORSE', 'SHEEP', 'GOAT', 'DUCK', 'FROG',
    'BEAR', 'LION', 'TIGER', 'WOLF', 'DEER', 'MOUSE', 'SNAKE', 'WHALE',
    'SHARK', 'CRAB', 'BEE', 'ANT',
  },
  ClueCategory.nature: {
    'SUN', 'MOON', 'STAR', 'TREE', 'LEAF', 'SEED', 'FIRE', 'EARTH', 'WIND',
    'RAIN', 'SNOW', 'CLOUD', 'WATER', 'SAND', 'ROCK', 'STONE', 'GOLD',
    'SILVER', 'IRON', 'WOOD',
  },
  ClueCategory.food: {
    'BREAD', 'MILK', 'MEAT', 'RICE', 'SALT', 'SUGAR', 'HONEY', 'CAKE',
    'SOUP', 'FRUIT', 'APPLE', 'GRAPE', 'LEMON',
  },
  ClueCategory.home: {
    'CHAIR', 'TABLE', 'DOOR', 'WALL', 'ROOF', 'LAMP', 'DESK', 'GLASS',
  },
  ClueCategory.people: {
    'FRIEND', 'FAMILY', 'MOTHER', 'FATHER', 'SISTER', 'BABY', 'CHILD',
    'WOMAN', 'KING', 'QUEEN', 'CLASS',
  },
  ClueCategory.body: {
    'HAND', 'FOOT', 'HEAD', 'EAR', 'NOSE', 'MOUTH', 'HAIR', 'ARM', 'LEG',
    'HEART', 'BONE', 'SKIN', 'SMILE',
  },
  ClueCategory.time: {'TIME', 'DAY', 'NIGHT', 'WEEK', 'MONTH', 'YEAR', 'HOUR', 'CLOCK'},
  ClueCategory.place: {
    'ROAD', 'PATH', 'BRIDGE', 'RIVER', 'LAKE', 'SEA', 'OCEAN', 'HILL',
    'VALLEY', 'FIELD', 'FOREST', 'DESERT', 'ISLAND', 'BEACH', 'MAP',
  },
  ClueCategory.object: {'BOOK', 'PAGE', 'WORD', 'PEN', 'PAPER', 'CROWN'},
  ClueCategory.color: {'COLOR', 'RED', 'BLUE', 'GREEN'},
  ClueCategory.action: {
    'WALK', 'RUN', 'JUMP', 'SWIM', 'DANCE', 'SING', 'PLAY', 'WORK', 'SLEEP',
    'DREAM',
  },
});

final categoriesDe = _invert({
  ClueCategory.animal: {
    'HUND', 'KATZE', 'ONKEL', 'PFERD', 'SCHAF', 'ENTE', 'FROSCH', 'ELCH',
    'TIGER', 'WOLF', 'MAUS', 'SCHLANGE', 'WAL', 'HAI', 'BIENE',
  },
  ClueCategory.nature: {
    'BAUM', 'SONNE', 'MOND', 'STERN', 'WASSER', 'FEUER', 'WIND', 'REGEN',
    'SCHNEE', 'WOLKE', 'BLATT', 'SAND', 'STEIN', 'GOLD', 'SILBER', 'EISEN',
    'HOLZ',
  },
  ClueCategory.food: {'BROT', 'MILCH', 'SALZ', 'ZUCKER', 'KUCHEN'},
  ClueCategory.home: {'HAUS', 'GLAS'},
  ClueCategory.people: {
    'FREUND', 'FAMILIE', 'MUTTER', 'VATER', 'SCHWESTER', 'BABY', 'KIND',
    'FRAU', 'SCHULE',
  },
  ClueCategory.body: {
    'HAND', 'FUSS', 'KOPF', 'OHR', 'NASE', 'MUND', 'HAAR', 'ARM', 'BEIN',
    'HERZ', 'HAUT',
  },
  ClueCategory.time: {'ZEIT', 'TAG', 'NACHT', 'WOCHE', 'MONAT', 'JAHR', 'STUNDE', 'UHR'},
  ClueCategory.place: {
    'STRASSE', 'FLUSS', 'SEE', 'MEER', 'BERG', 'TAL', 'FELD', 'WALD',
    'EBENE', 'INSEL', 'STRAND',
  },
  ClueCategory.object: {'BUCH', 'SEITE', 'WORT', 'STIFT', 'PAPIER'},
  ClueCategory.color: {'FARBE', 'ROT', 'BLAU', 'BRAUN'},
  ClueCategory.action: {'SCHLAF', 'TRAUM'},
});

final categoriesFr = _invert({
  ClueCategory.animal: {
    'CHAT', 'CHIEN', 'POISSON', 'OISEAU', 'CHEVAL', 'MOUTON', 'CANARD',
    'GRENOUILLE', 'OURS', 'LION', 'LOUP', 'SOURIS', 'SERPENT', 'BALEINE',
    'REQUIN', 'ABEILLE',
  },
  ClueCategory.nature: {
    'SOLEIL', 'LUNE', 'ETOILE', 'ARBRE', 'EAU', 'FEU', 'TERRE', 'VENT',
    'PLUIE', 'NEIGE', 'NUAGE', 'FEUILLE', 'SABLE', 'PIERRE', 'OR', 'ARGENT',
    'FER', 'BOIS',
  },
  ClueCategory.food: {'PAIN', 'LAIT', 'SEL', 'SUCRE', 'GATEAU', 'SOUPE'},
  ClueCategory.home: {'CHAISE', 'TABLE', 'PORTE', 'MUR', 'TOIT', 'LAMPE', 'VERRE'},
  ClueCategory.people: {
    'AMI', 'FAMILLE', 'MERE', 'PERE', 'SOEUR', 'BEBE', 'ENFANT', 'FEMME',
    'ROI', 'REINE', 'ECOLE',
  },
  ClueCategory.body: {
    'MAIN', 'PIED', 'TETE', 'OEIL', 'NEZ', 'BOUCHE', 'CHEVEUX', 'BRAS',
    'JAMBE', 'COEUR', 'PEAU', 'SOURIRE',
  },
  ClueCategory.time: {'TEMPS', 'JOUR', 'NUIT', 'SEMAINE', 'MOIS', 'ANNEE', 'HEURE', 'HORLOGE'},
  ClueCategory.place: {
    'ROUTE', 'RIVIERE', 'LAC', 'MER', 'MONTAGNE', 'VALLEE', 'CHAMP',
    'FORET', 'DESERT', 'ILE', 'PLAGE',
  },
  ClueCategory.object: {'LIVRE', 'PAGE', 'MOT', 'STYLO', 'PAPIER'},
  ClueCategory.color: {'COULEUR', 'ROUGE', 'BLEU', 'VERT'},
  ClueCategory.action: {'SOMMEIL', 'REVE'},
});

final categoriesEs = _invert({
  ClueCategory.animal: {
    'GATO', 'PERRO', 'PEZ', 'PAJARO', 'CABALLO', 'OVEJA', 'PATO', 'RANA',
    'OSO', 'LEON', 'LOBO', 'RATON', 'SERPIENTE', 'BALLENA', 'TIBURON',
    'ABEJA', 'HORMIGA',
  },
  ClueCategory.nature: {
    'SOL', 'LUNA', 'ESTRELLA', 'ARBOL', 'AGUA', 'FUEGO', 'TIERRA', 'VIENTO',
    'LLUVIA', 'NIEVE', 'NUBE', 'HOJA', 'ARENA', 'PIEDRA', 'ORO', 'PLATA',
    'HIERRO', 'MADERA',
  },
  ClueCategory.food: {'PAN', 'LECHE', 'SAL', 'AZUCAR', 'PASTEL', 'SOPA'},
  ClueCategory.home: {'SILLA', 'MESA', 'PUERTA', 'PARED', 'TECHO', 'LAMPARA', 'VIDRIO'},
  ClueCategory.people: {
    'AMIGO', 'FAMILIA', 'MADRE', 'PADRE', 'HERMANA', 'BEBE', 'NIÑO',
    'MUJER', 'REY', 'REINA', 'ESCUELA',
  },
  ClueCategory.body: {
    'MANO', 'PIE', 'CABEZA', 'OJO', 'NARIZ', 'BOCA', 'PELO', 'BRAZO',
    'PIERNA', 'CORAZON', 'PIEL', 'SONRISA',
  },
  ClueCategory.time: {'TIEMPO', 'DIA', 'NOCHE', 'SEMANA', 'MES', 'AÑO', 'HORA', 'RELOJ'},
  ClueCategory.place: {
    'CAMINO', 'RIO', 'MAR', 'MONTAÑA', 'VALLE', 'CAMPO', 'BOSQUE',
    'DESIERTO', 'ISLA', 'PLAYA',
  },
  ClueCategory.object: {'LIBRO', 'PAGINA', 'PALABRA', 'LAPIZ', 'PAPEL'},
  ClueCategory.color: {'COLOR', 'ROJO', 'AZUL', 'VERDE'},
  ClueCategory.action: {'SUEÑO'},
});

final categoriesIt = _invert({
  ClueCategory.animal: {
    'GATTO', 'CANE', 'PESCE', 'UCCELLO', 'CAVALLO', 'PECORA', 'ANATRA',
    'RANA', 'ORSO', 'LEONE', 'LUPO', 'TOPO', 'SERPENTE', 'BALENA',
    'SQUALO', 'APE', 'FORMICA',
  },
  ClueCategory.nature: {
    'SOLE', 'LUNA', 'STELLA', 'ALBERO', 'ACQUA', 'FUOCO', 'TERRA', 'VENTO',
    'PIOGGIA', 'NEVE', 'NUVOLA', 'FOGLIA', 'SABBIA', 'PIETRA', 'ORO',
    'ARGENTO', 'FERRO', 'LEGNO',
  },
  ClueCategory.food: {'PANE', 'LATTE', 'SALE', 'ZUCCHERO', 'TORTA', 'MINESTRA'},
  ClueCategory.home: {'SEDIA', 'TAVOLO', 'PORTA', 'MURO', 'TETTO', 'LAMPADA', 'VETRO'},
  ClueCategory.people: {
    'AMICO', 'FAMIGLIA', 'MADRE', 'PADRE', 'SORELLA', 'BAMBINO', 'DONNA',
    'RE', 'REGINA', 'SCUOLA',
  },
  ClueCategory.body: {
    'MANO', 'PIEDE', 'TESTA', 'OCCHIO', 'NASO', 'BOCCA', 'CAPELLI',
    'BRACCIO', 'GAMBA', 'CUORE', 'PELLE', 'SORRISO',
  },
  ClueCategory.time: {'TEMPO', 'GIORNO', 'NOTTE', 'SETTIMANA', 'MESE', 'ANNO', 'ORA', 'OROLOGIO'},
  ClueCategory.place: {
    'STRADA', 'FIUME', 'LAGO', 'MARE', 'MONTAGNA', 'VALLE', 'CAMPO',
    'BOSCO', 'DESERTO', 'ISOLA', 'SPIAGGIA',
  },
  ClueCategory.object: {'LIBRO', 'PAGINA', 'PAROLA', 'PENNA', 'CARTA'},
  ClueCategory.color: {'COLORE', 'ROSSO', 'BLU', 'VERDE'},
  ClueCategory.action: {'SONNO'},
});

final categoriesAr = _invert({
  ClueCategory.animal: {
    'قطة', 'كلب', 'طير', 'سمك', 'أرنب', 'حصان', 'أسد', 'ذئب', 'فأر', 'نمر',
    'فيل', 'دجاجة', 'بقرة', 'خروف',
  },
  ClueCategory.nature: {
    'شمس', 'قمر', 'نجم', 'سماء', 'أرض', 'ماء', 'نار', 'مطر', 'ثلج', 'ريح',
    'شجرة', 'زهرة', 'نور',
  },
  ClueCategory.food: {'خبز', 'لبن', 'عسل', 'ملح', 'تفاح', 'موز', 'شاي', 'قهوة'},
  ClueCategory.home: {'بيت', 'باب', 'غرفة', 'نافذة', 'سرير', 'كرسي', 'طاولة', 'كوب'},
  ClueCategory.people: {'ولد', 'رجل', 'طفل', 'ملك', 'وزير', 'طالب', 'مدرسة', 'جيش'},
  ClueCategory.body: {'عين', 'يد', 'فم'},
  ClueCategory.time: {
    'سنة', 'يوم', 'ليل', 'شهر', 'أسبوع', 'ساعة', 'صباح', 'مساء', 'ظهر',
    'أمس', 'غد', 'عمر',
  },
  ClueCategory.place: {'بحر', 'نهر', 'جبل', 'شرق', 'غرب', 'جنوب', 'شمال', 'بلد', 'مكتب'},
  ClueCategory.object: {'قلم', 'كتاب', 'دفتر', 'ثوب', 'حذاء', 'قبعة'},
  ClueCategory.color: {'لون'},
  ClueCategory.action: {},
});

/// Per-language lookup used by the generator.
final categoriesByLanguage = <String, Map<String, ClueCategory>>{
  'en': categoriesEn,
  'ar': categoriesAr,
  'de': categoriesDe,
  'fr': categoriesFr,
  'es': categoriesEs,
  'it': categoriesIt,
};

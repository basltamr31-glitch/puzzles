import 'package:word_search_app/features/word_search/domain/puzzle_theme.dart';

/// German word pools, one list per [PuzzleTheme]. All uppercase.
final wordsByThemeDe = <PuzzleTheme, List<String>>{
  PuzzleTheme.animals: [
    'FUCHS', 'HUND', 'KATZE', 'MAUS', 'PFERD', 'SCHAF', 'ZIEGE', 'HASE',
    'ADLER', 'BIENE', 'WOLF', 'BAER', 'LOEWE', 'TIGER', 'ZEBRA', 'KAMEL',
    'DELFIN', 'PANTHER', 'GIRAFFE', 'PINGUIN', 'EICHHOERNCHEN', 'ELEFANT',
    'KROKODIL',
  ],
  PuzzleTheme.food: [
    'BROT', 'KAESE', 'MILCH', 'HONIG', 'SUPPE', 'KUCHEN', 'BUTTER', 'APFEL',
    'BIRNE', 'ZITRONE', 'BANANE', 'KARTOFFEL', 'TOMATE', 'KAFFEE', 'KEKSE',
    'SCHOKOLADE', 'ERDBEERE', 'WASSERMELONE', 'PFANNKUCHEN',
  ],
  PuzzleTheme.nature: [
    'SONNE', 'HIMMEL', 'MEER', 'EIS', 'NEBEL', 'REGEN', 'WIND', 'BLATT',
    'BAUM', 'WOLKE', 'FLUSS', 'STEIN', 'STRAND', 'WALD', 'WUESTE', 'INSEL',
    'GLETSCHER', 'VULKAN', 'WIESE', 'REGENBOGEN', 'BERG', 'WASSERFALL',
  ],
  PuzzleTheme.home: [
    'BETT', 'TEPPICH', 'TASSE', 'TUER', 'LAMPE', 'SOFA', 'STUHL', 'TISCH',
    'REGAL', 'SPIEGEL', 'KISSEN', 'FENSTER', 'KUECHE', 'DECKE', 'GARTEN',
    'SCHLAFZIMMER', 'BADEZIMMER', 'KAMIN',
  ],
  PuzzleTheme.body: [
    'ARM', 'BEIN', 'OHR', 'AUGE', 'HAND', 'FUSS', 'KOPF', 'HALS', 'KINN',
    'KNIE', 'FINGER', 'SCHULTER', 'ELLBOGEN', 'KNOECHEL', 'BAUCH',
    'AUGENBRAUE', 'STIRN',
  ],
  PuzzleTheme.clothes: [
    'HUT', 'SOCKE', 'GUERTEL', 'MANTEL', 'HANDSCHUH', 'SCHAL', 'KLEID',
    'JACKE', 'PULLOVER', 'HOSE', 'SANDALEN', 'TURNSCHUHE', 'PANTOFFELN',
    'REGENMANTEL', 'HALSKETTE', 'ARMBAND',
  ],
  PuzzleTheme.travel: [
    'KARTE', 'BUS', 'AUTO', 'SCHIFF', 'TAXI', 'ZUG', 'FLUGZEUG', 'TICKET',
    'FLUGHAFEN', 'BAHNHOF', 'REISEPASS', 'KOFFER', 'RUCKSACK', 'AUTOBAHN',
    'REISE', 'HAFEN', 'FAHRRAD', 'URLAUB',
  ],
  PuzzleTheme.sports: [
    'LAUF', 'TOR', 'TEAM', 'RENNEN', 'SCHWIMMEN', 'SCHACH', 'FUSSBALL',
    'TENNIS', 'HOCKEY', 'BOXEN', 'RADFAHREN', 'SPORTLER', 'STADION',
    'SCHIEDSRICHTER', 'MARATHON', 'BASKETBALL', 'VOLLEYBALL',
  ],
};

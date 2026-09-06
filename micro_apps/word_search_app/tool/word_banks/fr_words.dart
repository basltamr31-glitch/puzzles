import 'package:word_search_app/features/word_search/domain/puzzle_theme.dart';

/// French word pools, one list per [PuzzleTheme]. All uppercase, and
/// deliberately without accents (CHAT not CHÂT, ETE not ÉTÉ): a grid cell
/// shows one glyph, and an accented and unaccented letter would otherwise
/// need to compare as different filler letters while reading as "the same
/// letter" to a player — matching French word-search publications, which
/// do the same.
final wordsByThemeFr = <PuzzleTheme, List<String>>{
  PuzzleTheme.animals: [
    'CHAT', 'CHIEN', 'RENARD', 'SOURIS', 'CHEVAL', 'MOUTON', 'CHEVRE',
    'LAPIN', 'AIGLE', 'ABEILLE', 'LOUP', 'OURS', 'LION', 'TIGRE', 'ZEBRE',
    'CHAMEAU', 'DAUPHIN', 'PANTHERE', 'GIRAFE', 'PINGOUIN', 'ECUREUIL',
    'ELEPHANT', 'CROCODILE',
  ],
  PuzzleTheme.food: [
    'PAIN', 'FROMAGE', 'LAIT', 'MIEL', 'SOUPE', 'GATEAU', 'BEURRE',
    'POMME', 'POIRE', 'CITRON', 'BANANE', 'POMMEDETERRE', 'TOMATE', 'CAFE',
    'BISCUIT', 'CHOCOLAT', 'FRAISE', 'PASTEQUE', 'CREPE',
  ],
  PuzzleTheme.nature: [
    'SOLEIL', 'CIEL', 'MER', 'GLACE', 'BROUILLARD', 'PLUIE', 'VENT',
    'FEUILLE', 'ARBRE', 'NUAGE', 'RIVIERE', 'PIERRE', 'PLAGE', 'FORET',
    'DESERT', 'ILE', 'GLACIER', 'VOLCAN', 'PRAIRIE', 'ARCENCIEL',
    'MONTAGNE', 'CASCADE',
  ],
  PuzzleTheme.home: [
    'LIT', 'TAPIS', 'TASSE', 'PORTE', 'LAMPE', 'CANAPE', 'CHAISE', 'TABLE',
    'ETAGERE', 'MIROIR', 'COUSSIN', 'FENETRE', 'CUISINE', 'COUVERTURE',
    'JARDIN', 'CHAMBRE', 'SALLEDEBAIN', 'CHEMINEE',
  ],
  PuzzleTheme.body: [
    'BRAS', 'JAMBE', 'OREILLE', 'OEIL', 'MAIN', 'PIED', 'TETE', 'COU',
    'MENTON', 'GENOU', 'DOIGT', 'EPAULE', 'COUDE', 'CHEVILLE', 'VENTRE',
    'SOURCIL', 'FRONT',
  ],
  PuzzleTheme.clothes: [
    'CHAPEAU', 'CRAVATE', 'CHAUSSETTE', 'CEINTURE', 'MANTEAU', 'GANT',
    'ECHARPE', 'ROBE', 'VESTE', 'PULL', 'PANTALON', 'SANDALES', 'BASKETS',
    'PANTOUFLES', 'IMPERMEABLE', 'COLLIER', 'BRACELET',
  ],
  PuzzleTheme.travel: [
    'CARTE', 'BUS', 'VOITURE', 'BATEAU', 'TAXI', 'TRAIN', 'AVION',
    'BILLET', 'AEROPORT', 'GARE', 'PASSEPORT', 'VALISE', 'SACADOS',
    'AUTOROUTE', 'VOYAGE', 'PORT', 'VELO', 'VACANCES',
  ],
  PuzzleTheme.sports: [
    'COURSE', 'BUT', 'EQUIPE', 'NATATION', 'ECHECS', 'FOOTBALL', 'TENNIS',
    'HOCKEY', 'BOXE', 'CYCLISME', 'ATHLETE', 'STADE', 'ARBITRE',
    'MARATHON', 'BASKETBALL', 'VOLLEYBALL',
  ],
};

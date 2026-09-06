import 'package:word_search_app/features/word_search/domain/puzzle_theme.dart';

/// Spanish word pools, one list per [PuzzleTheme]. All uppercase and
/// without accents (RIO not RÍO) — see the note in fr_words.dart; a grid
/// cell shows one glyph, and Spanish word-search books do the same.
final wordsByThemeEs = <PuzzleTheme, List<String>>{
  PuzzleTheme.animals: [
    'GATO', 'PERRO', 'ZORRO', 'RATON', 'CABALLO', 'OVEJA', 'CABRA',
    'CONEJO', 'AGUILA', 'ABEJA', 'LOBO', 'OSO', 'LEON', 'TIGRE', 'CEBRA',
    'CAMELLO', 'DELFIN', 'PANTERA', 'JIRAFA', 'PINGUINO', 'ARDILLA',
    'ELEFANTE', 'COCODRILO',
  ],
  PuzzleTheme.food: [
    'PAN', 'QUESO', 'LECHE', 'MIEL', 'SOPA', 'PASTEL', 'MANTEQUILLA',
    'MANZANA', 'PERA', 'LIMON', 'PLATANO', 'PATATA', 'TOMATE', 'CAFE',
    'GALLETA', 'CHOCOLATE', 'FRESA', 'SANDIA', 'TORTILLA',
  ],
  PuzzleTheme.nature: [
    'SOL', 'CIELO', 'MAR', 'HIELO', 'NIEBLA', 'LLUVIA', 'VIENTO', 'HOJA',
    'ARBOL', 'NUBE', 'RIO', 'PIEDRA', 'PLAYA', 'BOSQUE', 'DESIERTO',
    'ISLA', 'GLACIAR', 'VOLCAN', 'PRADERA', 'ARCOIRIS', 'MONTANA',
    'CASCADA',
  ],
  PuzzleTheme.home: [
    'CAMA', 'ALFOMBRA', 'TAZA', 'PUERTA', 'LAMPARA', 'SOFA', 'SILLA',
    'MESA', 'ESTANTE', 'ESPEJO', 'ALMOHADA', 'VENTANA', 'COCINA',
    'MANTA', 'JARDIN', 'DORMITORIO', 'BANO', 'CHIMENEA',
  ],
  PuzzleTheme.body: [
    'BRAZO', 'PIERNA', 'OREJA', 'OJO', 'MANO', 'PIE', 'CABEZA', 'CUELLO',
    'MENTON', 'RODILLA', 'DEDO', 'HOMBRO', 'CODO', 'TOBILLO', 'ESTOMAGO',
    'CEJA', 'FRENTE',
  ],
  PuzzleTheme.clothes: [
    'SOMBRERO', 'CORBATA', 'CALCETIN', 'CINTURON', 'ABRIGO', 'GUANTE',
    'BUFANDA', 'VESTIDO', 'CHAQUETA', 'SUETER', 'PANTALON', 'SANDALIAS',
    'ZAPATILLAS', 'PANTUFLAS', 'IMPERMEABLE', 'COLLAR', 'PULSERA',
  ],
  PuzzleTheme.travel: [
    'MAPA', 'BUS', 'COCHE', 'BARCO', 'TAXI', 'TREN', 'AVION', 'BOLETO',
    'AEROPUERTO', 'ESTACION', 'PASAPORTE', 'MALETA', 'MOCHILA',
    'AUTOPISTA', 'VIAJE', 'PUERTO', 'BICICLETA', 'VACACIONES',
  ],
  PuzzleTheme.sports: [
    'CARRERA', 'GOL', 'EQUIPO', 'NATACION', 'AJEDREZ', 'FUTBOL', 'TENIS',
    'HOCKEY', 'BOXEO', 'CICLISMO', 'ATLETA', 'ESTADIO', 'ARBITRO',
    'MARATON', 'BALONCESTO', 'VOLEIBOL',
  ],
};

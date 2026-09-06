import 'package:word_search_app/features/word_search/domain/puzzle_theme.dart';

/// English word pools, one list per [PuzzleTheme]. All uppercase, since
/// that's the case the generator and the grid render in.
///
/// Sized generously across lengths 3-13 so every difficulty tier (which
/// filters by word length) has enough eligible words per theme without
/// falling back to another theme's pool.
final wordsByThemeEn = <PuzzleTheme, List<String>>{
  PuzzleTheme.animals: [
    'CAT', 'DOG', 'FOX', 'OWL', 'BEE', 'ANT', 'COW', 'PIG',
    'BIRD', 'FISH', 'DEER', 'WOLF', 'BEAR', 'LION', 'HARE', 'GOAT',
    'TIGER', 'HORSE', 'SHEEP', 'MOUSE', 'ZEBRA', 'EAGLE', 'CAMEL', 'RABBIT',
    'DOLPHIN', 'PANTHER', 'GIRAFFE', 'PENGUIN', 'SQUIRREL', 'ELEPHANT',
    'CROCODILE', 'HIPPOPOTAMUS',
  ],
  PuzzleTheme.food: [
    'TEA', 'PIE', 'JAM', 'EGG', 'RICE', 'CAKE', 'SOUP', 'MILK',
    'BREAD', 'HONEY', 'APPLE', 'GRAPE', 'LEMON', 'PASTA', 'PIZZA',
    'CHEESE', 'BUTTER', 'COFFEE', 'COOKIE', 'CARROT', 'BANANA', 'ORANGE',
    'POTATO', 'TOMATO', 'PANCAKE', 'SANDWICH', 'AVOCADO', 'CHOCOLATE',
    'STRAWBERRY', 'WATERMELON',
  ],
  PuzzleTheme.nature: [
    'SUN', 'SKY', 'SEA', 'ICE', 'FOG', 'RAIN', 'WIND', 'LEAF',
    'TREE', 'CLOUD', 'RIVER', 'STONE', 'BEACH', 'OCEAN', 'FOREST',
    'DESERT', 'ISLAND', 'GLACIER', 'VOLCANO', 'MEADOW', 'SUNSET', 'RAINBOW',
    'MOUNTAIN', 'WATERFALL', 'THUNDERSTORM',
  ],
  PuzzleTheme.home: [
    'BED', 'RUG', 'CUP', 'DOOR', 'LAMP', 'SOFA', 'DESK', 'CHAIR',
    'TABLE', 'SHELF', 'MIRROR', 'PILLOW', 'WINDOW', 'KITCHEN', 'BLANKET',
    'CARPET', 'CEILING', 'GARDEN', 'HALLWAY', 'STAIRCASE', 'BATHROOM',
    'BEDROOM', 'CUPBOARD', 'FIREPLACE',
  ],
  PuzzleTheme.body: [
    'ARM', 'LEG', 'EAR', 'EYE', 'LIP', 'HAND', 'FOOT', 'HEAD',
    'NECK', 'CHIN', 'KNEE', 'FINGER', 'SHOULDER', 'ELBOW', 'ANKLE',
    'STOMACH', 'EYEBROW', 'FOREHEAD', 'FINGERNAIL',
  ],
  PuzzleTheme.clothes: [
    'HAT', 'TIE', 'SOCK', 'BELT', 'COAT', 'GLOVE', 'SCARF', 'DRESS',
    'JACKET', 'SWEATER', 'TROUSERS', 'SANDALS', 'SNEAKERS', 'SLIPPERS',
    'RAINCOAT', 'PAJAMAS', 'NECKLACE', 'BRACELET',
  ],
  PuzzleTheme.travel: [
    'MAP', 'BUS', 'CAR', 'SHIP', 'TAXI', 'TRAIN', 'PLANE', 'TICKET',
    'AIRPORT', 'STATION', 'PASSPORT', 'SUITCASE', 'BACKPACK', 'HIGHWAY',
    'JOURNEY', 'HARBOR', 'BICYCLE', 'VOYAGE', 'VACATION', 'DESTINATION',
  ],
  PuzzleTheme.sports: [
    'RUN', 'GYM', 'GOAL', 'TEAM', 'RACE', 'SWIM', 'CHESS', 'SOCCER',
    'TENNIS', 'HOCKEY', 'BOXING', 'ARCHERY', 'CYCLING', 'ATHLETE',
    'STADIUM', 'REFEREE', 'MARATHON', 'BASKETBALL', 'VOLLEYBALL',
    'CHAMPIONSHIP',
  ],
};

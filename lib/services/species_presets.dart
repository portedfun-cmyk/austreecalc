import '../models/species_preset.dart';

/// Hard-coded species presets for AusTreeCalc.
/// Wood strength values (fb) based on published timber property data.
/// Drag coefficients based on wind tunnel studies (Rudnicki et al., Vollsinger et al.)
class SpeciesPresets {
  // ============ EUCALYPTS - NATIVE AUSTRALIAN ============
  
  static const SpeciesPreset ironbark = SpeciesPreset(
    id: 'ironbark',
    displayName: 'Ironbark (Eucalyptus sideroxylon, E. crebra)',
    fbGreenMPa: 55.0,
    dragCoefficient: 0.22,
    crownShapeFactor: 0.65,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset spottedGum = SpeciesPreset(
    id: 'spotted_gum',
    displayName: 'Spotted Gum (Corymbia maculata)',
    fbGreenMPa: 52.0,
    dragCoefficient: 0.24,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset flooded_gum = SpeciesPreset(
    id: 'flooded_gum',
    displayName: 'Flooded Gum / Rose Gum (E. grandis)',
    fbGreenMPa: 38.0,
    dragCoefficient: 0.25,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset lemonScentedGum = SpeciesPreset(
    id: 'lemon_scented_gum',
    displayName: 'Lemon-Scented Gum (Corymbia citriodora)',
    fbGreenMPa: 48.0,
    dragCoefficient: 0.22,
    crownShapeFactor: 0.6,
    defaultFullness: 0.8,
  );

  static const SpeciesPreset riverRedGum = SpeciesPreset(
    id: 'river_red_gum',
    displayName: 'River Red Gum (E. camaldulensis)',
    fbGreenMPa: 42.0,
    dragCoefficient: 0.26,
    crownShapeFactor: 0.75,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset forestRedGum = SpeciesPreset(
    id: 'forest_red_gum',
    displayName: 'Forest Red Gum (E. tereticornis)',
    fbGreenMPa: 45.0,
    dragCoefficient: 0.25,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset sydneyBlueGum = SpeciesPreset(
    id: 'sydney_blue_gum',
    displayName: 'Sydney Blue Gum (E. saligna)',
    fbGreenMPa: 40.0,
    dragCoefficient: 0.25,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset scribblyGum = SpeciesPreset(
    id: 'scribbly_gum',
    displayName: 'Scribbly Gum (E. haemastoma, E. racemosa)',
    fbGreenMPa: 32.0,
    dragCoefficient: 0.26,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset ghostGum = SpeciesPreset(
    id: 'ghost_gum',
    displayName: 'Ghost Gum (Corymbia aparrerinja)',
    fbGreenMPa: 28.0,
    dragCoefficient: 0.24,
    crownShapeFactor: 0.65,
    defaultFullness: 0.8,
  );

  static const SpeciesPreset snowGum = SpeciesPreset(
    id: 'snow_gum',
    displayName: 'Snow Gum (E. pauciflora)',
    fbGreenMPa: 30.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.75,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset sugargum = SpeciesPreset(
    id: 'sugar_gum',
    displayName: 'Sugar Gum (E. cladocalyx)',
    fbGreenMPa: 45.0,
    dragCoefficient: 0.24,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset yellowBox = SpeciesPreset(
    id: 'yellow_box',
    displayName: 'Yellow Box (E. melliodora)',
    fbGreenMPa: 40.0,
    dragCoefficient: 0.26,
    crownShapeFactor: 0.75,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset greyBox = SpeciesPreset(
    id: 'grey_box',
    displayName: 'Grey Box (E. microcarpa, E. moluccana)',
    fbGreenMPa: 42.0,
    dragCoefficient: 0.25,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset stringybark = SpeciesPreset(
    id: 'stringybark',
    displayName: 'Stringybark (E. obliqua, E. eugenioides)',
    fbGreenMPa: 35.0,
    dragCoefficient: 0.27,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset peppermint = SpeciesPreset(
    id: 'peppermint',
    displayName: 'Peppermint (E. radiata, E. dives)',
    fbGreenMPa: 32.0,
    dragCoefficient: 0.26,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset bloodwood = SpeciesPreset(
    id: 'bloodwood',
    displayName: 'Bloodwood (Corymbia gummifera)',
    fbGreenMPa: 38.0,
    dragCoefficient: 0.26,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset tallowwood = SpeciesPreset(
    id: 'tallowwood',
    displayName: 'Tallowwood (E. microcorys)',
    fbGreenMPa: 48.0,
    dragCoefficient: 0.24,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset blackbutt = SpeciesPreset(
    id: 'blackbutt',
    displayName: 'Blackbutt (E. pilularis)',
    fbGreenMPa: 45.0,
    dragCoefficient: 0.25,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset brushBox = SpeciesPreset(
    id: 'brush_box',
    displayName: 'Brush Box (Lophostemon confertus)',
    fbGreenMPa: 42.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.8,
    defaultFullness: 0.95,
  );

  // ============ OTHER NATIVE AUSTRALIAN ============

  static const SpeciesPreset melaleuca = SpeciesPreset(
    id: 'melaleuca',
    displayName: 'Melaleuca / Paperbark (M. quinquenervia)',
    fbGreenMPa: 28.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset casuarina = SpeciesPreset(
    id: 'casuarina',
    displayName: 'Casuarina / She-Oak (C. cunninghamiana)',
    fbGreenMPa: 32.0,
    dragCoefficient: 0.22,
    crownShapeFactor: 0.6,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset bangalay = SpeciesPreset(
    id: 'bangalay',
    displayName: 'Bangalay (E. botryoides)',
    fbGreenMPa: 38.0,
    dragCoefficient: 0.26,
    crownShapeFactor: 0.75,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset angophora = SpeciesPreset(
    id: 'angophora',
    displayName: 'Angophora / Sydney Red Gum (A. costata)',
    fbGreenMPa: 32.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.8,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset moreton_bay_fig = SpeciesPreset(
    id: 'moreton_bay_fig',
    displayName: 'Moreton Bay Fig (Ficus macrophylla)',
    fbGreenMPa: 22.0,
    dragCoefficient: 0.35,
    crownShapeFactor: 0.85,
    defaultFullness: 1.0,
  );

  static const SpeciesPreset portJacksonFig = SpeciesPreset(
    id: 'port_jackson_fig',
    displayName: 'Port Jackson Fig (Ficus rubiginosa)',
    fbGreenMPa: 20.0,
    dragCoefficient: 0.32,
    crownShapeFactor: 0.8,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset banyaTree = SpeciesPreset(
    id: 'bunya',
    displayName: 'Bunya Pine (Araucaria bidwillii)',
    fbGreenMPa: 26.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.7,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset hoopPine = SpeciesPreset(
    id: 'hoop_pine',
    displayName: 'Hoop Pine (Araucaria cunninghamii)',
    fbGreenMPa: 24.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.65,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset norfolkPine = SpeciesPreset(
    id: 'norfolk_pine',
    displayName: 'Norfolk Island Pine (Araucaria heterophylla)',
    fbGreenMPa: 24.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.7,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset jacaranda = SpeciesPreset(
    id: 'jacaranda',
    displayName: 'Jacaranda (Jacaranda mimosifolia)',
    fbGreenMPa: 22.0,
    dragCoefficient: 0.32,
    crownShapeFactor: 0.8,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset poinciana = SpeciesPreset(
    id: 'poinciana',
    displayName: 'Poinciana / Flame Tree (Delonix regia)',
    fbGreenMPa: 18.0,
    dragCoefficient: 0.35,
    crownShapeFactor: 0.85,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset silkyOak = SpeciesPreset(
    id: 'silky_oak',
    displayName: 'Silky Oak (Grevillea robusta)',
    fbGreenMPa: 28.0,
    dragCoefficient: 0.26,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset tulipwood = SpeciesPreset(
    id: 'tulipwood',
    displayName: 'Tulipwood (Harpullia pendula)',
    fbGreenMPa: 25.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.75,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset leopardTree = SpeciesPreset(
    id: 'leopard_tree',
    displayName: 'Leopard Tree (Caesalpinia ferrea)',
    fbGreenMPa: 35.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.75,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset tuckeroo = SpeciesPreset(
    id: 'tuckeroo',
    displayName: 'Tuckeroo (Cupaniopsis anacardioides)',
    fbGreenMPa: 28.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.8,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset lillypilly = SpeciesPreset(
    id: 'lillypilly',
    displayName: 'Lilly Pilly (Syzygium spp.)',
    fbGreenMPa: 30.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.8,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset bottlebrush = SpeciesPreset(
    id: 'bottlebrush',
    displayName: 'Bottlebrush (Callistemon / Melaleuca)',
    fbGreenMPa: 26.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  // ============ EXOTIC / INTRODUCED ============

  static const SpeciesPreset londonPlane = SpeciesPreset(
    id: 'london_plane',
    displayName: 'London Plane (Platanus × acerifolia)',
    fbGreenMPa: 28.0,
    dragCoefficient: 0.32,
    crownShapeFactor: 0.8,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset englishElm = SpeciesPreset(
    id: 'english_elm',
    displayName: 'English Elm (Ulmus procera)',
    fbGreenMPa: 26.0,
    dragCoefficient: 0.32,
    crownShapeFactor: 0.8,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset dutchElm = SpeciesPreset(
    id: 'dutch_elm',
    displayName: 'Dutch Elm (Ulmus × hollandica)',
    fbGreenMPa: 24.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.75,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset englishOak = SpeciesPreset(
    id: 'english_oak',
    displayName: 'English Oak (Quercus robur)',
    fbGreenMPa: 32.0,
    dragCoefficient: 0.32,
    crownShapeFactor: 0.8,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset pinOak = SpeciesPreset(
    id: 'pin_oak',
    displayName: 'Pin Oak (Quercus palustris)',
    fbGreenMPa: 30.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.75,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset liquidambar = SpeciesPreset(
    id: 'liquidambar',
    displayName: 'Liquidambar (Liquidambar styraciflua)',
    fbGreenMPa: 26.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset tulipTree = SpeciesPreset(
    id: 'tulip_tree',
    displayName: 'Tulip Tree (Liriodendron tulipifera)',
    fbGreenMPa: 24.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.7,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset ash = SpeciesPreset(
    id: 'ash',
    displayName: 'Ash (Fraxinus spp.)',
    fbGreenMPa: 28.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.75,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset birch = SpeciesPreset(
    id: 'birch',
    displayName: 'Birch (Betula spp.)',
    fbGreenMPa: 22.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.65,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset poplar = SpeciesPreset(
    id: 'poplar',
    displayName: 'Poplar (Populus spp.)',
    fbGreenMPa: 20.0,
    dragCoefficient: 0.26,
    crownShapeFactor: 0.6,
    defaultFullness: 0.85,
  );

  static const SpeciesPreset willow = SpeciesPreset(
    id: 'willow',
    displayName: 'Willow (Salix spp.)',
    fbGreenMPa: 18.0,
    dragCoefficient: 0.35,
    crownShapeFactor: 0.85,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset camphorLaurel = SpeciesPreset(
    id: 'camphor_laurel',
    displayName: 'Camphor Laurel (Cinnamomum camphora)',
    fbGreenMPa: 24.0,
    dragCoefficient: 0.32,
    crownShapeFactor: 0.8,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset magnolia = SpeciesPreset(
    id: 'magnolia',
    displayName: 'Magnolia (Magnolia grandiflora)',
    fbGreenMPa: 26.0,
    dragCoefficient: 0.32,
    crownShapeFactor: 0.8,
    defaultFullness: 0.95,
  );

  // ============ CONIFERS ============

  static const SpeciesPreset radiataPine = SpeciesPreset(
    id: 'radiata_pine',
    displayName: 'Radiata Pine (Pinus radiata)',
    fbGreenMPa: 18.0,
    dragCoefficient: 0.35,
    crownShapeFactor: 0.7,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset cypressPine = SpeciesPreset(
    id: 'cypress_pine',
    displayName: 'Cypress Pine (Callitris spp.)',
    fbGreenMPa: 22.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.65,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset monterey_cypress = SpeciesPreset(
    id: 'monterey_cypress',
    displayName: 'Monterey Cypress (Cupressus macrocarpa)',
    fbGreenMPa: 20.0,
    dragCoefficient: 0.32,
    crownShapeFactor: 0.75,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset leyland_cypress = SpeciesPreset(
    id: 'leyland_cypress',
    displayName: 'Leyland Cypress (× Cuprocyparis leylandii)',
    fbGreenMPa: 18.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.7,
    defaultFullness: 0.95,
  );

  // ============ PALMS ============

  static const SpeciesPreset cocosPalm = SpeciesPreset(
    id: 'cocos_palm',
    displayName: 'Cocos Palm (Syagrus romanzoffiana)',
    fbGreenMPa: 15.0,
    dragCoefficient: 0.40,
    crownShapeFactor: 0.5,
    defaultFullness: 0.7,
  );

  static const SpeciesPreset phoenixPalm = SpeciesPreset(
    id: 'phoenix_palm',
    displayName: 'Phoenix / Canary Palm (Phoenix canariensis)',
    fbGreenMPa: 18.0,
    dragCoefficient: 0.45,
    crownShapeFactor: 0.6,
    defaultFullness: 0.8,
  );

  static const SpeciesPreset washingtoniaPalm = SpeciesPreset(
    id: 'washingtonia_palm',
    displayName: 'Washingtonia Palm (Washingtonia robusta)',
    fbGreenMPa: 14.0,
    dragCoefficient: 0.38,
    crownShapeFactor: 0.5,
    defaultFullness: 0.7,
  );

  static const SpeciesPreset bangalowPalm = SpeciesPreset(
    id: 'bangalow_palm',
    displayName: 'Bangalow Palm (Archontophoenix cunninghamiana)',
    fbGreenMPa: 12.0,
    dragCoefficient: 0.35,
    crownShapeFactor: 0.5,
    defaultFullness: 0.7,
  );

  // ============ GENERIC / UNKNOWN ============

  static const SpeciesPreset eucTypical = SpeciesPreset(
    id: 'euc_typical',
    displayName: 'Eucalypt – Generic/Typical',
    fbGreenMPa: 35.0,
    dragCoefficient: 0.25,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset unknownHardwood = SpeciesPreset(
    id: 'unknown_hardwood',
    displayName: 'Unknown Hardwood (broadleaf)',
    fbGreenMPa: 25.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset unknownSoftwood = SpeciesPreset(
    id: 'unknown_softwood',
    displayName: 'Unknown Softwood / Evergreen',
    fbGreenMPa: 18.0,
    dragCoefficient: 0.33,
    crownShapeFactor: 0.75,
    defaultFullness: 0.95,
  );

  static final Map<String, SpeciesPreset> all = {
    // Eucalypts
    ironbark.id: ironbark,
    spottedGum.id: spottedGum,
    flooded_gum.id: flooded_gum,
    lemonScentedGum.id: lemonScentedGum,
    riverRedGum.id: riverRedGum,
    forestRedGum.id: forestRedGum,
    sydneyBlueGum.id: sydneyBlueGum,
    scribblyGum.id: scribblyGum,
    ghostGum.id: ghostGum,
    snowGum.id: snowGum,
    sugargum.id: sugargum,
    yellowBox.id: yellowBox,
    greyBox.id: greyBox,
    stringybark.id: stringybark,
    peppermint.id: peppermint,
    bloodwood.id: bloodwood,
    tallowwood.id: tallowwood,
    blackbutt.id: blackbutt,
    brushBox.id: brushBox,
    // Other natives
    melaleuca.id: melaleuca,
    casuarina.id: casuarina,
    bangalay.id: bangalay,
    angophora.id: angophora,
    moreton_bay_fig.id: moreton_bay_fig,
    portJacksonFig.id: portJacksonFig,
    banyaTree.id: banyaTree,
    hoopPine.id: hoopPine,
    norfolkPine.id: norfolkPine,
    jacaranda.id: jacaranda,
    poinciana.id: poinciana,
    silkyOak.id: silkyOak,
    tulipwood.id: tulipwood,
    leopardTree.id: leopardTree,
    tuckeroo.id: tuckeroo,
    lillypilly.id: lillypilly,
    bottlebrush.id: bottlebrush,
    // Exotic
    londonPlane.id: londonPlane,
    englishElm.id: englishElm,
    dutchElm.id: dutchElm,
    englishOak.id: englishOak,
    pinOak.id: pinOak,
    liquidambar.id: liquidambar,
    tulipTree.id: tulipTree,
    ash.id: ash,
    birch.id: birch,
    poplar.id: poplar,
    willow.id: willow,
    camphorLaurel.id: camphorLaurel,
    magnolia.id: magnolia,
    // Conifers
    radiataPine.id: radiataPine,
    cypressPine.id: cypressPine,
    monterey_cypress.id: monterey_cypress,
    leyland_cypress.id: leyland_cypress,
    // Palms
    cocosPalm.id: cocosPalm,
    phoenixPalm.id: phoenixPalm,
    washingtoniaPalm.id: washingtoniaPalm,
    bangalowPalm.id: bangalowPalm,
    // Generic
    eucTypical.id: eucTypical,
    unknownHardwood.id: unknownHardwood,
    unknownSoftwood.id: unknownSoftwood,
  };

  static List<SpeciesPreset> get list => all.values.toList(growable: false);
}

import '../enums/enums.dart';

/// Single source of truth for which classes clients can book and how each one
/// is shown. Screens never list vehicle classes on their own.
abstract class VehicleCatalog {
  /// Classes offered to clients, cheapest first. First Class only appears when
  /// the admin has enabled it.
  static List<VehicleClass> bookable({required bool firstClassEnabled}) => [
        VehicleClass.business,
        VehicleClass.businessSuv,
        VehicleClass.businessVan,
        if (firstClassEnabled) VehicleClass.firstClass,
      ];

  /// Transparent PNG of the vehicle. Classes without a real photo yet
  /// (Business SUV) fall back to an illustration when the file is missing,
  /// so dropping the photo into the folder is all it takes to show it.
  static String carImage(VehicleClass vc) =>
      'assets/images/vehicles/${vc.assetKey}/car.png';

  /// Up to three photos for the "Detalles" carousel, in order. Only the files
  /// that exist are shown; see [VehicleDetailsGallery].
  static List<String> galleryPhotos(VehicleClass vc) => [
        for (var i = 1; i <= 3; i++)
          'assets/images/vehicles/${vc.assetKey}/gallery_$i.png',
      ];

  /// Photo of the trunk for a luggage option (illustration if missing).
  static String luggagePhoto(VehicleClass vc, int option) =>
      'assets/images/booking/luggage/${vc.assetKey}_$option.png';

  /// Photo of the rear cabin for a seating option (illustration if missing).
  static String seatingPhoto(VehicleClass vc, int option) =>
      'assets/images/booking/seating/${vc.assetKey}_$option.png';

  static List<LuggageOption> luggage(VehicleClass vc) => switch (vc) {
        VehicleClass.businessVan => const [
            LuggageOption(4, LuggageSize.cabin),
            LuggageOption(2, LuggageSize.checked),
            LuggageOption(1, LuggageSize.oversize),
          ],
        VehicleClass.businessSuv => const [
            LuggageOption(8, LuggageSize.cabin),
            LuggageOption(4, LuggageSize.checked),
            LuggageOption(2, LuggageSize.oversize),
          ],
        VehicleClass.firstClass => const [
            LuggageOption(3, LuggageSize.cabin),
            LuggageOption(2, LuggageSize.checked),
            LuggageOption(1, LuggageSize.oversize),
          ],
        _ => const [
            LuggageOption(4, LuggageSize.cabin),
            LuggageOption(3, LuggageSize.checked),
            LuggageOption(2, LuggageSize.oversize),
          ],
      };

  static List<SeatingOption> seating(VehicleClass vc) {
    final max = vc.capacity;
    return [
      SeatingOption(max, title: '$max pasajeros', detail: 'Capacidad máxima'),
      SeatingOption(max - 1,
          title: '${max - 1} pasajeros', detail: 'Más espacio para cada uno'),
      SeatingOption(max - 1,
          childSeat: true,
          title: 'Con asiento infantil',
          detail: 'Bajo solicitud previa'),
    ];
  }

  /// Short, factual lines for the "Detalles" gallery.
  static List<String> highlights(VehicleClass vc) => switch (vc) {
        VehicleClass.business => const [
            'Sedán ejecutivo, discreto y silencioso',
            'Asientos traseros en cuero para tres',
            'Maletero para tres maletas facturadas',
          ],
        VehicleClass.businessSuv => const [
            'SUV ejecutiva, posición de manejo elevada',
            'Cabina amplia para cuatro pasajeros',
            'Maletero para cuatro maletas facturadas',
          ],
        VehicleClass.businessVan => const [
            'Van ejecutiva para grupos y familias',
            'Hasta siete pasajeros en tres filas',
            'Espacio para dos maletas facturadas',
          ],
        VehicleClass.firstClass => const [
            'Sedán insignia, nuestro máximo nivel',
            'Plazas traseras con apoyabrazos central',
            'Maletero para dos maletas facturadas',
          ],
        VehicleClass.electric => const [
            'Sedán ejecutivo totalmente eléctrico',
            'Silencioso y sin emisiones',
            'Maletero para dos maletas facturadas',
          ],
      };
}

enum LuggageSize { cabin, checked, oversize }

extension LuggageSizeX on LuggageSize {
  String get singular => switch (this) {
        LuggageSize.cabin => 'maleta de mano',
        LuggageSize.checked => 'maleta facturada',
        LuggageSize.oversize => 'maleta extra grande',
      };
  String get plural => switch (this) {
        LuggageSize.cabin => 'maletas de mano',
        LuggageSize.checked => 'maletas facturadas',
        LuggageSize.oversize => 'maletas extra grandes',
      };
  String get dimensions => switch (this) {
        LuggageSize.cabin => 'Hasta 55 × 40 × 20 cm',
        LuggageSize.checked => 'Hasta 75 × 50 × 30 cm',
        LuggageSize.oversize => 'Más de 80 cm',
      };
}

class LuggageOption {
  const LuggageOption(this.count, this.size);
  final int count;
  final LuggageSize size;
  String get title => '$count ${count == 1 ? size.singular : size.plural}';
}

class SeatingOption {
  const SeatingOption(
    this.passengers, {
    required this.title,
    required this.detail,
    this.childSeat = false,
  });
  final int passengers;
  final bool childSeat;
  final String title;
  final String detail;
}

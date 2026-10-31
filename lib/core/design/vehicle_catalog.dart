import 'package:flutter/painting.dart';

import '../../l10n/l10n.dart';
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

  /// Transparent WebP of the vehicle. Classes without a real photo yet
  /// (Business SUV) fall back to an illustration when the file is missing,
  /// so dropping the photo into the folder is all it takes to show it.
  static String carImage(VehicleClass vc) =>
      'assets/images/vehicles/${vc.assetKey}/car.webp';

  /// Up to three photos for the "Detalles" carousel, in order. Only the files
  /// that exist are shown; see [VehicleDetailsGallery].
  static List<String> galleryPhotos(VehicleClass vc) => [
        for (var i = 1; i <= 3; i++)
          'assets/images/vehicles/${vc.assetKey}/gallery_$i.webp',
      ];

  /// Photo of the trunk for a luggage option (illustration if missing).
  static String luggagePhoto(VehicleClass vc, int option) =>
      'assets/images/booking/luggage/${vc.assetKey}_$option.webp';

  /// Photo of the rear cabin for a seating option (illustration if missing).
  static String seatingPhoto(VehicleClass vc, int option) =>
      'assets/images/booking/seating/${vc.assetKey}_$option.webp';

  /// Signature colours of each class: soft enough for large backgrounds,
  /// distinct enough that the interface changes with the car you pick.
  static VehicleTone tone(VehicleClass vc) => switch (vc) {
        // Mist blue
        VehicleClass.business => const VehicleTone(
            wash: Color(0xFFEAF0F8),
            stage: Color(0xFFD5E1F0),
            accent: Color(0xFF2B4E7E),
          ),
        // Sage slate
        VehicleClass.businessSuv => const VehicleTone(
            wash: Color(0xFFE9F1EE),
            stage: Color(0xFFD0E2DB),
            accent: Color(0xFF2E5B50),
          ),
        // Lavender grey
        VehicleClass.businessVan => const VehicleTone(
            wash: Color(0xFFEFEDF6),
            stage: Color(0xFFDDD8EC),
            accent: Color(0xFF4A4373),
          ),
        // Bordeaux rose
        VehicleClass.firstClass => const VehicleTone(
            wash: Color(0xFFF5EDF0),
            stage: Color(0xFFEAD7DE),
            accent: Color(0xFF6E2E42),
          ),
        // Glacier teal
        VehicleClass.electric => const VehicleTone(
            wash: Color(0xFFE8F3F4),
            stage: Color(0xFFCFE6E8),
            accent: Color(0xFF235F67),
          ),
      };

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
    final t = L10n.current;
    return [
      SeatingOption(
        max,
        title: t.commonSeatingPassengers(max),
        detail: t.commonSeatingMaxDetail,
      ),
      SeatingOption(
        max - 1,
        title: t.commonSeatingPassengers(max - 1),
        detail: t.commonSeatingRoomierDetail,
      ),
      SeatingOption(
        max - 1,
        childSeat: true,
        title: t.commonSeatingChildSeat,
        detail: t.commonSeatingChildSeatDetail,
      ),
    ];
  }

  /// Short, factual lines for the "Detalles" gallery.
  static List<String> highlights(VehicleClass vc) {
    final t = L10n.current;
    return switch (vc) {
      VehicleClass.business => [
          t.commonHighlightBusiness1,
          t.commonHighlightBusiness2,
          t.commonHighlightBusiness3,
        ],
      VehicleClass.businessSuv => [
          t.commonHighlightSuv1,
          t.commonHighlightSuv2,
          t.commonHighlightSuv3,
        ],
      VehicleClass.businessVan => [
          t.commonHighlightVan1,
          t.commonHighlightVan2,
          t.commonHighlightVan3,
        ],
      VehicleClass.firstClass => [
          t.commonHighlightFirst1,
          t.commonHighlightFirst2,
          t.commonHighlightTwoCheckedBags,
        ],
      VehicleClass.electric => [
          t.commonHighlightElectric1,
          t.commonHighlightElectric2,
          t.commonHighlightTwoCheckedBags,
        ],
    };
  }
}

enum LuggageSize { cabin, checked, oversize }

extension LuggageSizeX on LuggageSize {
  String get singular => switch (this) {
        LuggageSize.cabin => L10n.current.commonLuggageCabinOne,
        LuggageSize.checked => L10n.current.commonLuggageCheckedOne,
        LuggageSize.oversize => L10n.current.commonLuggageOversizeOne,
      };
  String get plural => switch (this) {
        LuggageSize.cabin => L10n.current.commonLuggageCabinMany,
        LuggageSize.checked => L10n.current.commonLuggageCheckedMany,
        LuggageSize.oversize => L10n.current.commonLuggageOversizeMany,
      };
  String get dimensions => switch (this) {
        LuggageSize.cabin => L10n.current.commonLuggageCabinSize,
        LuggageSize.checked => L10n.current.commonLuggageCheckedSize,
        LuggageSize.oversize => L10n.current.commonLuggageOversizeSize,
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

/// Colours that follow the selected class across the booking screen.
class VehicleTone {
  const VehicleTone({
    required this.wash,
    required this.stage,
    required this.accent,
  });

  /// Page background behind the class.
  final Color wash;

  /// Bottom of the gradient the car stands on.
  final Color stage;

  /// Borders, checks and indicators.
  final Color accent;

  /// Backdrop for the car: white at the top fading into [stage].
  LinearGradient get stageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFFFFF), stage],
      );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../utils/app_colors.dart';

class PlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final PlaceType? placeType;
  final Color? backgroundColor;
  final Color? borderColor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<Prediction>? onItemClick;
  final ValueChanged<Prediction>? onPlaceDetails;

  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.focusNode,
    this.validator,
    this.placeType,
    this.backgroundColor,
    this.borderColor,
    this.onChanged,
    this.onItemClick,
    this.onPlaceDetails,
  });

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  late final TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    return GooglePlaceAutoCompleteTextField(
      validator: (value, _) => widget.validator?.call(value),
      focusNode: widget.focusNode,
      boxDecoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.inputFill,
        border: Border.all(color: widget.borderColor ?? Colors.white),
        borderRadius: BorderRadius.circular(10),
      ),
      textEditingController: _internalController,
      googleAPIKey: "AIzaSyCnfQ-TTa0kZzAPvcgc9qyorD34aIxaZhk",
      textStyle: const TextStyle(fontSize: 14),
      countries: const ["in"],
      isLatLngRequired: true,
      isCrossBtnShown: true,
      itemClick: (prediction) {
        _internalController.text = prediction.description ?? "";
        _internalController.selection = TextSelection.fromPosition(
          TextPosition(offset: _internalController.text.length),
        );
        widget.onItemClick?.call(prediction);
      },
      getPlaceDetailWithLatLng: (prediction) {
        widget.onPlaceDetails?.call(prediction);
      },
      placeType: widget.placeType,
      inputDecoration: InputDecoration(
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: .5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        filled: true,
        fillColor: Colors.transparent,
        isDense: true,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black38),
        ),
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, color: AppColors.primary)
            : null,
        hintText: widget.hint,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
      formSubmitCallback: () {
        widget.onChanged?.call(_internalController.text);
      },
    );
  }
}

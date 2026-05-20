import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationController extends GetxController {
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  LatLng? get myPosition {
    // Se ainda estiver carregando ou as coordenadas forem 0, retornamos null
    if (latitude.value == 0.0 && longitude.value == 0.0) return null;
    return LatLng(latitude.value, longitude.value);
  }

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    _checkPermissionAndStartTracking();
  }

  @override
  void onClose() {
    _positionStreamSubscription?.cancel();
    super.onClose();
  }

  Future<void> _checkPermissionAndStartTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      isLoading.value = false;
      errorMessage.value =
          'O serviço de localização está desativado no aparelho.';
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        isLoading.value = false;
        errorMessage.value = 'Permissão de localização negada pelo usuário.';
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      isLoading.value = false;
      errorMessage.value =
          'As permissões de localização foram permanentemente negadas. Ative nas configurações.';
      return;
    }

    _startTracking();
  }

  void _startTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            latitude.value = position.latitude;
            longitude.value = position.longitude;
            isLoading.value = false;
            errorMessage.value = ''; 
            print("Localização Coletada: Lat ${position.latitude}, Lon ${position.longitude}");
          },
          onError: (error) {
            errorMessage.value = 'Erro ao obter localização: $error';
          },
        );
  }
}

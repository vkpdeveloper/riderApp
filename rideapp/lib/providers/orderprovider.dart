import 'package:flutter/material.dart';
import 'package:rideapp/controllers/static_utils.dart';
import 'package:rideapp/providers/locationViewProvider.dart';

class OrderProvider with ChangeNotifier {
  int _selectedPaymentMethod;
  String _receiverName;
  String _receiverPhone;
  String _truckName;
  int _orderPrice;
  double _totalDistance;
  StaticUtils _utils = StaticUtils();
  List<String> _trucksCategory = [
    "Mini",
    "Small",
    "Medium",
    "Big"
  ];
  String _selectedTruck = "Mini";

  OrderProvider() {
    _selectedPaymentMethod = 0;
    _totalDistance = 0;
    _orderPrice = 0;
    _receiverName = "";
    _receiverPhone = "";
    _truckName = "";
  }

  int get getSelectedPaymentMethod => _selectedPaymentMethod;

  String get getReceiverName => _receiverName;

  String get getReceiverPhone => _receiverPhone;

  String get getTruckName => _truckName;

  int get getOrderPrice => _orderPrice;

  double get getTotalDistance => _totalDistance;

  String get getSelectedTruck => _selectedTruck;

  List<String> get getTruckCategory => _trucksCategory;

  void setPaymentMethod(int id) {
    _selectedPaymentMethod = id;
    notifyListeners();
  }

  void setTruckCategory(String cat) {
    _selectedTruck = cat;
    notifyListeners();
  }

  void setOrderPrice(LocationViewProvider provider) async {
    _totalDistance = _utils.distanceInKmBetweenEarthCoordinates(
        provider.getPickUpLatLng, provider.getDestinationLatLng);
    print(_totalDistance);
    _orderPrice = ((_totalDistance) * 20).round();
    notifyListeners();
  }

  void setReceiverPhone(String phone) {
    _receiverPhone = phone;
    notifyListeners();
  }

  void setReceiverName(String name) {
    _receiverName = name;
    notifyListeners();
  }

  void setTruckName(String truck) {
    _truckName = truck;
    notifyListeners();
  }
}

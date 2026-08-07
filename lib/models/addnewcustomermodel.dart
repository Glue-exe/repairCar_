
class AddNewCustomerModel {
  String cusFirstname;
  String cusLastname;
  String cusPhone;
  String vehLicenseplate;
  int brandId; 
  String vehModel;
  String vehColor;
  String vehYear;

  AddNewCustomerModel({
    required this.cusFirstname,
    required this.cusLastname,
    required this.cusPhone,
    required this.vehLicenseplate,
    required this.brandId,
    required this.vehModel,
    required this.vehColor,
    required this.vehYear,
  });

  Map<String, dynamic> toJson() {
    return{
      'cus_firstname' : cusFirstname,
      'cus_lastname' : cusLastname,
      'cus_phone' : cusPhone,
      'veh_lecenseplate' : vehLicenseplate,
      'band_id': brandId,
      'veh_model' : vehModel,
      'veh_color' : vehColor,
      'veh_year' : vehYear,
    };
  }
}
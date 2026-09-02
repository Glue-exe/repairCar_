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
    return {
      'first_name': cusFirstname,
      'last_name': cusLastname,
      'phone': cusPhone,
      'license_plate': vehLicenseplate,
      'brand_id': brandId,
      'model_name': vehModel,
      'color': vehColor,
      'year': vehYear,
      // create_table_latest.sql fields
      'cus_first_name': cusFirstname,
      'cus_last_name': cusLastname,
      'cus_phone': cusPhone,
      'v_license_plate': vehLicenseplate,
      'vb_id': brandId,
      'vm_brand_id': brandId,
      'vm_name': vehModel,
      'v_color': vehColor,
      'v_year': vehYear,
      // legacy keys
      'cus_firstname': cusFirstname,
      'cus_lastname': cusLastname,
      'veh_licenseplate': vehLicenseplate,
      'veh_model': vehModel,
      'veh_color': vehColor,
      'veh_year': vehYear,
    };
  }
}
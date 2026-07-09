class EndPoints {
//home screen_______________________________
  static const String countriesCities = '/equipment/locations'; //get
  // Catalogue screen_______________________________
  static const String getProducts = '/equipment/products'; //get
  static const String getCategories = '/equipment/categories'; //get
  static const String getSubCategories = '/equipment/subcategories'; //get
  // see more options __________________________________________
  static const String getSeeMoreData = '/equipment/deals'; //get + id
  // Cart __________________________________________
  static const String addProductToCart = '/cart/add_to_cart'; //post
//auth________________________________________________
  static const String signingUp = '/auth/register'; //post
  static const String verifySigningUpOTP = '/auth/register/verify-otp'; //post
  static const String verifyForgetPassOTP = '/auth/verify-reset-otp'; //post
  static const String resendSigningUpOTP = '/auth/register/resend-otp'; //post
  static const String signingIn = 'mobile/login'; //post
  static const String forgetPassword = '/auth/forgot-password'; //post
  static const String loggingOut = 'mobile/logout'; //post
  static const String verifyResetPassOTP = 'mobile/verify-otp'; //post
  static const String verifyResetPass = '/auth/reset-password'; //post
  static const String changePass = '/auth/profile/password'; //post
  static const String getProfileData = '/mobile/get-unit-details'; //get getting profile data and put in the case of editing profile data
// ── Passes ────────────────────────────────────────────────────────────────────
  static const String getPasses = 'mobile/get-passes';           // POST
  static const String todayPassesCount = 'mobile/today-passes-count'; // POST
  static const String checkFinance = 'mobile/check-finance';     // POST
  static const String storePass = 'mobile/store-pass';

// ── Profile / Account ─────────────────────────────────────────────────────────
  static const String getUnitDetails = 'mobile/get-unit-details'; // POST
  static const String deleteAccount = 'mobile/delete-account';   // POST

}
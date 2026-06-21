String getLanguageName(String languageCode) {
  switch (languageCode) {
    case "en":
      return "English";
    case "it":
      return "Italiano";
    default:
      return languageCode.toUpperCase();
  }
}

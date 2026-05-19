import 'package:flutter/foundation.dart';

class ApiConstants {
  // ✨ L'URL unique de votre application
  // En mode debug (émulateur), on peut garder l'adresse locale
  // En mode release (vrai téléphone), on met l'URL Render
  
  static const String baseUrl = kReleaseMode 
      ? 'https://task-management-api-xuok.onrender.com/api' // 🚀 REMPLACEZ PAR VOTRE VRAIE URL RENDER
      : 'http://10.0.2.2:3000/api';               // 💻 URL Locale pour l'émulateur
}

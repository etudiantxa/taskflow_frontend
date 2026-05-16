import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/task_hive.dart';

class CacheService {
  // ✨ Nom de la boîte Hive
  static const String taskBoxName = 'tasks';

  // ✨ INITIALISER HIVE
  static Future<void> initHive() async {
    try {
      // Initialiser Hive avec Flutter
      await Hive.initFlutter();

      // Enregistrer l'adaptateur TaskHive
      Hive.registerAdapter(TaskHiveAdapter());

      // Ouvrir la boîte
      await Hive.openBox<TaskHive>(taskBoxName);

      print('✅ Hive initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation de Hive: $e');
    }
  }

  // ✨ SAUVEGARDER LES TÂCHES DANS LE CACHE
  static Future<void> saveTasks(List<Task> tasks) async {
    try {
      final box = Hive.box<TaskHive>(taskBoxName);

      // Convertir Task en TaskHive
      final taskHiveList = tasks.map((task) => TaskHive.fromTask(task)).toList();

      // Vider la boîte (supprimer les anciennes données)
      await box.clear();

      // Sauvegarder les nouvelles données
      // Utiliser l'ID comme clé pour faciliter les recherches
      for (int i = 0; i < taskHiveList.length; i++) {
        await box.putAt(i, taskHiveList[i]);
      }

      print('✅ ${taskHiveList.length} tâches sauvegardées dans le cache');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
    }
  }

  // ✨ RÉCUPÉRER LES TÂCHES DU CACHE
  static Future<List<Task>> getTasks() async {
    try {
      final box = Hive.box<TaskHive>(taskBoxName);

      if (box.isEmpty) {
        print('⚠️ Cache vide');
        return [];
      }

      // Convertir TaskHive en Task
      final tasks = box.values.map((taskHive) => taskHive.toTask()).toList();

      print('✅ ${tasks.length} tâches récupérées du cache');
      return tasks;
    } catch (e) {
      print('❌ Erreur lors de la récupération: $e');
      return [];
    }
  }

  // ✨ RÉCUPÉRER UNE TÂCHE PAR ID
  static Future<Task?> getTaskById(String id) async {
    try {
      final box = Hive.box<TaskHive>(taskBoxName);

      for (var taskHive in box.values) {
        if (taskHive.id == id) {
          return taskHive.toTask();
        }
      }

      print('⚠️ Tâche avec ID $id non trouvée');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération: $e');
      return null;
    }
  }

  // ✨ SAUVEGARDER UNE TÂCHE UNIQUE
  static Future<void> saveTask(Task task) async {
    try {
      final box = Hive.box<TaskHive>(taskBoxName);
      final taskHive = TaskHive.fromTask(task);

      // Chercher si la tâche existe déjà
      int? existingIndex;
      for (int i = 0; i < box.length; i++) {
        if (box.getAt(i)?.id == taskHive.id) {
          existingIndex = i;
          break;
        }
      }

      if (existingIndex != null) {
        // Mettre à jour
        await box.putAt(existingIndex, taskHive);
        print('✅ Tâche mise à jour dans le cache');
      } else {
        // Ajouter
        await box.add(taskHive);
        print('✅ Tâche ajoutée au cache');
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
    }
  }

  // ✨ SUPPRIMER UNE TÂCHE
  static Future<void> deleteTask(String id) async {
    try {
      final box = Hive.box<TaskHive>(taskBoxName);

      for (int i = 0; i < box.length; i++) {
        if (box.getAt(i)?.id == id) {
          await box.deleteAt(i);
          print('✅ Tâche supprimée du cache');
          return;
        }
      }

      print('⚠️ Tâche avec ID $id non trouvée');
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
    }
  }

  // ✨ VIDER TOUT LE CACHE
  static Future<void> clearCache() async {
    try {
      final box = Hive.box<TaskHive>(taskBoxName);
      await box.clear();
      print('✅ Cache vidé');
    } catch (e) {
      print('❌ Erreur lors du vidage: $e');
    }
  }

  // ✨ OBTENIR LE NOMBRE DE TÂCHES EN CACHE
  static int getCacheSize() {
    try {
      final box = Hive.box<TaskHive>(taskBoxName);
      return box.length;
    } catch (e) {
      print('❌ Erreur: $e');
      return 0;
    }
  }

  // ✨ VÉRIFIER SI LE CACHE EST VIDE
  static bool isCacheEmpty() {
    try {
      final box = Hive.box<TaskHive>(taskBoxName);
      return box.isEmpty;
    } catch (e) {
      print('❌ Erreur: $e');
      return true;
    }
  }
}
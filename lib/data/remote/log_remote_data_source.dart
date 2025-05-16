import '../models/log_model.dart';
import 'base_remote_data_source.dart';

class LogRemoteDataSource extends BaseRemoteDataSource<Log> {
  LogRemoteDataSource() : super('logs');

  Future<Log?> getLogById(String id) async {
    try {
      final response = await getById(id);
      if (response == null) return null;

      return Log.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<Log>> getAllLogs() async {
    try {
      final response = await getAll();

      return response.map((json) => Log.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> createLog(Log log) async {
    try {
      final response = await insert(log.toJson());
      if (response == null) return null;

      return response['id'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateLog(Log log) async {
    try {
      await update(log.id, log.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLog(String id) async {
    try {
      await delete(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Log>> getLogsByEntityId(String entityId) async {
    try {
      final response = await supabase
          .from('logs')
          .select()
          .eq('entity_id', entityId)
          .order('created_at', ascending: false);

      return response.map((json) => Log.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Log>> getLogsByType(LogType logType) async {
    try {
      final response = await supabase
          .from('logs')
          .select()
          .eq('log_type', logType.toString().split('.').last)
          .order('created_at', ascending: false);

      return response.map((json) => Log.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Log>> getLogsByAction(String action) async {
    try {
      final response = await supabase
          .from('logs')
          .select()
          .eq('action', action)
          .order('created_at', ascending: false);

      return response.map((json) => Log.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}

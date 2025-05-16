import '../models/log_model.dart';
import '../local/log_local_data_source.dart';
import '../remote/log_remote_data_source.dart';

class LogRepository {
  final LogRemoteDataSource _remoteDataSource;
  final LogLocalDataSource _localDataSource;

  LogRepository({
    required LogRemoteDataSource remoteDataSource,
    required LogLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  Future<Log?> getLogById(String id, {bool forceRemote = false}) async {
    if (forceRemote) {
      final log = await _remoteDataSource.getLogById(id);
      if (log != null) {
        await _localDataSource.updateLog(log);
      }
      return log;
    }

    final localLog = await _localDataSource.getLogById(id);
    if (localLog != null) {
      return localLog;
    }

    final remoteLog = await _remoteDataSource.getLogById(id);
    if (remoteLog != null) {
      await _localDataSource.insertLog(remoteLog);
    }
    return remoteLog;
  }

  Future<List<Log>> getAllLogs({bool forceRemote = false}) async {
    if (forceRemote) {
      final logs = await _remoteDataSource.getAllLogs();
      // Update local cache
      for (final log in logs) {
        await _localDataSource.updateLog(log);
      }
      return logs;
    }

    final localLogs = await _localDataSource.getAllLogs();
    if (localLogs.isNotEmpty) {
      return localLogs;
    }

    final remoteLogs = await _remoteDataSource.getAllLogs();
    // Cache the logs locally
    for (final log in remoteLogs) {
      await _localDataSource.insertLog(log);
    }
    return remoteLogs;
  }

  Future<String> createLog(Log log) async {
    final id = await _remoteDataSource.createLog(log);
    if (id == null) {
      throw Exception('Failed to create log');
    }
    final logWithId = log.copyWith(id: id);
    await _localDataSource.insertLog(logWithId);
    return id;
  }

  Future<bool> updateLog(Log log) async {
    final updated = await _remoteDataSource.updateLog(log);
    if (updated) {
      await _localDataSource.updateLog(log);
      return true;
    }
    return false;
  }

  Future<bool> deleteLog(String id) async {
    final deleted = await _remoteDataSource.deleteLog(id);
    if (deleted) {
      await _localDataSource.deleteLog(id);
      return true;
    }
    return false;
  }

  Future<List<Log>> getLogsByEntityId(String entityId,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final logs = await _remoteDataSource.getLogsByEntityId(entityId);
      // Update local cache
      for (final log in logs) {
        await _localDataSource.updateLog(log);
      }
      return logs;
    }

    final localLogs = await _localDataSource.getLogsByEntityId(entityId);
    if (localLogs.isNotEmpty) {
      return localLogs;
    }

    final remoteLogs = await _remoteDataSource.getLogsByEntityId(entityId);
    // Cache the logs locally
    for (final log in remoteLogs) {
      await _localDataSource.insertLog(log);
    }
    return remoteLogs;
  }

  Future<List<Log>> getLogsByType(LogType logType,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final logs = await _remoteDataSource.getLogsByType(logType);
      // Update local cache
      for (final log in logs) {
        await _localDataSource.updateLog(log);
      }
      return logs;
    }

    final localLogs = await _localDataSource.getLogsByType(logType);
    if (localLogs.isNotEmpty) {
      return localLogs;
    }

    final remoteLogs = await _remoteDataSource.getLogsByType(logType);
    // Cache the logs locally
    for (final log in remoteLogs) {
      await _localDataSource.insertLog(log);
    }
    return remoteLogs;
  }

  Future<List<Log>> getLogsByAction(String action,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final logs = await _remoteDataSource.getLogsByAction(action);
      // Update local cache
      for (final log in logs) {
        await _localDataSource.updateLog(log);
      }
      return logs;
    }

    final localLogs = await _localDataSource.getLogsByAction(action);
    if (localLogs.isNotEmpty) {
      return localLogs;
    }

    final remoteLogs = await _remoteDataSource.getLogsByAction(action);
    // Cache the logs locally
    for (final log in remoteLogs) {
      await _localDataSource.insertLog(log);
    }
    return remoteLogs;
  }
}

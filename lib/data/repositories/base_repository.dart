abstract class BaseRepository<T> {
  Future<T> create(T item);
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<T> update(T item);
  Future<void> delete(String id);
}

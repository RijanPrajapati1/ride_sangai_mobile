/// One page of a list endpoint. Every list in the API looks like
/// `{ "items": [...], "nextCursor": "…" | null }`.
///
/// To get the next page, send `nextCursor` back as the `cursor` query
/// parameter. `nextCursor` is null on the last page.
class Paginated<T> {
  final List<T> items;
  final String? nextCursor;

  const Paginated({required this.items, this.nextCursor});

  bool get hasMore => nextCursor != null;

  factory Paginated.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic> item) fromItem) =>
      Paginated(
        items: (json['items'] as List).map((item) => fromItem(item as Map<String, dynamic>)).toList(),
        nextCursor: json['nextCursor'] as String?,
      );
}

typedef ProgressListener = void Function(double progress);

class FetchOptions {
  final Map<String, String>? headers;
  final bool? noResolveJson;

  const FetchOptions({this.headers, this.noResolveJson});
}

class Bucket {
  final String id;
  final String name;
  final String owner;
  final String createdAt;
  final String updatedAt;
  final bool public;

  const Bucket({
    required this.id,
    required this.name,
    required this.owner,
    required this.createdAt,
    required this.updatedAt,
    required this.public,
  });

  Bucket.fromJson(Map<String, dynamic> json)
      : id = (json)['id'] as String,
        name = json['name'] as String,
        owner = json['owner'] as String,
        createdAt = json['created_at'] as String,
        updatedAt = json['updated_at'] as String,
        public = json['public'] as bool;
}

class FileObject {
  final String name;
  final String? bucketId;
  final String? owner;
  final String? id;
  final String? updatedAt;
  final String? createdAt;
  final String? lastAccessedAt;
  final Map<String, dynamic>? metadata;
  final Bucket? buckets;

  const FileObject({
    required this.name,
    required this.bucketId,
    required this.owner,
    required this.id,
    required this.updatedAt,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.metadata,
    required this.buckets,
  });

  FileObject.fromJson(dynamic json)
      : id = (json as Map<String, dynamic>)['id'] as String?,
        name = json['name'] as String,
        bucketId = json['bucket_id'] as String?,
        owner = json['owner'] as String?,
        updatedAt = json['updated_at'] as String?,
        createdAt = json['created_at'] as String?,
        lastAccessedAt = json['last_accessed_at'] as String?,
        metadata = json['metadata'] as Map<String, dynamic>?,
        buckets =
            json['buckets'] != null ? Bucket.fromJson(json['buckets']) : null;
}

class BucketOptions {
  final bool public;

  const BucketOptions({required this.public});
}

class FileOptions {
  final String cacheControl;
  final bool upsert;

  /// Used as Content-Type
  /// Gets parsed with [MediaType.parse(mime)]
  ///
  /// Throws a FormatError if the media type is invalid.
  final String? contentType;

  const FileOptions({
    this.cacheControl = '3600',
    this.upsert = false,
    this.contentType,
  });
}

class SearchOptions {
  /// The number of files you want to be returned. */
  final int? limit;

  /// The starting position. */
  final int? offset;

  /// The column to sort by. Can be any column inside a FileObject. */
  final SortBy? sortBy;

  /// The search string to filter files by.
  final String? search;

  const SearchOptions({
    this.limit = 100,
    this.offset = 0,
    this.sortBy = const SortBy(
      column: 'name',
      order: 'asc',
    ),
    this.search,
  });

  Map<String, dynamic> toMap() {
    return {
      'limit': limit,
      'offset': offset,
      'sortBy': sortBy?.toMap(),
      'search': search,
    };
  }
}

class SortBy {
  final String? column;
  final String? order;

  const SortBy({this.column, this.order});

  Map<String, dynamic> toMap() {
    return {
      'column': column,
      'order': order,
    };
  }
}

class SignedUrl {
  final String? path;
  final String? signedUrl;

  const SignedUrl({this.path, this.signedUrl});

  @override
  String toString() => 'SignedUrl(path: $path, signedUrl: $signedUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SignedUrl &&
        other.path == path &&
        other.signedUrl == signedUrl;
  }

  @override
  int get hashCode => path.hashCode ^ signedUrl.hashCode;

  SignedUrl copyWith({
    String? path,
    String? signedUrl,
  }) {
    return SignedUrl(
      path: path ?? this.path,
      signedUrl: signedUrl ?? this.signedUrl,
    );
  }
}

class StorageException implements Exception {
  final String message;
  final String? error;
  final String? statusCode;

  const StorageException(this.message, {this.error, this.statusCode}) : super();

  factory StorageException.fromJson(
    Map<String, dynamic> json, [
    String? statusCode,
  ]) =>
      StorageException(
        json['message'] as String? ?? json.toString(),
        error: json['error'] as String?,
        statusCode: (json['statusCode'] as String?) ?? statusCode,
      );

  @override
  String toString() {
    return 'StorageException(message: $message, statusCode: $statusCode, error: $error)';
  }
}

class StorageRetryController {
  /// Whether the retry operation is aborted
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  /// Creates a controller to abort storage file upload retry operations.
  StorageRetryController();

  /// Aborts the next retry operation
  void cancel() {
    _cancelled = true;
  }
}

/// {@template resize_mode}
/// Specifies how image cropping should be handled when performing image transformations.
/// {@endtemplate}
enum ResizeMode {
  /// Resizes the image while keeping the aspect ratio to fill a given size and crops projecting parts.
  cover,

  /// Resizes the image while keeping the aspect ratio to fit a given size.
  contain,

  /// Resizes the image without keeping the aspect ratio to fill a given size.
  fill,
}

/// {@template transform_options}
/// Specifies the dimensions and the resize mode of the requesting image.
/// {@endtemplate}
class TransformOptions {
  /// Width of the requesting image to be.
  final int? width;

  /// Height of requesting image to be.
  final int? height;

  /// {@macro resize_mode}
  ///
  /// [ResizeMode.cover] will be used if no value is specified.
  final ResizeMode? resize;

  /// {@macro transform_options}
  const TransformOptions({
    this.width,
    this.height,
    this.resize,
  });
}

extension ToQueryParams on TransformOptions {
  Map<String, String> get toQueryParams {
    return {
      if (width != null) 'width': '$width',
      if (height != null) 'height': '$height',
      if (resize != null) 'resize': resize!.snakeCase,
    };
  }
}

extension ToSnakeCase on Enum {
  String get snakeCase {
    final a = 'a'.codeUnitAt(0), z = 'z'.codeUnitAt(0);
    final A = 'A'.codeUnitAt(0), Z = 'Z'.codeUnitAt(0);
    final result = StringBuffer()..write(name[0].toLowerCase());
    for (var i = 1; i < name.length; i++) {
      final char = name.codeUnitAt(i);
      if (A <= char && char <= Z) {
        final pChar = name.codeUnitAt(i - 1);
        if (a <= pChar && pChar <= z) {
          result.write('_');
        }
      }
      result.write(name[i].toLowerCase());
    }
    return result.toString();
  }
}

import '../network/api_client.dart';

/// The gateway's rider-profile routes. Failures are thrown as ApiException; the
/// repository turns them into failures.
class RiderAccountApi {
  RiderAccountApi(this._client);

  final ApiClient _client;

  /// A refused session is thrown, not ended app-wide: the start screen decides.
  Future<JsonMap> findByIdentity(String identityId) => _client.get(
        '/v1/identities/${Uri.encodeComponent(identityId)}/rider',
        signOutOnExpiry: false,
      );

  Future<JsonMap> create({
    required String identityId,
    required String displayName,
  }) =>
      _client.post(
        '/v1/riders',
        body: <String, dynamic>{
          'identityId': identityId,
          'displayName': displayName,
        },
      );
}

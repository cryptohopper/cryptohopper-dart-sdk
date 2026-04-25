import '../transport.dart';

/// `client.social` — profiles, feed, posts, conversations, social graph.
/// Largest resource in the SDK (27 methods).
class Social {
  final Transport _transport;
  Social(this._transport);

  // Profiles.

  Future<dynamic> getProfile(Object aliasOrId) =>
      _transport.request('GET', '/social/getprofile', query: {'alias': aliasOrId});

  Future<dynamic> editProfile(Map<String, dynamic> data) =>
      _transport.request('POST', '/social/editprofile', body: data);

  Future<dynamic> checkAlias(String alias) =>
      _transport.request('GET', '/social/checkalias', query: {'alias': alias});

  // Feed / discovery.

  Future<dynamic> getFeed({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/social/getfeed',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> getTrends() => _transport.request('GET', '/social/gettrends');

  Future<dynamic> whoToFollow() => _transport.request('GET', '/social/whotofollow');

  Future<dynamic> search(String query) =>
      _transport.request('GET', '/social/search', query: {'q': query});

  // Notifications.

  Future<dynamic> getNotifications({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/social/getnotifications',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  // Conversations / messages.

  Future<dynamic> getConversationList() =>
      _transport.request('GET', '/social/getconversationlist');

  Future<dynamic> getConversation(Object conversationId) => _transport.request(
        'GET',
        '/social/loadconversation',
        query: {'conversation_id': conversationId},
      );

  Future<dynamic> sendMessage(Map<String, dynamic> data) =>
      _transport.request('POST', '/social/sendmessage', body: data);

  Future<dynamic> deleteMessage(Object messageId) =>
      _transport.request('POST', '/social/deletemessage', body: {'message_id': messageId});

  // Posts.

  Future<dynamic> createPost(Map<String, dynamic> data) =>
      _transport.request('POST', '/social/post', body: data);

  Future<dynamic> getPost(Object postId) =>
      _transport.request('GET', '/social/getpost', query: {'post_id': postId});

  Future<dynamic> deletePost(Object postId) =>
      _transport.request('POST', '/social/deletepost', body: {'post_id': postId});

  Future<dynamic> pinPost(Object postId) =>
      _transport.request('POST', '/social/pinpost', body: {'post_id': postId});

  // Comments.

  Future<dynamic> getComment(Object commentId) =>
      _transport.request('GET', '/social/getcomment', query: {'comment_id': commentId});

  Future<dynamic> getComments(Object postId) =>
      _transport.request('GET', '/social/getcomments', query: {'post_id': postId});

  Future<dynamic> deleteComment(Object commentId) =>
      _transport.request('POST', '/social/deletecomment', body: {'comment_id': commentId});

  // Media.

  Future<dynamic> getMedia(Object mediaId) =>
      _transport.request('GET', '/social/getmedia', query: {'media_id': mediaId});

  // Social graph.

  Future<dynamic> follow(Object aliasOrId) =>
      _transport.request('POST', '/social/follow', body: {'alias': aliasOrId});

  Future<dynamic> getFollowers(Object aliasOrId) =>
      _transport.request('GET', '/social/followers', query: {'alias': aliasOrId});

  Future<dynamic> getFollowing(Object aliasOrId) =>
      _transport.request('GET', '/social/following', query: {'alias': aliasOrId});

  Future<dynamic> getFollowingProfiles(Object aliasOrId) => _transport.request(
        'GET',
        '/social/followingprofiles',
        query: {'alias': aliasOrId},
      );

  // Engagement.

  Future<dynamic> like(Object postId) =>
      _transport.request('POST', '/social/like', body: {'post_id': postId});

  Future<dynamic> repost(Object postId) =>
      _transport.request('POST', '/social/repost', body: {'post_id': postId});

  // Moderation.

  Future<dynamic> blockUser(Object aliasOrId) =>
      _transport.request('POST', '/social/blockuser', body: {'alias': aliasOrId});
}

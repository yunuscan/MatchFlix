import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for movie watch proposals between matched users
class ProposalModel {
  final String proposalId;
  final String roomId;
  final String movieId;
  final String movieTitle;
  final String? moviePoster;
  final String proposerUserId;
  final String receiverUserId;
  final ProposalStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  ProposalModel({
    required this.proposalId,
    required this.roomId,
    required this.movieId,
    required this.movieTitle,
    this.moviePoster,
    required this.proposerUserId,
    required this.receiverUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Create from Firestore document
  factory ProposalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProposalModel(
      proposalId: doc.id,
      roomId: data['roomId'] ?? '',
      movieId: data['movieId'] ?? '',
      movieTitle: data['movieTitle'] ?? '',
      moviePoster: data['moviePoster'],
      proposerUserId: data['proposerUserId'] ?? '',
      receiverUserId: data['receiverUserId'] ?? '',
      status: ProposalStatus.values.firstWhere(
        (e) => e.toString() == 'ProposalStatus.${data['status']}',
        orElse: () => ProposalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'movieId': movieId,
      'movieTitle': movieTitle,
      'moviePoster': moviePoster,
      'proposerUserId': proposerUserId,
      'receiverUserId': receiverUserId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  /// Copy with modifications
  ProposalModel copyWith({
    ProposalStatus? status,
    DateTime? respondedAt,
  }) {
    return ProposalModel(
      proposalId: proposalId,
      roomId: roomId,
      movieId: movieId,
      movieTitle: movieTitle,
      moviePoster: moviePoster,
      proposerUserId: proposerUserId,
      receiverUserId: receiverUserId,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

/// Status of a proposal
enum ProposalStatus {
  pending, // Waiting for receiver's response
  accepted, // Receiver accepted, ready to watch
  rejected, // Receiver rejected
  cancelled, // Proposer cancelled
}

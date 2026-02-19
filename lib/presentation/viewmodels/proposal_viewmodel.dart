import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/proposal_model.dart';
import '../../data/services/firestore_service.dart';

/// ViewModel for managing movie watch proposals
class ProposalViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<ProposalModel> _proposals = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _proposalSubscription;
  String? _currentRoomId;

  ProposalViewModel(this._firestoreService);

  // Getters
  List<ProposalModel> get proposals => _proposals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get proposals sent by current user
  List<ProposalModel> get sentProposals => _proposals
      .where((p) => p.proposerUserId == _firestoreService.currentUserId)
      .toList();

  /// Get proposals received by current user
  List<ProposalModel> get receivedProposals => _proposals
      .where((p) => p.receiverUserId == _firestoreService.currentUserId)
      .toList();

  /// Get pending proposals received by current user
  List<ProposalModel> get pendingReceivedProposals => receivedProposals
      .where((p) => p.status == ProposalStatus.pending)
      .toList();

  /// Get count of pending proposals
  int get pendingProposalsCount => pendingReceivedProposals.length;

  /// Initialize and start listening to proposals
  void initialize(String roomId) {
    if (_currentRoomId == roomId && _proposalSubscription != null) {
      // Already listening to this room
      return;
    }

    _currentRoomId = roomId;
    _proposals = [];
    _error = null;
    _isLoading = true;
    notifyListeners();

    // Cancel previous subscription if exists
    _proposalSubscription?.cancel();

    // Listen to proposals
    _proposalSubscription = _firestoreService.listenToProposals(roomId).listen(
      (proposals) {
        _proposals = proposals;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load proposals: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Create a new proposal to watch a movie
  Future<bool> createProposal({
    required String roomId,
    required String movieId,
    required String movieTitle,
    String? moviePoster,
    required String receiverUserId,
  }) async {
    try {
      await _firestoreService.createProposal(
        roomId: roomId,
        movieId: movieId,
        movieTitle: movieTitle,
        moviePoster: moviePoster,
        receiverUserId: receiverUserId,
      );
      return true;
    } catch (e) {
      _error = 'Failed to send proposal: $e';
      notifyListeners();
      return false;
    }
  }

  /// Accept a proposal
  Future<bool> acceptProposal({
    required String roomId,
    required String proposalId,
  }) async {
    try {
      await _firestoreService.respondToProposal(
        roomId: roomId,
        proposalId: proposalId,
        status: ProposalStatus.accepted,
      );
      return true;
    } catch (e) {
      _error = 'Failed to accept proposal: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reject a proposal
  Future<bool> rejectProposal({
    required String roomId,
    required String proposalId,
  }) async {
    try {
      await _firestoreService.respondToProposal(
        roomId: roomId,
        proposalId: proposalId,
        status: ProposalStatus.rejected,
      );
      return true;
    } catch (e) {
      _error = 'Failed to reject proposal: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cancel a proposal (only for proposer)
  Future<bool> cancelProposal({
    required String roomId,
    required String proposalId,
  }) async {
    try {
      await _firestoreService.cancelProposal(
        roomId: roomId,
        proposalId: proposalId,
      );
      return true;
    } catch (e) {
      _error = 'Failed to cancel proposal: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get proposal status display text
  String getStatusText(ProposalModel proposal) {
    if (proposal.proposerUserId == _firestoreService.currentUserId) {
      // Sent by me
      switch (proposal.status) {
        case ProposalStatus.pending:
          return 'Bekliyor...';
        case ProposalStatus.accepted:
          return 'Kabul edildi ✅';
        case ProposalStatus.rejected:
          return 'Reddedildi ❌';
        case ProposalStatus.cancelled:
          return 'İptal edildi';
      }
    } else {
      // Received by me
      switch (proposal.status) {
        case ProposalStatus.pending:
          return 'Yanıt bekliyor';
        case ProposalStatus.accepted:
          return 'Kabul ettin ✅';
        case ProposalStatus.rejected:
          return 'Reddettin ❌';
        case ProposalStatus.cancelled:
          return 'İptal edildi';
      }
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _proposalSubscription?.cancel();
    super.dispose();
  }
}

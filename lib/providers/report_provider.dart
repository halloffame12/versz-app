import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../core/constants/appwrite_constants.dart';
import '../models/report.dart';
import 'package:appwrite/appwrite.dart';

enum ReportType {
  spam,
  harassment,
  misinformation,
  offensiveContent,
  otherViolation,
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(AppwriteService());
});

class ReportState {
  final List<Report> reports;
  final bool isLoading;
  final String? error;
  final bool success;

  ReportState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  ReportState copyWith({
    List<Report>? reports,
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return ReportState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final AppwriteService _appwrite;

  ReportNotifier(this._appwrite) : super(ReportState());

  Future<void> reportContent({
    required String targetId,
    required String targetType, // 'debate' or 'comment'
    required ReportType reportType,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      final user = await _appwrite.account.get();

      // Check if user already reported this content
      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reportsCollection,
        queries: [
          Query.equal('reporterId', user.$id),
          Query.equal('targetId', targetId),
          Query.equal('targetType', targetType),
        ],
      );

      if (existing.documents.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'You have already reported this content',
        );
        return;
      }

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reportsCollection,
        documentId: ID.unique(),
        data: {
          'reporterId': user.$id,
          'targetId': targetId,
          'targetType': targetType,
          'reason': reportType.toString().split('.').last,
          'status': 'pending',
          'description': description,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUserReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _appwrite.account.get();

      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reportsCollection,
        queries: [
          Query.equal('reporterId', user.$id),
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      final reports = response.documents
          .map((doc) => Report.fromMap(doc.data))
          .toList();

      state = state.copyWith(reports: reports, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAllReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reportsCollection,
        queries: [
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      final reports = response.documents
          .map((doc) => Report.fromMap(doc.data))
          .toList();

      state = state.copyWith(reports: reports, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resolveReport(String reportId) async {
    try {
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reportsCollection,
        documentId: reportId,
        data: {
          'status': 'resolved',
        },
      );

      await loadAllReports();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _appwrite.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reportsCollection,
        documentId: reportId,
      );

      await loadAllReports();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
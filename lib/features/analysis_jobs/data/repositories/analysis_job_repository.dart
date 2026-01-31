import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/analysis_job.dart';
import '../../domain/entities/analysis_report.dart';
import '../../domain/entities/job_enums.dart';

/// Repository for analysis jobs and reports persistence
class AnalysisJobRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AnalysisJobRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Jobs Collection
  CollectionReference get _jobsCollection =>
      _firestore.collection('users').doc(_userId).collection('analysis_jobs');

  // Reports Collection
  CollectionReference get _reportsCollection => _firestore
      .collection('users')
      .doc(_userId)
      .collection('analysis_reports');

  /// Get all jobs
  Future<List<AnalysisJob>> getJobs() async {
    final snapshot =
        await _jobsCollection.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => _jobFromFirestore(doc)).toList();
  }

  /// Get jobs stream
  Stream<List<AnalysisJob>> getJobsStream() {
    return _jobsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _jobFromFirestore(doc)).toList(),
        );
  }

  /// Add new job
  Future<void> addJob(AnalysisJob job) async {
    try {
      print('[AnalysisJobRepository] Adding job: ${job.id} - ${job.name}');
      await _jobsCollection.doc(job.id).set(_jobToFirestore(job));
      print('[AnalysisJobRepository] Job added successfully');
    } catch (e) {
      print('[AnalysisJobRepository] Error adding job: $e');
      rethrow;
    }
  }

  /// Update job
  Future<void> updateJob(AnalysisJob job) async {
    try {
      print('[AnalysisJobRepository] Updating job: ${job.id}');
      await _jobsCollection.doc(job.id).update(_jobToFirestore(job));
      print('[AnalysisJobRepository] Job updated successfully');
    } catch (e) {
      print('[AnalysisJobRepository] Error updating job: $e');
      rethrow;
    }
  }

  /// Delete job
  Future<void> deleteJob(String jobId) async {
    try {
      print('[AnalysisJobRepository] Deleting job: $jobId');
      await _jobsCollection.doc(jobId).delete();
      print('[AnalysisJobRepository] Job deleted successfully');
    } catch (e) {
      print('[AnalysisJobRepository] Error deleting job: $e');
      rethrow;
    }
  }

  /// Get reports for a job
  Future<List<AnalysisReport>> getReportsForJob(String jobId) async {
    final snapshot = await _reportsCollection
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => _reportFromFirestore(doc)).toList();
  }

  /// Get all reports
  Future<List<AnalysisReport>> getAllReports() async {
    final snapshot = await _reportsCollection
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => _reportFromFirestore(doc)).toList();
  }

  /// Add report
  Future<void> addReport(AnalysisReport report) async {
    await _reportsCollection.doc(report.id).set(_reportToFirestore(report));
  }

  /// Convert Firestore doc to AnalysisJob
  AnalysisJob _jobFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalysisJob(
      id: doc.id,
      name: data['name'] as String,
      type: JobType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => JobType.daily,
      ),
      runAt: (data['runAt'] as Timestamp).toDate(),
      scopes: (data['scopes'] as List)
          .map((s) => AnalysisScope.values.firstWhere(
                (scope) => scope.name == s,
                orElse: () => AnalysisScope.portfolio,
              ))
          .toList(),
      analysisTypes: (data['analysisTypes'] as List)
          .map((t) => AnalysisType.values.firstWhere(
                (type) => type.name == t,
                orElse: () => AnalysisType.risk,
              ))
          .toList(),
      notifyUser: data['notifyUser'] as bool? ?? true,
      isActive: data['isActive'] as bool? ?? true,
      lastRun: data['lastRun'] != null
          ? (data['lastRun'] as Timestamp).toDate()
          : null,
      nextRun: data['nextRun'] != null
          ? (data['nextRun'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert AnalysisJob to Firestore map
  Map<String, dynamic> _jobToFirestore(AnalysisJob job) {
    return {
      'name': job.name,
      'type': job.type.name,
      'runAt': Timestamp.fromDate(job.runAt),
      'scopes': job.scopes.map((s) => s.name).toList(),
      'analysisTypes': job.analysisTypes.map((t) => t.name).toList(),
      'notifyUser': job.notifyUser,
      'isActive': job.isActive,
      'lastRun': job.lastRun != null ? Timestamp.fromDate(job.lastRun!) : null,
      'nextRun': job.nextRun != null ? Timestamp.fromDate(job.nextRun!) : null,
      'createdAt': Timestamp.fromDate(job.createdAt),
    };
  }

  /// Convert Firestore doc to AnalysisReport
  AnalysisReport _reportFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalysisReport(
      id: doc.id,
      jobId: data['jobId'] as String,
      jobName: data['jobName'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      summaryTitle: data['summaryTitle'] as String,
      summaryText: data['summaryText'] as String,
      riskLevel: RiskLevel.values.firstWhere(
        (r) => r.name == data['riskLevel'],
        orElse: () => RiskLevel.low,
      ),
      highlights: List<String>.from(data['highlights'] as List),
    );
  }

  /// Convert AnalysisReport to Firestore map
  Map<String, dynamic> _reportToFirestore(AnalysisReport report) {
    return {
      'jobId': report.jobId,
      'jobName': report.jobName,
      'createdAt': Timestamp.fromDate(report.createdAt),
      'summaryTitle': report.summaryTitle,
      'summaryText': report.summaryText,
      'riskLevel': report.riskLevel.name,
      'highlights': report.highlights,
    };
  }
}

import 'package:equatable/equatable.dart';

import 'job_enums.dart';

/// Analysis job entity - represents a scheduled analysis task
class AnalysisJob extends Equatable {
  final String id;
  final String name;
  final JobType type;
  final DateTime runAt;
  final List<AnalysisScope> scopes;
  final List<AnalysisType> analysisTypes;
  final bool notifyUser;
  final bool isActive;
  final DateTime? lastRun;
  final DateTime? nextRun;
  final DateTime createdAt;

  const AnalysisJob({
    required this.id,
    required this.name,
    required this.type,
    required this.runAt,
    required this.scopes,
    required this.analysisTypes,
    this.notifyUser = true,
    this.isActive = true,
    this.lastRun,
    this.nextRun,
    required this.createdAt,
  });

  /// Calculate next run time based on job type
  DateTime? calculateNextRun() {
    if (!isActive) return null;

    final now = DateTime.now();

    switch (type) {
      case JobType.oneTime:
        // One-time jobs don't repeat
        return runAt.isAfter(now) ? runAt : null;

      case JobType.daily:
        // Daily jobs run at same time every day
        var next = DateTime(
          now.year,
          now.month,
          now.day,
          runAt.hour,
          runAt.minute,
        );
        if (next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case JobType.weekly:
        // Weekly jobs run same day/time every week
        var next = DateTime(
          now.year,
          now.month,
          now.day,
          runAt.hour,
          runAt.minute,
        );
        // Add days until we reach the same weekday
        while (next.weekday != runAt.weekday || next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;
    }
  }

  AnalysisJob copyWith({
    String? id,
    String? name,
    JobType? type,
    DateTime? runAt,
    List<AnalysisScope>? scopes,
    List<AnalysisType>? analysisTypes,
    bool? notifyUser,
    bool? isActive,
    DateTime? lastRun,
    DateTime? nextRun,
    DateTime? createdAt,
  }) {
    return AnalysisJob(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      runAt: runAt ?? this.runAt,
      scopes: scopes ?? this.scopes,
      analysisTypes: analysisTypes ?? this.analysisTypes,
      notifyUser: notifyUser ?? this.notifyUser,
      isActive: isActive ?? this.isActive,
      lastRun: lastRun ?? this.lastRun,
      nextRun: nextRun ?? this.nextRun,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        runAt,
        scopes,
        analysisTypes,
        notifyUser,
        isActive,
        lastRun,
        nextRun,
        createdAt,
      ];
}

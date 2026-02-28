/// Represents an internship contract.
class InternshipContract {
  /// The unique identifier for the contract.
  final String id;

  /// The ID of the project associated with the internship.
  final String projectId;

  /// The ID of the job posting.
  final String jobId;

  /// The ID of the employer offering the internship.
  final String employerId;

  /// The status of the contract (e.g., 'active', 'completed').
  final String status;

  /// The start date of the internship.
  final DateTime? startDate;

  /// The end date of the internship.
  final DateTime? endDate;

  /// The total payment amount for the internship.
  final double totalPayment;

  /// The terms of service agreed upon.
  final String? termsOfService;

  /// The date and time when the contract was created.
  final DateTime createdAt;

  /// Creates an [InternshipContract] instance.
  InternshipContract({
    required this.id,
    required this.projectId,
    required this.jobId,
    required this.employerId,
    required this.status,
    this.startDate,
    this.endDate,
    required this.totalPayment,
    this.termsOfService,
    required this.createdAt,
  });

  /// Creates an [InternshipContract] from a JSON map.
  factory InternshipContract.fromJson(Map<String, dynamic> json) {
    return InternshipContract(
      id: json['id'],
      projectId: json['project_id'],
      jobId: json['job_id'],
      employerId: json['employer_id'],
      status: json['status'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      totalPayment: (json['total_payment'] as num?)?.toDouble() ?? 0.0,
      termsOfService: json['terms_of_service'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [InternshipContract] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'job_id': jobId,
      'employer_id': employerId,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'total_payment': totalPayment,
      'terms_of_service': termsOfService,
    };
  }
}

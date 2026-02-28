import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../data/internship_model.dart';
import '../../data/internship_repository.dart';
import '../../data/job_model.dart';

/// Screen for creating and viewing internship contracts.
class ContractScreen extends ConsumerStatefulWidget {
  /// The job request associated with this contract.
  final JobRequest job;

  /// The ID of the project associated with this contract.
  final String projectId;

  /// The name of the project associated with this contract.
  final String projectName;

  /// Creates a [ContractScreen].
  const ContractScreen(
      {super.key,
      required this.job,
      required this.projectId,
      required this.projectName});

  @override
  ConsumerState<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends ConsumerState<ContractScreen> {
  bool _isLoading = false;
  bool _signed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Sign Contract'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 40),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                        child: Icon(LucideIcons.fileSignature,
                            size: 64, color: Colors.cyanAccent)),
                    const SizedBox(height: 24),
                    const Text('Internship Agreement',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white24, height: 32),
                    _buildRow('Employer:', widget.job.clientName ?? 'Unknown'),
                    _buildRow('Project Team:', widget.projectName),
                    _buildRow('Role:', widget.job.title),
                    _buildRow('Compensation:',
                        '${widget.job.currency} ${widget.job.budget}'),
                    const SizedBox(height: 24),
                    const Text('Terms & Conditions:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'This agreement serves as a binding contract between the Employer and the Student Team. The Team agrees to deliver the project scope defined in the job description. The Employer agrees to provide mentorship and payment upon successful completion.',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => setState(() => _signed = !_signed),
                      child: Row(
                        children: [
                          Icon(
                              _signed
                                  ? LucideIcons.checkSquare
                                  : LucideIcons.square,
                              color: _signed
                                  ? Colors.greenAccent
                                  : Colors.white54),
                          const SizedBox(width: 12),
                          const Expanded(
                              child: Text(
                                  'I, as the Team Leader, agree to these terms on behalf of my squad.')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_signed && !_isLoading) ? _submitContract : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('SIGN & APPLY'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _submitContract() async {
    setState(() => _isLoading = true);
    try {
      final contract = InternshipContract(
        id: '', // Generated by DB
        projectId: widget.projectId,
        jobId: widget.job.id,
        employerId: widget.job.clientId,
        status: 'Pending',
        totalPayment: widget.job.budget,
        createdAt: DateTime.now(),
        termsOfService:
            'Standard Verasso Internship Agreement v1.0\n\n1. Scope: The "Team" agrees to complete the project "${widget.job.title}".\n2. Payment: ${widget.job.currency} ${widget.job.budget} upon completion.\n3. Mentorship: The Employer agrees to provide weekly guidance.',
      );

      await ref.read(internshipRepositoryProvider).createContract(contract);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application & Contract Sent! 🚀')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

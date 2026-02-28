import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A simulation screen for drafting board resolutions using smart templates.
///
/// Provides pre-built resolution templates for Ordinary Resolutions,
/// Special Resolutions, and Written Resolutions, allowing students
/// to learn the formal structure required for corporate governance.
class ResolutionDrafterScreen extends StatefulWidget {
  /// Creates a [ResolutionDrafterScreen] instance.
  const ResolutionDrafterScreen({super.key});

  @override
  State<ResolutionDrafterScreen> createState() =>
      _ResolutionDrafterScreenState();
}

class _ResolutionDrafterScreenState extends State<ResolutionDrafterScreen> {
  static const _templates = {
    'ordinary': _ResolutionTemplate(
      title: 'Ordinary Resolution',
      description: 'Requires simple majority (>50%). Used for routine matters '
          'like appointment of auditors or declaration of dividends.',
      icon: LucideIcons.fileText,
      color: Colors.blueAccent,
      sections: [
        'RESOLVED THAT pursuant to the provisions of Section ___ of the '
            'Companies Act, 2013, approval of the members be and is hereby '
            'accorded to ___.',
        'RESOLVED FURTHER THAT any Director or the Company Secretary be '
            'and is hereby authorized to do all such acts, deeds, matters '
            'and things as may be necessary to give effect to this resolution.',
      ],
    ),
    'special': _ResolutionTemplate(
      title: 'Special Resolution',
      description: 'Requires 75% majority. Used for significant changes '
          'like altering the Articles of Association or changing company name.',
      icon: LucideIcons.shield,
      color: Colors.amber,
      sections: [
        'RESOLVED THAT pursuant to Section ___ of the Companies Act, 2013 '
            'and Rules made thereunder, and subject to such approvals, '
            'consents, sanctions, and permissions as may be required, the '
            'consent of the members be and is hereby accorded to ___.',
        'RESOLVED FURTHER THAT the Board of Directors be and is hereby '
            'authorized to take all steps, sign all documents, and do all '
            'acts as may be necessary, proper, or expedient to give effect '
            'to this Special Resolution.',
      ],
    ),
    'written': _ResolutionTemplate(
      title: 'Written Resolution (Circulation)',
      description: 'Passed without a meeting via written consent. '
          'Used for matters requiring quick approval where all directors agree.',
      icon: LucideIcons.mail,
      color: Colors.greenAccent,
      sections: [
        'RESOLUTION BY CIRCULATION\n'
            'In accordance with Section 175 of the Companies Act, 2013, '
            'the following resolution is proposed for approval by '
            'circulation among all the Directors.',
        'RESOLVED THAT the consent of the Board be and is hereby accorded '
            'to ___.',
        'This resolution shall be deemed to have been passed on the date '
            'on which the last of the Directors, being not less than the '
            'required majority, has signified their assent.',
      ],
    ),
  };
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cinController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final TextEditingController _customClauseController = TextEditingController();
  String _selectedTemplate = 'ordinary';
  String _generatedDraft = '';

  bool _isDraftGenerated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Resolution Drafter'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_isDraftGenerated)
            IconButton(
              icon: const Icon(LucideIcons.copy),
              tooltip: 'Copy Draft',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _generatedDraft));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Resolution copied to clipboard!'),
                    backgroundColor: Colors.greenAccent,
                  ),
                );
              },
            ),
        ],
      ),
      body: LiquidBackground(
        child: ListView(
          padding:
              const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 40),
          children: [
            // Template Selector
            const Text('Select Template',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            ..._templates.entries.map((entry) {
              final isSelected = _selectedTemplate == entry.key;
              final template = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedTemplate = entry.key;
                    _isDraftGenerated = false;
                  }),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    color: isSelected
                        ? template.color.withValues(alpha: 0.15)
                        : null,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: template.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: template.color, width: 2)
                                : null,
                          ),
                          child: Icon(template.icon,
                              color: template.color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(template.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? template.color
                                          : Colors.white)),
                              const SizedBox(height: 4),
                              Text(template.description,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white54)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(LucideIcons.checkCircle,
                              color: template.color, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Input Fields
            const Text('Company Details',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            _buildTextField(
                _companyNameController, 'Company Name', LucideIcons.building),
            const SizedBox(height: 12),
            _buildTextField(_cinController, 'CIN Number', LucideIcons.hash),
            const SizedBox(height: 12),
            _buildTextField(
                _dateController, 'Date (DD/MM/YYYY)', LucideIcons.calendar),
            const SizedBox(height: 12),
            _buildTextField(_customClauseController, 'Resolution Subject',
                LucideIcons.edit3,
                maxLines: 3),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _generateDraft,
                icon: const Icon(LucideIcons.sparkles),
                label: const Text('GENERATE DRAFT',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            // Generated Draft
            if (_isDraftGenerated) ...[
              const SizedBox(height: 24),
              const Text('Generated Draft',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _generatedDraft,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _cinController.dispose();
    _dateController.dispose();
    _customClauseController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.indigoAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _generateDraft() {
    final template = _templates[_selectedTemplate]!;
    final companyName = _companyNameController.text.isEmpty
        ? '[Company Name]'
        : _companyNameController.text;
    final cin =
        _cinController.text.isEmpty ? '[CIN Number]' : _cinController.text;
    final date = _dateController.text.isEmpty ? '[Date]' : _dateController.text;
    final customClause = _customClauseController.text.isEmpty
        ? '[describe the matter here]'
        : _customClauseController.text;

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln(template.title.toUpperCase());
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Company: $companyName');
    buffer.writeln('CIN: $cin');
    buffer.writeln('Date: $date');
    buffer.writeln();
    buffer.writeln('─────────────────────────────────────');
    buffer.writeln();

    for (final section in template.sections) {
      final filledSection = section.replaceAll('___', customClause);
      buffer.writeln(filledSection);
      buffer.writeln();
    }

    buffer.writeln('─────────────────────────────────────');
    buffer.writeln('Signature: ________________________');
    buffer.writeln('Name of Director / Company Secretary');
    buffer.writeln('Date: $date');

    setState(() {
      _generatedDraft = buffer.toString();
      _isDraftGenerated = true;
    });
  }
}

class _ResolutionTemplate {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> sections;

  const _ResolutionTemplate({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.sections,
  });
}

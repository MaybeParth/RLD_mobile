import 'package:flutter/material.dart';
import '../models/trial.dart';

class TrialDecisionDialog extends StatefulWidget {
  final Trial trial;
  final VoidCallback onKeep;
  final VoidCallback onDiscard;
  final Function(String)? onKeepWithNotes;

  const TrialDecisionDialog({
    super.key,
    required this.trial,
    required this.onKeep,
    required this.onDiscard,
    this.onKeepWithNotes,
  });

  @override
  State<TrialDecisionDialog> createState() => _TrialDecisionDialogState();
}

class _TrialDecisionDialogState extends State<TrialDecisionDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _showNotesField = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.science, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Trial Completed'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trial results summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trial ${widget.trial.id} Results',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Show actual drop measurement prominently
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_down,
                                color: Colors.red.shade700, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Leg Dropped: ${widget.trial.dropAngle?.toStringAsFixed(1) ?? 'N/A'}°',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This is how many degrees your leg dropped from the starting position',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Additional measurements
                  _buildResultRow(
                      'Peak Drop Angle',
                      '${widget.trial.peakDropAngle?.toStringAsFixed(1) ?? 'N/A'}°',
                      Colors.orange),
                  _buildResultRow(
                      'Drop Time',
                      '${widget.trial.dropTimeMs?.toStringAsFixed(0) ?? 'N/A'} ms',
                      Colors.blue),
                  if (widget.trial.motorVelocity != null)
                    _buildResultRow(
                        'Motor Velocity',
                        '${widget.trial.motorVelocity!.toStringAsFixed(1)} °/s',
                        Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    'Completed at ${widget.trial.formattedTimestamp}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Instructions for patient
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Next Steps:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Return your leg to the fully extended position (180°)\n'
                    '2. Hold it steady for the next trial\n'
                    '3. The system will measure your drop angle again',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Decision question
            const Text(
              'What would you like to do with this trial?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 16),

            // Notes field (optional)
            if (_showNotesField) ...[
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any notes about this trial...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      actions: [
        // Discard button
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDiscard();
          },
          icon: const Icon(Icons.delete, color: Colors.red),
          label: const Text('Discard', style: TextStyle(color: Colors.red)),
        ),

        // Keep button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            if (_showNotesField && _notesController.text.isNotEmpty) {
              widget.onKeepWithNotes?.call(_notesController.text);
            } else {
              widget.onKeep();
            }
          },
          icon: const Icon(Icons.check, color: Colors.white),
          label: const Text('Keep', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),

        // Add notes button
        if (!_showNotesField)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showNotesField = true;
              });
            },
            icon: const Icon(Icons.note_add),
            label: const Text('Add Notes'),
          ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

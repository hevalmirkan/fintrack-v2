import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/analysis_job.dart';
import '../../domain/entities/job_enums.dart';
import '../providers/analysis_providers.dart';

/// Screen for creating a new analysis job
class AddAnalysisJobScreen extends ConsumerStatefulWidget {
  const AddAnalysisJobScreen({super.key});

  @override
  ConsumerState<AddAnalysisJobScreen> createState() =>
      _AddAnalysisJobScreenState();
}

class _AddAnalysisJobScreenState extends ConsumerState<AddAnalysisJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  JobType _selectedType = JobType.daily;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final Set<AnalysisScope> _selectedScopes = {AnalysisScope.portfolio};
  final Set<AnalysisType> _selectedAnalysisTypes = {AnalysisType.risk};
  bool _notifyUser = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedScopes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir kapsam seçmelisiniz')),
      );
      return;
    }
    if (_selectedAnalysisTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir analiz tipi seçmelisiniz')),
      );
      return;
    }

    final now = DateTime.now();
    final runAt = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final job = AnalysisJob(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _selectedType,
      runAt: runAt,
      scopes: _selectedScopes.toList(),
      analysisTypes: _selectedAnalysisTypes.toList(),
      notifyUser: _notifyUser,
      isActive: true,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(analysisJobActionsProvider).createJob(job);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analiz görevi oluşturuldu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Analiz Görevi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Job Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Görev Adı',
                hintText: 'Örn: Haftalık Portföy Kontrolü',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Görev adı gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Job Type
            Text(
              'Çalışma Sıklığı',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<JobType>(
              segments: JobType.values.map((type) {
                return ButtonSegment(
                  value: type,
                  label: Text(type.label),
                );
              }).toList(),
              selected: {_selectedType},
              onSelectionChanged: (Set<JobType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Time Picker
            Text(
              'Çalışma Saati',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // Analysis Scopes
            Text(
              'Analiz Kapsamı',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...AnalysisScope.values.map((scope) {
              return CheckboxListTile(
                title: Text(scope.label),
                value: _selectedScopes.contains(scope),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedScopes.add(scope);
                    } else {
                      _selectedScopes.remove(scope);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),

            // Analysis Types
            Text(
              'Analiz Türleri',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...AnalysisType.values.map((type) {
              return CheckboxListTile(
                title: Row(
                  children: [
                    Text(type.label),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showAnalysisTypeInfo(context, type),
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                value: _selectedAnalysisTypes.contains(type),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedAnalysisTypes.add(type);
                    } else {
                      _selectedAnalysisTypes.remove(type);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),

            // Notification Toggle
            SwitchListTile(
              title: const Text('Bildirim Gönder'),
              subtitle: const Text('Analiz tamamlandığında bildirim al'),
              value: _notifyUser,
              onChanged: (value) {
                setState(() => _notifyUser = value);
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _saveJob,
              icon: const Icon(Icons.save),
              label: const Text('Görevi Kaydet'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalysisTypeInfo(BuildContext context, AnalysisType type) {
    String explanation;
    switch (type) {
      case AnalysisType.risk:
        explanation =
            'Portföyünüzdeki varlıkların ani değer kaybı ihtimalini ölçer.';
        break;
      case AnalysisType.trend:
        explanation =
            'Varlıklarınızın fiyatlarının genel olarak yükseliş mi yoksa düşüş mü eğiliminde olduğunu belirler.';
        break;
      case AnalysisType.volatility:
        explanation =
            'Fiyatlardaki dalgalanma şiddetini ölçer. Yüksek dalgalanma, yüksek risk/getiri demektir.';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(type.label)),
          ],
        ),
        content: Text(
          explanation,
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}

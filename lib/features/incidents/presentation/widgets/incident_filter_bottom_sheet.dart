import 'package:flutter/material.dart';

import '../../domain/entities/incident_event.dart';
import '../models/incident_filter_criteria.dart';

class IncidentFilterBottomSheet extends StatefulWidget {
  final IncidentFilterCriteria initialCriteria;

  const IncidentFilterBottomSheet({
    super.key,
    required this.initialCriteria,
  });

  static Future<IncidentFilterCriteria?> show(
    BuildContext context,
    IncidentFilterCriteria criteria,
  ) {
    return showModalBottomSheet<IncidentFilterCriteria>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => IncidentFilterBottomSheet(initialCriteria: criteria),
    );
  }

  @override
  State<IncidentFilterBottomSheet> createState() =>
      _IncidentFilterBottomSheetState();
}

class _IncidentFilterBottomSheetState extends State<IncidentFilterBottomSheet> {
  late IncidentFilterCriteria _criteria;

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtros', style: theme.textTheme.titleLarge),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _criteria = const IncidentFilterCriteria();
                      });
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Orden', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: IncidentSortOption.values.map((opt) {
                  return ChoiceChip(
                    label: Text(opt.displayName),
                    selected: _criteria.sortBy == opt,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _criteria = _criteria.copyWith(sortBy: opt);
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Prioridad', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IncidentPriority.values.map((p) {
                  return FilterChip(
                    label: Text(p.displayName),
                    selected: _criteria.priority == p,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _criteria = _criteria.copyWith(
                              priority: p, clearPriority: false);
                        } else {
                          _criteria = _criteria.copyWith(clearPriority: true);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Estado', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                // Omitimos estados de rechazo/falso porque por defecto
                // el mapa del barrio no debería mostrarlos o si los muestra,
                // son de interés muy específico.
                children: [
                  IncidentStatus.recibido,
                  IncidentStatus.programado,
                  IncidentStatus.enReparacion,
                  IncidentStatus.solucionado,
                ].map((s) {
                  return FilterChip(
                    label: Text(s.displayName),
                    selected: _criteria.status == s,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _criteria =
                              _criteria.copyWith(status: s, clearStatus: false);
                        } else {
                          _criteria = _criteria.copyWith(clearStatus: true);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Solo incidentes avalados'),
                subtitle:
                    const Text('Filtrar reportes confirmados por referentes'),
                value: _criteria.onlyVerified,
                onChanged: (val) {
                  setState(() {
                    _criteria = _criteria.copyWith(onlyVerified: val);
                  });
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_criteria),
                child: const Text('Aplicar filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

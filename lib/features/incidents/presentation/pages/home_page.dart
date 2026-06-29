import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/referent_verification_aggregate.dart';
import '../models/incident_filter_criteria.dart';
import '../providers/incidents_provider.dart';
import '../widgets/incident_filter_bottom_sheet.dart';
import '../widgets/incident_status_badge.dart';
import '../widgets/quick_report_button.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  IncidentFilterCriteria _criteria = const IncidentFilterCriteria();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    // Mapa del barrio (SRS §3.1.1): muestra incidents públicos activos, no los
    // marcados falsos/rechazados/solucionados. [D-02]
    final incidentsAsync = ref.watch(activeIncidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          if (user?.role.canVerify == true)
            IconButton(
              icon: const Icon(Icons.notifications_active),
              tooltip: AppStrings.referentAlertsTitle,
              onPressed: () => context.push(AppRoutes.alerts),
            ),
          if (user?.role == UserRole.administrador)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: AppStrings.adminDashboard,
              onPressed: () => context.push(AppRoutes.admin),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Botón de reporte rápido (RF-REP-01)
          const Padding(
            padding: EdgeInsets.all(16),
            child: QuickReportButton(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Incidentes recientes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ActionChip(
                  avatar: const Icon(Icons.filter_list, size: 16),
                  label: Text('Filtros (${_criteria.activeFiltersCount})'),
                  onPressed: () async {
                    final newCriteria = await IncidentFilterBottomSheet.show(
                      context,
                      _criteria,
                    );
                    if (newCriteria != null) {
                      setState(() {
                        _criteria = newCriteria;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // Lista de incidentes en tiempo real
          Expanded(
            child: incidentsAsync.when(
              loading: () =>
                  const AppLoading(message: 'Cargando incidentes...'),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (incidents) {
                final filtered = incidents.where((i) {
                  if (_criteria.priority != null &&
                      i.priority != _criteria.priority) {
                    return false;
                  }
                  if (_criteria.status != null &&
                      i.status != _criteria.status) {
                    return false;
                  }
                  if (_criteria.onlyVerified) {
                    final agg = aggregateReferentVerification(
                        i.referentVerificationHistory);
                    if (agg.state != ReferentAggregateState.confirmed) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                filtered.sort((a, b) {
                  if (_criteria.sortBy == IncidentSortOption.newest) {
                    return b.timestamp.compareTo(a.timestamp);
                  } else {
                    return a.timestamp.compareTo(b.timestamp);
                  }
                });

                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No hay incidentes reportados.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final incident = filtered[i];
                    final referentAggregate = aggregateReferentVerification(
                      incident.referentVerificationHistory,
                    );

                    return ListTile(
                      leading: const Icon(Icons.report_problem),
                      title: Text(
                        incident.description ??
                            incident.category?.displayName ??
                            'Reporte rápido',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${incident.timestamp.day}/${incident.timestamp.month}/${incident.timestamp.year}',
                              ),
                              const SizedBox(width: 8),
                              IncidentStatusBadge(status: incident.status),
                              if (incident.priority != null) ...[
                                const SizedBox(width: 8),
                                IncidentPriorityBadge(
                                    priority: incident.priority!),
                              ],
                              if (referentAggregate.state !=
                                  ReferentAggregateState.none) ...[
                                const SizedBox(width: 8),
                                ReferentVerificationBadge(
                                  aggregate: referentAggregate,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        AppRoutes.incidentDetailPath(incident.eventId!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

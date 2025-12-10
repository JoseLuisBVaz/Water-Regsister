import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_consumption_provider.dart';
import '../models/daily_record.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedPeriod = 7; // 7 días por defecto
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    final provider = context.read<WaterConsumptionProvider>();
    final stats = await provider.getStatistics(days: _selectedPeriod);
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  void _changePeriod(int days) {
    setState(() => _selectedPeriod = days);
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de período
            _PeriodSelector(
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: _changePeriod,
            ),

            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_stats.isEmpty || _stats['daysWithData'] == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Sin datos para este período',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Card de total
              _StatCard(
                icon: Icons.water_drop,
                title: 'Consumo total',
                value: '${(_stats['totalLiters'] ?? 0.0).toStringAsFixed(1)} L',
                subtitle: 'Últimos ${_stats['daysWithData']} días',
                color: Colors.blue,
              ),

              const SizedBox(height: 12),

              // Card de promedio
              _StatCard(
                icon: Icons.show_chart,
                title: 'Promedio diario',
                value: '${(_stats['averagePerDay'] ?? 0.0).toStringAsFixed(1)} L',
                subtitle: 'Por día registrado',
                color: Colors.green,
              ),

              const SizedBox(height: 12),

              // Cards de máximo y mínimo
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.arrow_upward,
                      title: 'Día máximo',
                      value: _stats['maxDay'] != null
                          ? '${(_stats['maxDay'] as DailyRecord).totalLiters.toStringAsFixed(1)} L'
                          : '-',
                      subtitle: _stats['maxDay'] != null
                          ? '${(_stats['maxDay'] as DailyRecord).date.day}/${(_stats['maxDay'] as DailyRecord).date.month}'
                          : '',
                      color: Colors.orange,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.arrow_downward,
                      title: 'Día mínimo',
                      value: _stats['minDay'] != null
                          ? '${(_stats['minDay'] as DailyRecord).totalLiters.toStringAsFixed(1)} L'
                          : '-',
                      subtitle: _stats['minDay'] != null
                          ? '${(_stats['minDay'] as DailyRecord).date.day}/${(_stats['minDay'] as DailyRecord).date.month}'
                          : '',
                      color: Colors.teal,
                      isCompact: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Consejos ecológicos
              const _EcoTipsCard(),
            ],
          ],
        ),
      ),
    );
  }
}

// ========== SELECTOR DE PERÍODO ==========

class _PeriodSelector extends StatelessWidget {
  final int selectedPeriod;
  final Function(int) onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _PeriodButton(
                label: '7 días',
                isSelected: selectedPeriod == 7,
                onTap: () => onPeriodChanged(7),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodButton(
                label: '30 días',
                isSelected: selectedPeriod == 30,
                onTap: () => onPeriodChanged(30),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodButton(
                label: '90 días',
                isSelected: selectedPeriod == 90,
                onTap: () => onPeriodChanged(90),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ========== CARD DE ESTADÍSTICA ==========

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final bool isCompact;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: isCompact ? 20 : 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 20 : 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========== CONSEJOS ECOLÓGICOS ==========

class _EcoTipsCard extends StatefulWidget {
  const _EcoTipsCard();

  @override
  State<_EcoTipsCard> createState() => _EcoTipsCardState();
}

class _EcoTipsCardState extends State<_EcoTipsCard> {
  final List<Map<String, String>> _allTips = const [
    {
      'icon': '🚿',
      'title': 'Duchas más cortas',
      'tip': 'Reduce tu ducha a 5 minutos y ahorra hasta 50 litros por día',
    },
    {
      'icon': '🚰',
      'title': 'Cierra el grifo',
      'tip': 'Al cepillarte los dientes o lavar platos, cierra el grifo cuando no uses agua',
    },
    {
      'icon': '🌱',
      'title': 'Riega con inteligencia',
      'tip': 'Riega las plantas en la mañana o noche para evitar evaporación',
    },
    {
      'icon': '🔧',
      'title': 'Repara fugas',
      'tip': 'Un grifo goteando puede desperdiciar 30 litros por día',
    },
    {
      'icon': '🚽',
      'title': 'Inodoro eficiente',
      'tip': 'Coloca una botella con arena en el tanque para reducir el agua por descarga',
    },
    {
      'icon': '🧽',
      'title': 'Lava platos inteligente',
      'tip': 'Llena el lavabo para lavar en vez de dejar el agua corriendo',
    },
    {
      'icon': '🌧️',
      'title': 'Aprovecha el agua lluvia',
      'tip': 'Recoge agua de lluvia para regar plantas y limpiar exteriores',
    },
    {
      'icon': '🚗',
      'title': 'Lava tu auto con cubeta',
      'tip': 'Usa una cubeta en lugar de manguera y ahorra hasta 300 litros',
    },
    {
      'icon': '🍽️',
      'title': 'Lavavajillas eficiente',
      'tip': 'Usa el lavavajillas solo cuando esté completamente lleno',
    },
    {
      'icon': '👕',
      'title': 'Lavadora llena',
      'tip': 'Espera a tener una carga completa antes de usar la lavadora',
    },
    {
      'icon': '❗',
      'title': 'LaLiLuLeLo',
      'tip': 'Nuestras memorias no son "solo" sonidos e imágenes. Estos existen, en algún lugar entre los sonidos, en algún lugar entre las imágenes.',
    },
  ];

  List<Map<String, String>> _selectedTips = [];

  @override
  void initState() {
    super.initState();
    _shuffleTips();
  }

  void _shuffleTips() {
    final random = Random();
    final shuffled = List<Map<String, String>>.from(_allTips)..shuffle(random);
    setState(() {
      _selectedTips = shuffled.take(4).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Consejos para ahorrar agua',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green[700]),
                  onPressed: _shuffleTips,
                  tooltip: 'Ver otros consejos',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._selectedTips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip['icon']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip['title']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              tip['tip']!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

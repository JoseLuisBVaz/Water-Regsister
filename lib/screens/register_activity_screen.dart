import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/water_consumption_provider.dart';
import '../models/activity_type.dart';

class RegisterActivityScreen extends StatefulWidget {
  const RegisterActivityScreen({super.key});

  @override
  State<RegisterActivityScreen> createState() => _RegisterActivityScreenState();
}

class _RegisterActivityScreenState extends State<RegisterActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  
  ActivityType? _selectedActivityType;
  double _calculatedLiters = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Asegurar que los datos estén cargados
    Future.microtask(() {
      final provider = context.read<WaterConsumptionProvider>();
      if (provider.activityTypes.isEmpty) {
        provider.initialize();
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateLiters() {
    if (_selectedActivityType != null && _quantityController.text.isNotEmpty) {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      setState(() {
        _calculatedLiters = quantity * _selectedActivityType!.litersPerUnit;
      });
    } else {
      setState(() {
        _calculatedLiters = 0.0;
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedActivityType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una actividad')),
      );
      return;
    }

    // Confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar registro'),
        content: Text(
          '¿Deseas registrar ${_quantityController.text} ${_selectedActivityType!.unit} de ${_selectedActivityType!.name}?\n\n'
          'Consumo: ${_calculatedLiters.toStringAsFixed(1)} litros',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final provider = context.read<WaterConsumptionProvider>();
    final quantity = double.parse(_quantityController.text);
    
    final success = await provider.addActivity(
      activityType: _selectedActivityType!,
      quantity: quantity,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Actividad registrada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Animación al regresar
      Navigator.pop(context);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WaterConsumptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Actividad'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading || provider.activityTypes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando actividades...'),
                ],
              ),
            )
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${provider.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.initialize(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dropdown de actividades
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: DropdownButtonFormField<ActivityType>(
                          decoration: const InputDecoration(
                            labelText: 'Tipo de actividad',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.water_drop),
                          ),
                          value: _selectedActivityType,
                          items: provider.activityTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(type.icon, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Text('${type.name} (${type.litersPerUnit} L/${type.unit})',
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedActivityType = value);
                            _calculateLiters();
                          },
                          validator: (value) {
                            if (value == null) return 'Selecciona una actividad';
                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Campo de cantidad
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: _selectedActivityType != null
                                ? 'Cantidad (${_selectedActivityType!.unit})'
                                : 'Cantidad',
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.numbers),
                            hintText: 'Ejemplo: 1, 2, 5, 10',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          onChanged: (_) => _calculateLiters(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa una cantidad';
                            }
                            final quantity = double.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Ingresa un número válido mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Card de cálculo
                    if (_calculatedLiters > 0)
                      Hero(
                        tag: 'liters_calculation',
                        child: Card(
                          elevation: 4,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text(
                                  'Consumo estimado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _calculatedLiters.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        'litros',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Botón guardar
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveActivity,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Guardando...' : 'Guardar actividad'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'dart:async'; 
import 'package:crud_pet_feeder/models/pet.dart';
import 'package:crud_pet_feeder/models/feeding_suggestion.dart'; 
import 'package:crud_pet_feeder/models/schedule.dart'; 
import 'package:crud_pet_feeder/models/dispense_command.dart'; 
import 'package:crud_pet_feeder/services/feeding_calculator_service.dart'; 
import 'package:crud_pet_feeder/services/pet_service.dart';
import 'package:crud_pet_feeder/services/schedule_service.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';

class AddPetPage extends StatefulWidget {
  final Pet? petToEdit; 

  const AddPetPage({super.key, this.petToEdit});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para el formulario
  late final TextEditingController _nombreController;
  late final TextEditingController _pesoController;
  late DateTime _fechaNacimiento;

  TipoActividad _actividadSeleccionada = TipoActividad.moderada;
  TipoAlimento _tipoAlimentoSeleccionado = TipoAlimento.seco;

  bool _isEditMode = false;
  bool _isLoading = false;

  final FeedingCalculatorService _calculator = FeedingCalculatorService();
  FeedingSuggestion? _suggestion; 
  
  // --- 1. NUEVA SOLUCIÓN: FocusNode ---
  // Para detectar cuándo el usuario SALE del campo de texto
  final FocusNode _pesoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.petToEdit != null;

    if (_isEditMode) {
      final pet = widget.petToEdit!;
      _nombreController = TextEditingController(text: pet.nombre);
      _pesoController = TextEditingController(text: pet.peso.toString());
      _fechaNacimiento = pet.fechaNacimiento;
      _actividadSeleccionada = pet.actividad;
      _tipoAlimentoSeleccionado = pet.tipoAlimento;
    } else {
      _nombreController = TextEditingController();
      _pesoController = TextEditingController();
      _fechaNacimiento = DateTime.now();
    }
    
    _pesoFocusNode.addListener(_onPesoFocusChange);
    
    _updateSuggestion(); 
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _pesoController.dispose();
    
    _pesoFocusNode.removeListener(_onPesoFocusChange);
    _pesoFocusNode.dispose();
    
    super.dispose();
  }

  // Esta función AHORA solo llama a setState
  void _updateSuggestion() {
    final tempPet = Pet(
      id: '', 
      nombre: _nombreController.text,
      peso: double.tryParse(_pesoController.text) ?? 0.0,
      fechaNacimiento: _fechaNacimiento,
      actividad: _actividadSeleccionada,
      tipoAlimento: _tipoAlimentoSeleccionado,
    );

    FeedingSuggestion? newSuggestion;
    if (tempPet.peso > 0) {
      newSuggestion = _calculator.calculate(tempPet);
    } else {
      newSuggestion = null;
    }
    
    if (mounted) {
      setState(() {
        _suggestion = newSuggestion;
      });
    }
  }

  // --- 4. NUEVA FUNCIÓN LISTENER ---
  // Se llama cuando el usuario TOCA DENTRO o TOCA FUERA del campo "Peso"
  void _onPesoFocusChange() {
    // Si el nodo PIERDE el foco (es decir, el usuario tocó en otro lado)
    if (!_pesoFocusNode.hasFocus) {
      _updateSuggestion();
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento,
      firstDate: DateTime(2000), 
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaNacimiento) {
      _fechaNacimiento = picked;
      _updateSuggestion(); 
    }
  }

  Future<void> _submitForm() async {
    // Validamos ANTES de actualizar la sugerencia
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Nos aseguramos de que la sugerencia esté actualizada
    // con el último valor del peso antes de guardar.
    _updateSuggestion();
    
    // Capturamos la sugerencia actual ANTES de guardar
    final currentSuggestion = _suggestion;
    
    setState(() => _isLoading = true);
    final petService = Provider.of<PetService>(context, listen: false);

    try {
      final petData = Pet(
        id: _isEditMode ? widget.petToEdit!.id : '', 
        nombre: _nombreController.text,
        peso: double.tryParse(_pesoController.text) ?? 0.0,
        fechaNacimiento: _fechaNacimiento,
        actividad: _actividadSeleccionada,
        tipoAlimento: _tipoAlimentoSeleccionado,
      );

      if (_isEditMode) {
        await petService.updatePet(petData);
      } else {
        await petService.addPet(petData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mascota ${(_isEditMode ? "actualizada" : "guardada")} con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (currentSuggestion != null && currentSuggestion.totalGramsPerDay > 0 && mounted) {
          _showCreateSchedulesDialog(context, currentSuggestion);
        } else {
          Navigator.of(context).pop();
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateSchedulesDialog(BuildContext context, FeedingSuggestion suggestion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Crear Horarios?'),
          content: Text(
            '¡Mascota guardada! La sugerencia es ${suggestion.mealsPerDay} comidas de ${suggestion.gramsPerMeal}g c/u. '
            '¿Quieres crear ${suggestion.mealsPerDay} horarios predeterminados ahora?'
          ),
          actions: [
            TextButton(
              child: const Text('No, gracias'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                Navigator.of(context).pop(); 
              },
            ),
            ElevatedButton(
              child: const Text('Sí, crear'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _createSuggestedSchedules(context, suggestion);
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/horarios');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createSuggestedSchedules(BuildContext context, FeedingSuggestion suggestion) async {
    setState(() => _isLoading = true);
    final scheduleService = Provider.of<ScheduleService>(context, listen: false);

    final List<TimeOfDay> mealTimes = [
      const TimeOfDay(hour: 8, minute: 0),  // 8:00 AM
      const TimeOfDay(hour: 19, minute: 0), // 7:00 PM
      const TimeOfDay(hour: 14, minute: 0), // 2:00 PM (solo si son 3 comidas)
    ];

    final Map<String, bool> allDays = {
      'Lun': true, 'Mar': true, 'Mié': true, 'Jue': true, 
      'Vie': true, 'Sáb': true, 'Dom': true,
    };
    
    TipoCroqueta croquetaPorDefecto;
    if (_tipoAlimentoSeleccionado == TipoAlimento.secoHumedecido) { 
      croquetaPorDefecto = TipoCroqueta.tipoA; 
    } else {
      croquetaPorDefecto = TipoCroqueta.values.firstWhere(
        (e) => e.displayName == _tipoAlimentoSeleccionado.displayName, 
        orElse: () => TipoCroqueta.tipoA
      );
    }

    try {
      for (int i = 0; i < suggestion.mealsPerDay; i++) {
        final newSchedule = Schedule(
          id: '',
          timeOfDay: mealTimes[i],
          daysOfWeek: allDays,
          gramos: suggestion.gramsPerMeal.toDouble(),
          tipoCroqueta: croquetaPorDefecto,
          ratioAgua: RatioAgua.seco,
          isEnabled: true,
        );
        await scheduleService.addSchedule(newSchedule);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear horarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Mascota' : 'Añadir Mascota'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Mascota',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese un nombre.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _pesoController,
                      focusNode: _pesoFocusNode, // <--- ASIGNAMOS EL NODO
                      decoration: const InputDecoration(
                        labelText: 'Peso (Kg)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese un peso.';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Por favor, ingrese un número positivo.';
                        }
                        return null;
                      },
                      // --- 6. 'onChanged' ELIMINADO ---
                      // onChanged: _onPesoChanged, 
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nacimiento: ${DateFormat.yMMMd().format(_fechaNacimiento)}', 
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TipoActividad>(
                      value: _actividadSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Nivel de Actividad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.hiking), 
                      ),
                      items: TipoActividad.values.map((TipoActividad actividad) {
                        return DropdownMenuItem<TipoActividad>(
                          value: actividad,
                          child: Text(actividad.displayName),
                        );
                      }).toList(),
                      onChanged: (TipoActividad? newValue) {
                        if (newValue != null) {
                          _actividadSeleccionada = newValue;
                          _updateSuggestion(); 
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TipoAlimento>(
                      value: _tipoAlimentoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Alimento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.restaurant_menu),
                      ),
                      items: TipoAlimento.values.map((TipoAlimento tipo) {
                        return DropdownMenuItem<TipoAlimento>(
                          value: tipo,
                          child: Text(tipo.displayName),
                        );
                      }).toList(),
                      onChanged: (TipoAlimento? newValue) {
                        if (newValue != null) {
                          _tipoAlimentoSeleccionado = newValue;
                          _updateSuggestion();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSuggestionCard(context),

                    const SizedBox(height: 24),
                    
                    ElevatedButton.icon(
                      onPressed: _submitForm, 
                      icon: const Icon(Icons.save),
                      label: Text(_isEditMode ? 'Actualizar' : 'Guardar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context) {
    if (_suggestion == null) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _suggestion == null
          ? const SizedBox.shrink()
          : Card(
              key: const ValueKey('suggestion_card'), 
              elevation: 4,
              color: Colors.green[50], 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.green[800]),
                        const SizedBox(width: 8),
                        Text(
                          'Sugerencia de Alimentación',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_suggestion!.totalGramsPerDay > 0)
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 16),
                          children: [
                            const TextSpan(text: 'Recomendado: '),
                            TextSpan(
                              text: '${_suggestion!.totalGramsPerDay}g diarios',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ' en '),
                            TextSpan(
                              text: '${_suggestion!.mealsPerDay} comidas',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' (aprox. ${_suggestion!.gramsPerMeal}g c/u).'),
                          ],
                        ),
                      ),
                      
                    const SizedBox(height: 8),
                    Text(
                      _suggestion!.message,
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
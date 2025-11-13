import 'package:crud_pet_feeder/models/dispense_command.dart';
import 'package:crud_pet_feeder/models/schedule.dart';
import 'package:crud_pet_feeder/models/feeding_suggestion.dart'; 
import 'package:crud_pet_feeder/services/schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddSchedulePage extends StatefulWidget {
  final Schedule? scheduleToEdit;
  final FeedingSuggestion? suggestion; 

  const AddSchedulePage({
    super.key, 
    this.scheduleToEdit,
    this.suggestion, 
  });

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y variables
  late TimeOfDay _selectedTime;
  late Map<String, bool> _selectedDays;
  late final TextEditingController _gramosController;
  late TipoCroqueta _selectedCroqueta;
  late RatioAgua _selectedRatio;

  bool _isEditMode = false;
  bool _isLoading = false;

  final List<String> _daysOfWeek = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    
    _isEditMode = widget.scheduleToEdit != null;

    if (_isEditMode) {
      // --- MODO EDITAR ---
      final schedule = widget.scheduleToEdit!;
      _selectedTime = schedule.timeOfDay; 
      _selectedDays = Map<String, bool>.from(schedule.daysOfWeek);
      _gramosController = TextEditingController(text: schedule.gramos.toString());
      _selectedCroqueta = schedule.tipoCroqueta;
      _selectedRatio = schedule.ratioAgua;
    
    // --- 3. NUEVA LÓGICA: MODO SUGERENCIA ---
    } else if (widget.suggestion != null) {
      // Si recibimos una sugerencia, pre-llenamos el formulario
      final suggestion = widget.suggestion!;
      _selectedTime = TimeOfDay.now();
      _selectedDays = { for (var day in _daysOfWeek) day : true }; // Todos los días por defecto
      _gramosController = TextEditingController(text: suggestion.gramsPerMeal.toString()); 
      _selectedCroqueta = TipoCroqueta.tipoA; // Por defecto
      _selectedRatio = RatioAgua.seco;       // Por defecto
      
      // Lógica para pre-seleccionar el ratio si la sugerencia es de cachorro
      if (suggestion.mealsPerDay == 3) { // Asumimos que 3 comidas = cachorro
         _selectedRatio = RatioAgua.seco; 
      }
      
    } else {
      // --- MODO CREAR (Vacío) ---
      _selectedTime = TimeOfDay.now();
      _selectedDays = { for (var day in _daysOfWeek) day : false };
      _gramosController = TextEditingController();
      _selectedCroqueta = TipoCroqueta.tipoA;
      _selectedRatio = RatioAgua.seco;
    }
  }

  @override
  void dispose() {
    _gramosController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_selectedDays.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione al menos un día de la semana.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final scheduleService = Provider.of<ScheduleService>(context, listen: false);

    try {
      final scheduleData = Schedule(
        id: _isEditMode ? widget.scheduleToEdit!.id : '',
        timeOfDay: _selectedTime, 
        daysOfWeek: _selectedDays,
        gramos: double.tryParse(_gramosController.text) ?? 50.0,
        tipoCroqueta: _selectedCroqueta,
        ratioAgua: _selectedRatio,
        isEnabled: _isEditMode ? widget.scheduleToEdit!.isEnabled : true, 
      );

      if (_isEditMode) {
        await scheduleService.updateSchedule(scheduleData);
      } else {
        await scheduleService.addSchedule(scheduleData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Horario ${(_isEditMode ? "actualizado" : "guardado")} con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el horario: $e'),
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // El título cambia según el modo
        title: Text(_isEditMode ? 'Editar Horario' : (_isLoading ? 'Nuevo Horario' : 'Nuevo Horario (Sugerido)')),
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
                    Text('1. Seleccione la hora', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.edit_calendar),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text('2. Seleccione los días', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: _daysOfWeek.map((day) {
                        return ChoiceChip(
                          label: Text(day),
                          selected: _selectedDays[day]!,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedDays[day] = selected;
                            });
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: _selectedDays[day]! ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    Text('3. Defina la comida', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _gramosController,
                      decoration: const InputDecoration(
                        labelText: 'Gramos de Alimento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese los gramos.';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Ingrese un número positivo.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TipoCroqueta>(
                      value: _selectedCroqueta,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Croqueta',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      items: TipoCroqueta.values.map((TipoCroqueta tipo) {
                        return DropdownMenuItem<TipoCroqueta>(
                          value: tipo,
                          child: Text(tipo.displayName),
                        );
                      }).toList(),
                      onChanged: (TipoCroqueta? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCroqueta = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RatioAgua>(
                      value: _selectedRatio,
                      decoration: const InputDecoration(
                        labelText: 'Humedad (Agua)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.water_drop_outlined),
                      ),
                      items: RatioAgua.values.map((RatioAgua ratio) {
                        return DropdownMenuItem<RatioAgua>(
                          value: ratio,
                          child: Text(ratio.displayName),
                        );
                      }).toList(),
                      onChanged: (RatioAgua? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRatio = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save),
                      label: Text(_isEditMode ? 'Actualizar Horario' : 'Guardar Horario'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
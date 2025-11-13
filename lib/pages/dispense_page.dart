import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud_pet_feeder/models/dispense_command.dart';
import 'package:crud_pet_feeder/services/auth_services.dart';
import 'package:crud_pet_feeder/services/device_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DispensePage extends StatefulWidget {
  const DispensePage({super.key});

  @override
  State<DispensePage> createState() => _DispensePageState();
}

class _DispensePageState extends State<DispensePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _gramosController = TextEditingController();
  TipoCroqueta _selectedCroqueta = TipoCroqueta.tipoA;
  RatioAgua _selectedRatio = RatioAgua.seco;
  bool _isLoading = false;

  @override
  void dispose() {
    _gramosController.dispose();
    super.dispose();
  }

  // --- 2. FUNCIÓN DE GUARDAR MODIFICADA ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Obtenemos los servicios
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false); // <-- Obtenemos Auth
    
    // Verificamos si el usuario está logueado
    final userId = authService.user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no identificado. Intente iniciar sesión de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final command = DispenseCommand(
        gramos: double.tryParse(_gramosController.text) ?? 50.0,
        tipoCroqueta: _selectedCroqueta,
        ratioAgua: _selectedRatio,
        timestamp: Timestamp.now(),
        userId: userId,           // <-- ¡Añadido!
        source: 'Manual',       // <-- ¡Añadido!
      );
      
      await deviceService.dispenseNow(command);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Comando enviado al dispositivo!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar comando: $e'),
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

  
  // --- Diálogo de Información de Croquetas ---
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tipos de Croqueta (Referencia)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccione el tipo de croqueta que más se parezca al que usted suele darle a su mascota:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/croqueta_reference.png',
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text(
                          'Imagen de referencia no encontrada.\n(Añada a assets/croqueta_reference.png)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Las croquetas mostradas arriba son de referencia y para aclarar use:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                const Text('Tipo A: Cachorro'),
                const Text('Tipo B: Adulto'),
                const Text('Tipo C: Geriátrico'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Entendido'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispensado Manual'),
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
                    Text('Paso 1: Ingrese los gramos', style: Theme.of(context).textTheme.titleLarge),
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
                          return 'Por favor, ingrese los gramos.';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Por favor, ingrese un número positivo.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Paso 2: Seleccione tipo de croqueta',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'Ver referencia de croquetas',
                          onPressed: () => _showInfoDialog(context),
                        ),
                      ],
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
                    const SizedBox(height: 24),
                    Text('Paso 3: Seleccione la humedad', style: Theme.of(context).textTheme.titleLarge),
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
                      icon: const Icon(Icons.send),
                      label: const Text('Confirmar y Dispensar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
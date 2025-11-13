import 'package:crud_pet_feeder/models/pet.dart';
import 'package:crud_pet_feeder/models/schedule.dart';
import 'package:crud_pet_feeder/models/feeding_suggestion.dart';
import 'package:crud_pet_feeder/pages/add_pet_page.dart';
import 'package:crud_pet_feeder/pages/add_schedule_page.dart';
import 'package:crud_pet_feeder/pages/ajustes_page.dart';
import 'package:crud_pet_feeder/pages/auth_wrapper.dart';
import 'package:crud_pet_feeder/pages/dispense_page.dart';
import 'package:crud_pet_feeder/pages/history_page.dart';
import 'package:crud_pet_feeder/pages/horarios_page.dart';
import 'package:crud_pet_feeder/pages/inicio_page.dart';
import 'package:crud_pet_feeder/pages/loading_page.dart';
import 'package:crud_pet_feeder/pages/login_page.dart';
import 'package:crud_pet_feeder/pages/perros_page.dart';
import 'package:crud_pet_feeder/pages/register_page.dart';
import 'package:crud_pet_feeder/services/auth_services.dart';
import 'package:crud_pet_feeder/services/device_service.dart';
import 'package:crud_pet_feeder/services/history_service.dart';
import 'package:crud_pet_feeder/services/notification_service.dart'; // <-- 1. Importar
import 'package:crud_pet_feeder/services/pet_service.dart';
import 'package:crud_pet_feeder/services/schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- 2. INICIALIZAMOS SERVICIOS ---
  await Firebase.initializeApp();
  await initializeDateFormatting('es_ES', null);
  Intl.defaultLocale = 'es_ES';

  // 3. Creamos e inicializamos el servicio de notificaciones
  final notificationService = NotificationService();
  await notificationService.init(); // Lo inicializamos aquí

  // 4. Corremos la App, pasando el servicio
  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  // 5. Aceptamos el servicio
  final NotificationService notificationService;
  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- 6. PROVEEMOS LOS SERVICIOS ---
        
        // Servicios que no dependen de nada
        ChangeNotifierProvider(create: (_) => AuthService()),
        
        // Proveemos la instancia de NotificationService que ya creamos
        Provider.value(value: notificationService), 

        // Servicios que dependen de AuthService
        ChangeNotifierProxyProvider<AuthService, PetService>(
          create: (_) => PetService(null),
          update: (_, authService, __) => PetService(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, ScheduleService>(
          create: (_) => ScheduleService(null),
          update: (_, authService, __) => ScheduleService(authService),
        ),
        
        // --- 7. ACTUALIZAMOS PROXY PROVIDERS ---
        
        // DeviceService ahora depende de NotificationService
        ChangeNotifierProxyProvider<NotificationService, DeviceService>(
          create: (_) => DeviceService(null), // Se crea vacío
          update: (_, notificationService, __) => DeviceService(notificationService),
        ),
        
        // HistoryService ahora depende de Auth Y Notificaciones
        ChangeNotifierProxyProvider2<AuthService, NotificationService, HistoryService>(
          create: (_) => HistoryService(null, null), // Se crea vacío
          update: (_, authService, notificationService, __) => HistoryService(authService, notificationService),
        ),
      ],
      child: MaterialApp(
        title: 'Pet Feeder+',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/inicio': (context) => const InicioPage(),
          '/loading': (context) => const LoadingPage(),
          
          '/perros': (context) => const PerrosPage(),
          '/add_pet': (context) => const AddPetPage(),
          '/edit_pet': (context) {
            final petToEdit = ModalRoute.of(context)!.settings.arguments as Pet;
            return AddPetPage(petToEdit: petToEdit);
          },

          '/dispensar': (context) => const DispensePage(),
          
          '/horarios': (context) => const HorariosPage(),
          '/add_schedule': (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            if (arguments is FeedingSuggestion) {
              return AddSchedulePage(suggestion: arguments);
            }
            return const AddSchedulePage();
          },
          '/edit_schedule': (context) {
            final scheduleToEdit = ModalRoute.of(context)!.settings.arguments as Schedule;
            return AddSchedulePage(scheduleToEdit: scheduleToEdit);
          },

          '/historial': (context) => const HistoryPage(),
          '/ajustes': (context) => const AjustesPage(),
        },
      ),
    );
  }
}
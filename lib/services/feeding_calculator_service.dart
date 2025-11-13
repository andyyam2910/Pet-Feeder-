import 'package:crud_pet_feeder/models/pet.dart';
import 'package:crud_pet_feeder/models/feeding_suggestion.dart';

/*
 * Servicio de "Cerebro" 
 * Contiene la lógica de las tablas para calcular la alimentación.
 */
class FeedingCalculatorService {

  // Función principal que recibe el perfil de la mascota
  FeedingSuggestion? calculate(Pet pet) {
    
    // 1. Calcular la edad de la mascota
    final int ageInMonths = _calculateAgeInMonths(pet.fechaNacimiento);

    if (ageInMonths < 12) {
      // --- LÓGICA DE CACHORROS (Menos de 12 meses) ---
      // la lógica de gramos para cachorros es compleja
      // porque depende del "peso final" que no tenemos.
      
      return FeedingSuggestion(
        totalGramsPerDay: 0, // No podemos calcular gramos
        mealsPerDay: 3,
        message: "Para cachorros (${ageInMonths}m), se recomiendan 3 comidas al día. "
                   "La cantidad de gramos depende de la raza y su peso final estimado. "
                   "Consulta a tu veterinario o la bolsa de alimento."
      );

    } else {
      // --- LÓGICA DE ADULTOS (12+ meses) ---
      
      int grams;
      int meals;
      
      if (pet.peso <= 5) {
        const int baja = 35;
        const int alta = 100;
        switch (pet.actividad) {
          case TipoActividad.baja:
            grams = baja;
            break;
          case TipoActividad.alta:
            grams = alta;
            break;
          case TipoActividad.moderada:
            grams = ((baja + alta) / 2).round(); // Promedio: 68g
            break;
        }
      } else if (pet.peso <= 10) {
        const int baja = 100;
        const int alta = 180;
         switch (pet.actividad) {
          case TipoActividad.baja:
            grams = baja;
            break;
          case TipoActividad.alta:
            grams = alta;
            break;
          case TipoActividad.moderada:
            grams = ((baja + alta) / 2).round(); // Promedio: 140g
            break;
        }
      } else if (pet.peso <= 20) {
        const int baja = 180;
        const int alta = 320;
         switch (pet.actividad) {
          case TipoActividad.baja:
            grams = baja;
            break;
          case TipoActividad.alta:
            grams = alta;
            break;
          case TipoActividad.moderada:
            grams = ((baja + alta) / 2).round(); // Promedio: 250g
            break;
        }
      } else if (pet.peso <= 30) {
        const int baja = 320;
        const int alta = 440;
         switch (pet.actividad) {
          case TipoActividad.baja:
            grams = baja;
            break;
          case TipoActividad.alta:
            grams = alta;
            break;
          case TipoActividad.moderada:
            grams = ((baja + alta) / 2).round(); // Promedio: 380g
            break;
        }
      } else if (pet.peso <= 40) {
        const int baja = 440;
        const int alta = 550;
         switch (pet.actividad) {
          case TipoActividad.baja:
            grams = baja;
            break;
          case TipoActividad.alta:
            grams = alta;
            break;
          case TipoActividad.moderada:
            grams = ((baja + alta) / 2).round(); // Promedio: 495g
            break;
        }
      } else {
        // + 40 kg
        const int baja = 550;
        // Asumimos 600g para 'alta' basado en la progresión
        const int alta = 600; 
         switch (pet.actividad) {
          case TipoActividad.baja:
            grams = baja;
            break;
          case TipoActividad.alta:
            grams = alta;
            break;
          case TipoActividad.moderada:
            grams = ((baja + alta) / 2).round(); // Promedio: 575g
            break;
        }
      }

      // 2. Calcular Frecuencia (Comidas por día)
      // Esta es la opción más recomendada para la mayoría
      meals = 2; 
      String message = "Se recomiendan 2 comidas diarias para una buena digestión y energía.";
      
      return FeedingSuggestion(
        totalGramsPerDay: grams,
        mealsPerDay: meals,
        message: "Basado en un peso de ${pet.peso}kg y actividad ${pet.actividad.displayName.toLowerCase()}, "
                 "$message"
      );
    }
  }

  // --- Función Auxiliar ---
  // Calcula la diferencia de meses entre hoy y la fecha de nacimiento
  int _calculateAgeInMonths(DateTime birthDate) {
    final now = DateTime.now();
    
    // Cálculo básico de meses
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    
    // Ajuste si el cumpleaños de este año aún no ha pasado
    if (now.day < birthDate.day) {
      months--;
    }
    
    return (years * 12) + months;
  }
}
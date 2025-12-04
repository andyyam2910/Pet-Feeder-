/*
 * CÓDIGO MAESTRO V19: PRODUCTO FINAL
 * Características:
 * 1. WiFiManager: Configuración de WiFi sin reprogramar.
 * 2. Firebase: Comandos, Horarios, Historial, Estado.
 * 3. Hardware: RTC DS1307 + Sensores + Lógica de precisión V2.1.
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <Wire.h>       
#include "RTClib.h"     
#include <WiFiManager.h>

// =======================================================================
// =================== 1. CONFIGURACIÓN FIREBASE =========================
// =======================================================================

#define FIREBASE_PROJECT_ID "pet-feeder-plus"
#define FIREBASE_CLIENT_EMAIL "firebase-adminsdk-fbsvc@pet-feeder-plus.iam.gserviceaccount.com"
#define FIREBASE_PRIVATE_KEY "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCpnyrAWPQSsP/J\nrFjBWCM5Ln+51GcrWkhvCRr8HBOMsuqX3qwfG/fU276Pytw+Y2zw+Nm9HtPHjCtN\nHxWTpRu0G6T6Kms+zsuYtUcbYOVxeyHmrBxbKHvaT+W3rLsosY3NwKZyk9gw1f0U\nJjs5CbmV6HE/FmS9PIcRu2uWOaXOAKQCldYHaxtMe8+mhmO3W5tUPkTTKsxSTyeM\nltbPQJfD1mBt2Cm50kZiBDmRnRHB30GOfUl1pngUonKBSafVgbWaZuypt4HTofyE\nVuGUewyQCkzjLa5CobYIJybynzv226Qdv3QBu5mi704vgYUQLjfnQyGogZfdiRbd\ndBJCim2tAgMBAAECggEAAPT8rwKhd+SHQOpHwul+I2Gzh0cfQOOcwoGc5Ry8cIAG\n6k3vjypfetQ1jkag+PojIHXq9pHwtHDCQshg3Qkir6CzTNUF72AHzogBS3J/wOTm\ns1A3xbzj+/6U53UiRi/AQs+qML3MS7Q9Xgp8LY10PlgGIYq9DUNE6NDzobCYEqI0\ncLJ2vvMIR2xFvh3rSo29h2h/Qxzi1btd9Y1dSgFUTRKYAzwi6vlq4LG6pAVgBygK\nqxRyXzIlPAGj3ZHo2elXqVhlTqBzwF0ueITGapKLF51bigfR6IO4WiVcpxdweVSO\n0fTnMZIdBYzhxzQASpwRSjEloQi0yyRLPjArtIceWQKBgQDSqkmz//7WdIRCfU5P\nTNtRxzwE8JXygAwRFISC9r8TqvnSBI/djYS/s73sEjhGg0ItBo/PwlTOqU70YWWe\ndGBpoBpF72AodfznqDobN9EKyFBzitNu72UxD7P5Hjso5cjKsu+HZARHxmeeHm4t\nu+2KgDA/3htPW1KvE5tyPFOkKQKBgQDOH8Nua/f3rS2dKXQIUY3neqSpvXAE1suy\nTk5Tlv73nbG+ecu9eGc+8bSs3sFc9uf59sxy2efzviZnpomQr8B9LarhN3qSF++f\n4rFUv1px1UMAtsi4mkmX7hbjbuWAGYhyPt2q3Cl+wGISq0dFmOTWEnn+kkJmYqZN\nJR/WwZ6N5QKBgD4+mnBY3082Ni3/IDhGGTdcittayrNQKkCRs2WOyn5hMldfibKI\nsgSCc0dhSsdq2Q68tZlJbg1x8SY78O6UrDgJWjn3tI2/7u3zwtdv8pAhB8Rb7IUG\nrvuEDEU7LXe0DVP28tcqMimS8eLCUwOoV1No9NiqI5+a+B9Kx89FC+GhAoGARTWL\nFCdyghoGx89kY2qmwAOBCHFQDH/msz7xs8VuZMvxI2iXzU2BNTRJGwZMXJ+Wsmp4\nqVObO08sa/8SD5/DfQR5bNeI80bQMZoXOsJpZvFZZwL4kGtVrIrH6qOQsZthIiMT\noMv9rs5/347dBnRY2bwodB695szW0+5UK3KlfzUCgYBUt34m0P8ww1EJkGcuay3A\nXfWKSyAQYO9/JpOVRCGcXoFByUWjqLekmCY8b90SbcOL/NRUYM7AD4AmQUgNkycD\ns12TP+uNMQV3tKzYYf5xq0lNDyu8MOQEn7iwcu3tQksoJVefnE1t6PxzDaRkJmiI\n1Kumz7jOFLp2Gi0ijaDjQg==\n-----END PRIVATE KEY-----\n"

#define USER_UID "7gFcbhML6aaXmdthfXkMPfrqCVR2" 

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool firebaseReady = false;

RTC_DS1307 rtc;

// =======================================================================
// =================== 2. HARDWARE PINES =================================
// =======================================================================

// Sensor de distancia para agua
const int AGUA_TRIG = 13;
const int AGUA_ECHO = 12;
// Bomba de agua
const int BOMBA_ENA = 14; 
const int BOMBA_IN1 = 27;
const int BOMBA_IN2 = 26;
// Sensor de distancia para comida
const int COMIDA_TRIG = 33;
const int COMIDA_ECHO = 32;
// Etapa de molienda
const int RELAY_PIN = 15; 
//Apertura y cierre del cajon
const int CAJON_IN1 = 5; 
const int CAJON_IN2 = 18; 
const int CAJON_ENA = 19; 
const int FC_ABIERTO_PIN = 16; 
const int FC_CERRADO_PIN = 17; 

// =======================================================================
// =================== 3.1 PARÁMETROS AGUA ===============================
// =======================================================================
const float Q_MICRO = 14.03;
const float Q_PEQUENO_AGUA = 15.2;
const float Q_MEDIO_AGUA = 17.78;
const float Q_GRANDE_AGUA = 18.42;
const int LIMITE_MICRO_AGUA = 15;
const int LIMITE_PEQUENO_AGUA = 40;
const int LIMITE_MEDIO_AGUA = 100;

// Ratios para humedad
const float RATIO_SECO = 0.0;
const float RATIO_HUMEDO = 2.0;
const float RATIO_CALDOSO = 3.0;
const float RATIO_SOPA = 4.0;

// =======================================================================
// =================== 3.1 PARÁMETROS ALIMENTO ===========================
// =======================================================================

const int LIM_PEQ_CROQ = 25; 
const int LIM_MED_CROQ = 50;   
const float QA_P=4.26, QA_M=4.26, QA_G=4.20;
const float QB_P=3.56, QB_M=2.89, QB_G=3.04;
const float QC_P=4.34, QC_M=4.36, QC_G=4.16;

const float TOLVA_H = 16.5; 
const float TOLVA_W_TOP = 20.0;
const float TOLVA_L_TOP = 20.5;
const float TOLVA_W_BOT = 15.0;
const float TOLVA_L_BOT = 6.5;
const float SENSOR_DEADZONE = 3.0; //Variable

const int puntosAgua = 7;
float volAgua[puntosAgua] = {0, 500, 1000, 1500, 2000, 2500, 3000}; 
float distAgua[puntosAgua] = {16.01, 13.44, 11.23, 9.60, 7.26, 4.35, 2.62}; 
float distanciaAguaFiltrada = 0;

// =======================================================================
// =================== 4. MÁQUINA DE ESTADOS =============================
// =======================================================================

enum EstadoDispensador { 
  INACTIVO, 
  ETAPA_MOLIENDA, 
  ETAPA_AGUA, 
  ETAPA_ESPERA_MEZCLA, 
  ETAPA_ABRIR_CAJON,
  ETAPA_ESPERA_COMER,  
  ETAPA_CERRAR_CAJON,
  ETAPA_FINALIZANDO 
};

EstadoDispensador estadoActual = INACTIVO;
String comandoId = "";
float gramosDeseados = 0.0;
int croquetaElegida = 0;
int ratioElegido = 0;

unsigned long tiempoInicioEtapa = 0;
unsigned long duracionMolienda = 0;
unsigned long duracionAgua = 0;
unsigned long ultimaVerificacion = 0;
const unsigned long INTERVALO_VERIFICACION = 2000UL; 

int ultimoMinutoRevisado = -1;

// =======================================================================
// =================== DECLARACIONES =====================================
// =======================================================================
void reportarNivelesFirebase(); 
float obtenerDistancia(int trig, int echo);
float calcularPorcentajeComida();
float calcularPorcentajeAgua();

unsigned long calcularTiempoCroquetas(int croqueta, float gramos);
void moverCajon(bool abrir);
void verificarComandosFirebase();
void verificarHorariosFirebase(); 
bool procesarComando(float gramos, int croqueta, int ratio, String id);
void eliminarComandoEjecutado();
void actualizarNivelesEnBD(int nivAgua, int nivComida);
void registrarHistorial();

// =======================================================================
// =================== SETUP =============================================
// =======================================================================
void setup() {
  Serial.begin(115200);
  Wire.begin(); 

  // PINES
  pinMode(RELAY_PIN, OUTPUT); digitalWrite(RELAY_PIN, LOW);
  pinMode(BOMBA_ENA, OUTPUT); pinMode(BOMBA_IN1, OUTPUT); pinMode(BOMBA_IN2, OUTPUT);
  digitalWrite(BOMBA_IN1, HIGH); digitalWrite(BOMBA_IN2, LOW); digitalWrite(BOMBA_ENA, LOW);
  pinMode(AGUA_TRIG, OUTPUT); pinMode(AGUA_ECHO, INPUT);
  pinMode(COMIDA_TRIG, OUTPUT); pinMode(COMIDA_ECHO, INPUT);
  pinMode(CAJON_IN1, OUTPUT); pinMode(CAJON_IN2, OUTPUT); pinMode(CAJON_ENA, OUTPUT);
  pinMode(FC_ABIERTO_PIN, INPUT_PULLUP); pinMode(FC_CERRADO_PIN, INPUT_PULLUP);
  digitalWrite(CAJON_ENA, LOW);
  
  pinMode(LED_WIFI, OUTPUT); 
  digitalWrite(LED_WIFI, LOW); // Apagado

  // RTC
  Serial.println("Iniciando RTC...");
  if (!rtc.begin()) Serial.println("Error RTC");
  if (!rtc.isrunning()) rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));

  // SENSORES
  Serial.println("Preparando sensores...");
  delay(1000); 
  for(int i=0; i<5; i++) {
    obtenerDistancia(AGUA_TRIG, AGUA_ECHO);
    obtenerDistancia(COMIDA_TRIG, COMIDA_ECHO);
    delay(50);
  }

  // --- WIFI MANAGER START ---
  Serial.println("Iniciando WiFiManager...");
  WiFiManager wm;
  // Crea un portal "PET_FEEDER_SETUP" sin contraseña (se puede agregar una a requerimiento)
  bool res = wm.autoConnect("PET_FEEDER_SETUP");

  if(!res) {
      Serial.println("Fallo al conectar o timeout");
      ESP.restart(); // Reiniciar si falla
  } 
  else {
      Serial.println("WiFi CONECTADO!");
      digitalWrite(LED_WIFI, HIGH); // LED ENCENDIDO = CONECTADO
  }
  // --- WIFI MANAGER END ---

  // FIREBASE
  config.service_account.data.client_email = FIREBASE_CLIENT_EMAIL;
  config.service_account.data.project_id = FIREBASE_PROJECT_ID; 
  config.service_account.data.private_key = FIREBASE_PRIVATE_KEY;
  config.token_status_callback = tokenStatusCallback;
  fbdo.setResponseSize(4096);
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("SISTEMA V19 (FINAL) LISTO");
  reportarNivelesFirebase(); 
}

// =======================================================================
// =================== LOOP ==============================================
// =======================================================================
void loop() {
  if (Firebase.ready() && !firebaseReady) {
    firebaseReady = true;
    Serial.println("Firebase Sincronizado");
  }

  unsigned long ahora = millis();

  if (estadoActual != INACTIVO) {
    runDispensingLogic(ahora);
  } 
  else if (firebaseReady) {
    if (ahora - ultimaVerificacion >= INTERVALO_VERIFICACION) {
      verificarComandosFirebase();
      ultimaVerificacion = ahora;
    }

    DateTime now = rtc.now();
    if (now.minute() != ultimoMinutoRevisado && now.second() < 5) {
       Serial.printf("RTC %02d:%02d - Revisando Horarios...\n", now.hour(), now.minute());
       verificarHorariosFirebase();
       ultimoMinutoRevisado = now.minute();
    }
  }
}

// =======================================================================
// =================== LÓGICA DE DISPENSADO ==============================
// =======================================================================

void runDispensingLogic(unsigned long ahora) {
  unsigned long tiempoTranscurrido = ahora - tiempoInicioEtapa;

  switch (estadoActual) {
    case ETAPA_MOLIENDA:
      if (tiempoTranscurrido % 1000 < 20) Serial.print("."); 
      if (tiempoTranscurrido >= duracionMolienda) {
        digitalWrite(RELAY_PIN, LOW);
        Serial.println("\n Molienda Fin.");
        float ratio_mult = 0.0;
        if (ratioElegido == 1) ratio_mult = RATIO_HUMEDO;
        else if (ratioElegido == 2) ratio_mult = RATIO_CALDOSO;
        else if (ratioElegido == 3) ratio_mult = RATIO_SOPA;
        else ratio_mult = RATIO_SECO;
        
        int ml = (int)(gramosDeseados * ratio_mult);
        if (ml > 0) {
           float caudal;
           if (ml <= LIMITE_MICRO_AGUA) caudal = Q_MICRO;
           else if (ml <= LIMITE_PEQUENO_AGUA) caudal = Q_PEQUENO_AGUA;
           else if (ml <= LIMITE_MEDIO_AGUA) caudal = Q_MEDIO_AGUA;
           else caudal = Q_GRANDE_AGUA;
           duracionAgua = (unsigned long)((ml / caudal) * 1000);
           Serial.printf(" Agua: %d ml (%lu ms)\n", ml, duracionAgua);
           digitalWrite(BOMBA_ENA, HIGH); 
           estadoActual = ETAPA_AGUA;
        } else {
           Serial.println(" Sin agua.");
           estadoActual = ETAPA_ESPERA_MEZCLA;
        }
        tiempoInicioEtapa = millis();
      }
      break;

    case ETAPA_AGUA:
      if (tiempoTranscurrido >= duracionAgua) {
        digitalWrite(BOMBA_ENA, LOW); 
        Serial.println("Agua Fin. Esperando 1 min...");
        estadoActual = ETAPA_ESPERA_MEZCLA;
        tiempoInicioEtapa = millis();
      }
      break;

    case ETAPA_ESPERA_MEZCLA:
      if (tiempoTranscurrido >= 60000UL) { 
        Serial.println("Reposo Fin. Abriendo...");
        estadoActual = ETAPA_ABRIR_CAJON;
        tiempoInicioEtapa = millis();
      }
      break;

    case ETAPA_ABRIR_CAJON:
      moverCajon(true); 
      Serial.println("Abierto. Comiendo (1 min)...");
      estadoActual = ETAPA_ESPERA_COMER;
      tiempoInicioEtapa = millis();
      break;

    case ETAPA_ESPERA_COMER:
      if (tiempoTranscurrido >= 60000UL) { 
        Serial.println("Fin Comida. Cerrando...");
        estadoActual = ETAPA_CERRAR_CAJON;
        tiempoInicioEtapa = millis();
      }
      break;

    case ETAPA_CERRAR_CAJON:
      moverCajon(false);
      Serial.println("Cerrado.");
      estadoActual = ETAPA_FINALIZANDO;
      tiempoInicioEtapa = millis();
      break;

    case ETAPA_FINALIZANDO:
      registrarHistorial();
      if (comandoId != "") eliminarComandoEjecutado(); 
      Serial.println("CICLO COMPLETADO.");
      reportarNivelesFirebase(); 
      estadoActual = INACTIVO;
      break;
  }
}

// =======================================================================
// =================== FUNCIONES FIREBASE ================================
// =======================================================================

void registrarHistorial() {
  Serial.println("Guardando Historial...");
  fbdo.clear();
  
  String ruta = "users/" + String(USER_UID) + "/history";
  FirebaseJson json;
  
  json.set("fields/gramos/doubleValue", gramosDeseados);
  json.set("fields/tipoCroqueta/integerValue", croquetaElegida);
  json.set("fields/ratioAgua/integerValue", ratioElegido);
  
  String fuente = (comandoId != "") ? "Manual" : "Programado";
  json.set("fields/source/stringValue", fuente);
  
  DateTime now = rtc.now();
  char timeStr[30];
  
  sprintf(timeStr, "%04d-%02d-%02dT%02d:%02d:%02d-04:00", 
          now.year(), now.month(), now.day(), 
          now.hour(), now.minute(), now.second());
  // -----------------------

  json.set("fields/timestamp/timestampValue", timeStr);
  
  if(Firebase.Firestore.createDocument(&fbdo, FIREBASE_PROJECT_ID, "", ruta.c_str(), json.raw())) {
     Serial.println(" Historial OK.");
  }
}

void verificarComandosFirebase() {
  String ruta = "devices/petfeeder_001/commands";
  fbdo.clear(); 
  
  if (Firebase.Firestore.listDocuments(&fbdo, FIREBASE_PROJECT_ID, "", ruta, 1, "", "", "", true)) {
    FirebaseJson json; json.setJsonData(fbdo.payload());
    FirebaseJsonData jsonData;
    if (json.get(jsonData, "documents")) {
      FirebaseJsonArray arr; jsonData.getArray(arr);
      if (arr.size() > 0) {
        Serial.println(" ¡Comando Manual!");
        FirebaseJsonData doc; arr.get(doc, 0);
        FirebaseJson cmd; cmd.setJsonData(doc.stringValue);
        
        FirebaseJsonData nameData; cmd.get(nameData, "name");
        String fullPath = nameData.stringValue;
        comandoId = fullPath.substring(fullPath.lastIndexOf('/') + 1);

        FirebaseJsonData field;
        float gr = 0; int croq = 0; int rat = 0;
        
        if (cmd.get(field, "fields/gramos/doubleValue")) gr = field.doubleValue;
        else if (cmd.get(field, "fields/gramos/integerValue")) gr = field.intValue;
        
        if (cmd.get(field, "fields/tipoCroqueta/integerValue")) croq = field.intValue;
        if (cmd.get(field, "fields/ratioAgua/integerValue")) rat = field.intValue;

        procesarComando(gr, croq, rat, comandoId);
      }
    }
  }
}

String obtenerDiaSemana(int diaNum) {
  switch(diaNum) {
    case 0: return "Dom"; case 1: return "Lun"; case 2: return "Mar";
    case 3: return "Mié"; case 4: return "Jue"; case 5: return "Vie"; case 6: return "Sáb"; 
  }
  return "";
}

bool diaEstaActivo(FirebaseJson *json, String diaClave) {
  FirebaseJsonData res;
  String path = "fields/daysOfWeek/mapValue/fields/" + diaClave + "/booleanValue";
  json->get(res, path);
  return res.boolValue;
}

void verificarHorariosFirebase() {
  String ruta = "users/" + String(USER_UID) + "/schedules";
  fbdo.clear();
  
  if (Firebase.Firestore.listDocuments(&fbdo, FIREBASE_PROJECT_ID, "", ruta, 20, "", "", "", true)) {
    FirebaseJson json; json.setJsonData(fbdo.payload());
    FirebaseJsonData jsonData;
    
    if (json.get(jsonData, "documents")) {
      FirebaseJsonArray arr; jsonData.getArray(arr);
      
      DateTime now = rtc.now();
      char timeBuffer[6];
      sprintf(timeBuffer, "%02d:%02d", now.hour(), now.minute());
      String horaActual = String(timeBuffer);
      String diaActual = obtenerDiaSemana(now.dayOfTheWeek());
      
      Serial.printf(" Check: %s %s\n", diaActual.c_str(), horaActual.c_str());

      for (size_t i = 0; i < arr.size(); i++) {
        FirebaseJsonData doc; arr.get(doc, i);
        FirebaseJson sch; sch.setJsonData(doc.stringValue);
        
        FirebaseJsonData field;
        bool isEnabled = false;
        if(sch.get(field, "fields/isEnabled/booleanValue")) isEnabled = field.boolValue;
        if (!isEnabled) continue; 

        String schTime = "";
        if(sch.get(field, "fields/timeString/stringValue")) schTime = field.stringValue;
        if (schTime != horaActual) continue; 

        if (!diaEstaActivo(&sch, diaActual)) continue;

        Serial.println(" ¡HORARIO ACTIVADO!");
        
        float gr = 0; int croq = 0; int rat = 0;
        
        if (sch.get(field, "fields/gramos/doubleValue")) gr = field.doubleValue;
        else if (sch.get(field, "fields/gramos/integerValue")) gr = field.intValue;
        
        if (sch.get(field, "fields/tipoCroqueta/integerValue")) croq = field.intValue;
        if (sch.get(field, "fields/ratioAgua/integerValue")) rat = field.intValue;

        procesarComando(gr, croq, rat, ""); 
        return; 
      }
    }
  }
}

void actualizarNivelesEnBD(int nivAgua, int nivComida) {
  fbdo.clear(); 
  String documentPath = "devices/petfeeder_001"; 
  FirebaseJson content;
  content.set("fields/nivelAgua/integerValue", nivAgua);
  content.set("fields/nivelAlimento/integerValue", nivComida);
  String mask = "nivelAgua,nivelAlimento";
  
  if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str(), content.raw(), mask.c_str())) {
      Serial.printf(" Niveles OK: Ag:%d%% Al:%d%%\n", nivAgua, nivComida);
  }
}

void eliminarComandoEjecutado() {
  fbdo.clear(); 
  String ruta = "devices/petfeeder_001/commands/" + comandoId;
  Firebase.Firestore.deleteDocument(&fbdo, FIREBASE_PROJECT_ID, "", ruta.c_str());
  comandoId = ""; 
}

bool procesarComando(float gramos, int croqueta, int ratio, String id) {
  Serial.printf("\n START: %.1fg (ID: %s)\n", gramos, id.c_str());
  
  if (gramos <= 0) {
    if (id != "") eliminarComandoEjecutado();
    return false;
  }
  
  gramosDeseados = gramos;
  croquetaElegida = croqueta;
  ratioElegido = ratio;
  comandoId = id; 
  
  estadoActual = ETAPA_MOLIENDA;
  duracionMolienda = calcularTiempoCroquetas(croquetaElegida, gramosDeseados);
  digitalWrite(RELAY_PIN, HIGH); 
  tiempoInicioEtapa = millis();
  
  return true;
}

// =======================================================================
// =================== SENSORES & CALCULOS ===============================
// =======================================================================

void reportarNivelesFirebase() {
  int pctComida = (int)calcularPorcentajeComida();
  int pctAgua = (int)calcularPorcentajeAgua();
  actualizarNivelesEnBD(pctAgua, pctComida);
}

float obtenerDistancia(int trig, int echo) {
  digitalWrite(trig, LOW); delayMicroseconds(2);
  digitalWrite(trig, HIGH); delayMicroseconds(10);
  digitalWrite(trig, LOW);
  long duracion = pulseIn(echo, HIGH); 
  if (duracion == 0) return 0;
  return (duracion * 0.0343) / 2.0;
}

float calcularPorcentajeComida() {
  float d = obtenerDistancia(COMIDA_TRIG, COMIDA_ECHO);
  if (d == 0) d = TOLVA_H; 
  if (d < SENSOR_DEADZONE) d = 0; if (d > TOLVA_H) d = TOLVA_H;
  
  float h_fill = TOLVA_H - d; 
  if (h_fill <= 0) return 0.0;
  
  float w_c = TOLVA_W_BOT + ((TOLVA_W_TOP - TOLVA_W_BOT) * (h_fill / TOLVA_H));
  float l_c = TOLVA_L_BOT + ((TOLVA_L_TOP - TOLVA_L_BOT) * (h_fill / TOLVA_H));
  float a_b = TOLVA_W_BOT * TOLVA_L_BOT;
  float a_t = w_c * l_c;
  float v_act = (h_fill / 3.0) * (a_b + a_t + sqrt(a_b * a_t));
  float a_top_tot = TOLVA_W_TOP * TOLVA_L_TOP;
  float v_tot = (TOLVA_H / 3.0) * (a_b + a_top_tot + sqrt(a_b * a_top_tot));
  return (v_act / v_tot) * 100.0;
}

float calcularPorcentajeAgua() {
  float d = obtenerDistancia(AGUA_TRIG, AGUA_ECHO);
  if (d == 0 || d > 50) d = (distanciaAguaFiltrada > 0) ? distanciaAguaFiltrada : 16.01;
  distanciaAguaFiltrada = (distanciaAguaFiltrada == 0) ? d : (0.4 * d + 0.6 * distanciaAguaFiltrada);
  float lectura = distanciaAguaFiltrada;
  float volumen = 0;
  if (lectura < distAgua[6]) volumen = 3000;
  else if (lectura > distAgua[0]) volumen = 0;
  else {
    for (int i = 0; i < 6; i++) {
      if (lectura <= distAgua[i] && lectura >= distAgua[i+1]) {
        float frac = (distAgua[i] - lectura) / (distAgua[i] - distAgua[i+1]);
        volumen = volAgua[i] + frac * (volAgua[i+1] - volAgua[i]);
        break;
      }
    }
  }
  return (volumen / 3000.0) * 100.0;
}

unsigned long calcularTiempoCroquetas(int croqueta, float gramos) {
  float caudal = QA_G; 
  if (gramos <= LIM_PEQ_CROQ) {
      if (croqueta==1) caudal=QA_P; else if (croqueta==2) caudal=QB_P; else caudal=QC_P;
  } else if (gramos <= LIM_MED_CROQ) {
      if (croqueta==1) caudal=QA_M; else if (croqueta==2) caudal=QB_M; else caudal=QC_M;
  } else {
      if (croqueta==1) caudal=QA_G; else if (croqueta==2) caudal=QB_G; else caudal=QC_G;
  }
  return (unsigned long)((gramos / caudal) * 1000);
}

void moverCajon(bool abrir) {
  int pinLimite = abrir ? FC_ABIERTO_PIN : FC_CERRADO_PIN;
  if (digitalRead(pinLimite) == LOW) return;

  if (abrir) { digitalWrite(CAJON_IN1, HIGH); digitalWrite(CAJON_IN2, LOW); }
  else { digitalWrite(CAJON_IN1, LOW); digitalWrite(CAJON_IN2, HIGH); }
  digitalWrite(CAJON_ENA, HIGH);

  unsigned long inicio = millis();
  while (digitalRead(pinLimite) == HIGH) {
    if (millis() - inicio > 12000) { Serial.println(" Timeout Motor"); break; } // Por seguridad
    delay(10);
  }
  digitalWrite(CAJON_ENA, LOW);
  digitalWrite(CAJON_IN1, LOW); digitalWrite(CAJON_IN2, LOW);
}
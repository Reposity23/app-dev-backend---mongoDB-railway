/**
 * @file smart_toy_rfid.ino
 * @brief RFID ID Card reader for a smart toy store system.
 * @details This code reads an employee's RFID card, sends their name to a backend server,
 * and controls LEDs based on the server's response about their next assigned task.
 * 
 * @author Gemini AI & JohnT
 * @date 04 November 2025
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <SPI.h>
#include <MFRC522.h>

// --- Hardware & Network Configuration ---
#define SS_PIN 21         // SPI Slave Select Pin
#define RST_PIN 22        // RFID Reset Pin

// --- WiFi Credentials ---
const char* ssid = "YOUR_REAL_WIFI_NAME";
const char* password = "YOUR_REAL_WIFI_PASSWORD";

// --- Server Configuration ---
const char* serverName = "my-backend-prod.up.railway.app";

// --- LED Pin Mapping ---
const int LED_TOY_GUNS = 25;
const int LED_ACTION_FIGURES = 27;
const int LED_DOLLS = 26;
const int LED_PUZZLES = 33;

// --- RFID Hardware Initialization ---
MFRC522 rfid(SS_PIN, RST_PIN);

// --- Map Physical Card UIDs to Person Names ---
struct PersonMapping {
    const char* physicalUid;    // UID from the physical ID card
    const char* personName;     // Name of the employee
};

PersonMapping personMappings[] = {
    {"A9 6C 6A 05", "John Marwin"},
    {"01 02 03 04", "Jannalyn"},
    // TODO: Replace with the actual UID from Marl Prince's ID card
    {"YOUR_UID_HERE_MARL", "Marl Prince"},
    // TODO: Replace with the actual UID from Renz's ID card
    {"YOUR_UID_HERE_RENZ", "Renz"}
};
const int numMappings = sizeof(personMappings) / sizeof(PersonMapping);

// --- Function Prototypes ---
void setupWiFi();
void setupHardware();
void turnOffAllLEDs();
void indicateSystemReady();
void indicateError();
String getScannedUID();
String getPersonFromPhysicalUID(String physicalUid);
void handleScan(String personName);
void executeLedAction(const char* action, const char* category);
int getLedPinForCategory(const char* category);
void blinkLed(int pin, int times, int duration);

// ====================================================
// SETUP
// ====================================================
void setup() {
    Serial.begin(115200);
    Serial.println("\n[SETUP] Person-centric RFID Processor Initializing...");
    setupHardware();
    setupWiFi();
    Serial.println("[SETUP] System is ready. Waiting for employee card scans.");
    indicateSystemReady();
}

// ====================================================
// LOOP
// ====================================================
void loop() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[LOOP] WiFi disconnected. Reconnecting...");
        indicateError();
        setupWiFi();
        return;
    }

    if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
        String physicalUid = getScannedUID();
        String personName = getPersonFromPhysicalUID(physicalUid);

        if (personName.length() > 0) {
            Serial.print("[LOOP] Scanned card UID: "); Serial.print(physicalUid);
            Serial.print(", belongs to: "); Serial.println(personName);
            handleScan(personName);
        } else {
            Serial.print("[LOOP] Scanned unknown card UID: "); Serial.println(physicalUid);
            indicateError();
        }

        rfid.PICC_HaltA();
        rfid.PCD_StopCrypto1();
        delay(2500); // Wait before allowing another scan
    }
}

// ====================================================
// Core Functions
// ====================================================

void handleScan(String personName) {
    if (WiFi.status() != WL_CONNECTED) return;

    HTTPClient http;
    String url = "https://" + String(serverName) + "/api/process-next";
    
    http.setInsecure(); 
    http.begin(url); 
    http.addHeader("Content-Type", "application/json");

    StaticJsonDocument<128> doc;
    doc["person_name"] = personName;
    String payload;
    serializeJson(doc, payload);

    Serial.print("[HTTP] Sending POST to "); Serial.println(url);
    Serial.print("[HTTP] Payload: "); Serial.println(payload);

    int httpCode = http.POST(payload);

    if (httpCode > 0) {
        Serial.print("[HTTP] Response Code: "); Serial.println(httpCode);
        String responsePayload = http.getString();
        Serial.print("[HTTP] Response Payload: "); Serial.println(responsePayload);

        StaticJsonDocument<256> responseDoc;
        DeserializationError error = deserializeJson(responseDoc, responsePayload);

        if (error) {
            Serial.print("[JSON] Deserialization failed: "); Serial.println(error.c_str());
            indicateError();
        } else {
            const char* action = responseDoc["action"];
            const char* category = responseDoc["led"];
            executeLedAction(action, category);
        }
    } else {
        Serial.print("[HTTP] Request failed, error: "); Serial.println(http.errorToString(httpCode));
        indicateError();
    }
    http.end();
}

void executeLedAction(const char* action, const char* category) {
    Serial.print("[LED] Action: "); Serial.print(action); Serial.print(", Category: "); Serial.println(category);
    int targetLed = getLedPinForCategory(category);

    if (strcmp(action, "processing_success") == 0) {
        blinkLed(targetLed, 3, 200);
    } else if (strcmp(action, "no_pending_orders") == 0) {
        indicateSystemReady();
    } else {
        indicateError();
    }
}

// ====================================================
// Helper Functions
// ====================================================

void setupHardware() {
    pinMode(LED_TOY_GUNS, OUTPUT);
    pinMode(LED_ACTION_FIGURES, OUTPUT);
    pinMode(LED_DOLLS, OUTPUT);
    pinMode(LED_PUZZLES, OUTPUT);
    turnOffAllLEDs();
    SPI.begin();
    rfid.PCD_Init();
}

void setupWiFi() {
    Serial.print("[WIFI] Connecting to "); Serial.println(ssid);
    WiFi.begin(ssid, password);
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500); Serial.print("."); attempts++;
    }
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\n[WIFI] Connected!"); Serial.print("[WIFI] IP Address: "); Serial.println(WiFi.localIP());
    } else {
        Serial.println("\n[WIFI] Connection Failed.");
    }
}

String getScannedUID() {
    String uid = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
        if (i > 0) uid += " ";
        if (rfid.uid.uidByte[i] < 0x10) uid += "0";
        uid += String(rfid.uid.uidByte[i], HEX);
    }
    uid.toUpperCase();
    return uid;
}

String getPersonFromPhysicalUID(String physicalUid) {
    for (int i = 0; i < numMappings; i++) {
        if (physicalUid.equals(personMappings[i].physicalUid)) {
            return String(personMappings[i].personName);
        }
    }
    return "";
}

int getLedPinForCategory(const char* category) {
    if (strcmp(category, "Toy Guns") == 0) return LED_TOY_GUNS;
    if (strcmp(category, "Action Figures") == 0) return LED_ACTION_FIGURES;
    if (strcmp(category, "Dolls") == 0) return LED_DOLLS;
    if (strcmp(category, "Puzzles") == 0) return LED_PUZZLES;
    return -1;
}

void turnOffAllLEDs() {
    digitalWrite(LED_TOY_GUNS, LOW);
    digitalWrite(LED_ACTION_FIGURES, LOW);
    digitalWrite(LED_DOLLS, LOW);
    digitalWrite(LED_PUZZLES, LOW);
}

void blinkLed(int pin, int times, int duration) {
    if (pin == -1) return;
    for (int i = 0; i < times; i++) {
        digitalWrite(pin, HIGH); delay(duration); digitalWrite(pin, LOW); delay(duration);
    }
}

void indicateSystemReady() {
    turnOffAllLEDs(); delay(50);
    for (int i = 0; i < 2; i++) {
        digitalWrite(LED_TOY_GUNS, HIGH); digitalWrite(LED_ACTION_FIGURES, HIGH);
        digitalWrite(LED_DOLLS, HIGH); digitalWrite(LED_PUZZLES, HIGH);
        delay(100); turnOffAllLEDs(); delay(100);
    }
}

void indicateError() {
    for (int i = 0; i < 3; i++) {
        digitalWrite(LED_TOY_GUNS, HIGH); digitalWrite(LED_ACTION_FIGURES, HIGH);
        digitalWrite(LED_DOLLS, HIGH); digitalWrite(LED_PUZZLES, HIGH);
        delay(80); turnOffAllLEDs(); delay(80);
    }
}

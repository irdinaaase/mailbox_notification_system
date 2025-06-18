#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ============== CONSTANTS & CONFIGURATION ==============
// OLED Configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// WiFi Credentials
const char* SSID = "Bullet Chicken";
const char* PASSWORD = "vagabond";
const int BOX_ID = 1;

// Pin Definitions
const int PIR_PIN = 13;          // PIR motion sensor
const int TRIG_PIN = 17;         // Ultrasonic trigger
const int ECHO_PIN = 16;         // Ultrasonic echo
const int RELAY_PIN = 4;         // Relay IN pin
const int LED_PIN = 2;           // Built-in LED

// Sensor Parameters
const float EMPTY_BOX_DISTANCE = 30.0;       // Manually set empty distance (cm)
const float DELIVERY_THRESHOLD = 13.0;       // Distance change for delivery (cm)
const float STATUS_CHANGE_THRESHOLD = 15.0;  // Threshold for status changes (cm)
const float ERROR_MARGIN = 2.0;              // Buffer to prevent false triggers (cm)
const unsigned long DELIVERY_COOLDOWN = 5000; // Minimum time between deliveries (ms)

// PIR Sensitivity Control
const unsigned long PIR_DEBOUNCE_TIME = 1000;  // 1 second debounce period
const int PIR_REQUIRED_TRIGGERS = 5;           // Number of consecutive triggers needed
const unsigned long PIR_RESET_TIME = 3000;     // Reset trigger count after this time

// Timing Intervals
const unsigned long STATUS_CHECK_INTERVAL = 5000; 
const unsigned long DISPLAY_INTERVAL = 5000; 
const unsigned long DATA_REFRESH_INTERVAL = 10000;

// ============== GLOBAL VARIABLES ==============
// Status Tracking
unsigned long lastDeliveryTime = 0;
unsigned long lastStatusCheck = 0;
unsigned long lastDisplayChange = 0;
bool lastOccupiedState = false;
bool forceStatusUpdate = true;

// PIR Control Variables
unsigned long lastPIRTrigger = 0;
int pirTriggerCount = 0;
unsigned long lastPIRReset = 0;

// Display Management
int displayScreen = 0;
String boxLocation = "Loading...";
String boxStatus = "VACANT";
String userName = "Unknown";
String userPhoneNum = "Unknown";

// ============== CORE FUNCTIONS ==============
void setup() {
  initializeSerial();
  initializeDisplay();
  initializePins();
  connectToWiFi();
  fetchBoxData();
}

void loop() {
  maintainNetworkConnection();
  checkPIR();
  updateDisplay();
  refreshDataPeriodically();
  delay(100); // Reduced delay for better PIR responsiveness
}

// ============== INITIALIZATION FUNCTIONS ==============
void initializeSerial() {
  Serial.begin(115200);
  Serial.println("\nSystem Initializing...");
}

void initializeDisplay() {
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED initialization failed");
    while(1);
  }
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.clearDisplay();
  display.display();
}

void initializePins() {
  pinMode(PIR_PIN, INPUT);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  
  digitalWrite(RELAY_PIN, LOW); // Relay OFF initially
  digitalWrite(LED_PIN, LOW);
}

// ============== NETWORK FUNCTIONS ==============
void connectToWiFi() {
  WiFi.begin(SSID, PASSWORD);
  showTemporaryMessage("Connecting to", "WiFi...");
  
  int attempts = 0;
  while(WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    attempts++;
  }
  
  if(WiFi.status() == WL_CONNECTED) {
    showTemporaryMessage("WiFi Connected", WiFi.localIP().toString());
    forceStatusUpdate = true;
    digitalWrite(LED_PIN, HIGH);
  } else {
    showTemporaryMessage("WiFi Connection", "Failed");
  }
  delay(2000);
}

void reconnectWiFi() {
  static unsigned long lastAttempt = 0;
  if(millis() - lastAttempt > 10000) {
    connectToWiFi();
    lastAttempt = millis();
  }
}

void maintainNetworkConnection() {
  if(WiFi.status() != WL_CONNECTED) {
    digitalWrite(LED_PIN, LOW);
    reconnectWiFi();
  } else {
    digitalWrite(LED_PIN, HIGH);
  }
}

// ============== PIR SENSOR FUNCTIONS ==============
void checkPIR() {
  // Reset trigger count if too much time has passed
  if(millis() - lastPIRReset > PIR_RESET_TIME) {
    pirTriggerCount = 0;
    lastPIRReset = millis();
  }

  if(digitalRead(PIR_PIN) == HIGH) {
    handlePIRTrigger();
  } else if(forceStatusUpdate) {
    handleMotionDetection();
    forceStatusUpdate = false;
  }
}

void handlePIRTrigger() {
  unsigned long currentTime = millis();
  
  // Ignore triggers that are too close together
  if(currentTime - lastPIRTrigger > PIR_DEBOUNCE_TIME) {
    pirTriggerCount++;
    lastPIRTrigger = currentTime;
    lastPIRReset = currentTime;
    
    Serial.print("PIR Trigger #");
    Serial.println(pirTriggerCount);
    
    if(pirTriggerCount >= PIR_REQUIRED_TRIGGERS) {
      pirTriggerCount = 0;
      handleMotionDetection();
    }
  }
}

// ============== MAILBOX STATUS FUNCTIONS ==============
void handleMotionDetection() {
  Serial.println("PIR Triggered - Checking for mail...");
  delay(1000); // Wait for mail to settle
  
  float currentDist = getDistance();
  logDistanceReading(currentDist);
  
  if(isNewDelivery(currentDist)) {
    handleMailEvent(true); // Mail delivered
  } 
  else if(isMailCollected(currentDist)) {
    handleMailEvent(false); // Mail collected
  }
}

void logDistanceReading(float distance) {
  Serial.print("Post-delivery distance: ");
  Serial.print(distance);
  Serial.print("cm (Empty: ");
  Serial.print(EMPTY_BOX_DISTANCE);
  Serial.println("cm)");
}

bool isNewDelivery(float currentDistance) {
  return (currentDistance < (EMPTY_BOX_DISTANCE - DELIVERY_THRESHOLD)) && 
         (millis() - lastDeliveryTime > DELIVERY_COOLDOWN);
}

bool isMailCollected(float currentDistance) {
  return currentDistance >= (EMPTY_BOX_DISTANCE - ERROR_MARGIN);
}

void handleMailEvent(bool delivered) {
  if(delivered) {
    lastDeliveryTime = millis();
    Serial.println("Status changed: OCCUPIED (New Delivery)");
    updateSystemState("OCCUPIED", "NEW MAIL!", "Status: OCCUPIED");
  } else {
    Serial.println("Status changed: VACANT (Mail Collected)");
    updateSystemState("VACANT", "MAIL COLLECTED", "Status: VACANT");
  }
  delay(2000); // Display message for 2 seconds
}

void updateSystemState(String status, String messageLine1, String messageLine2) {
  lockMailbox(status == "OCCUPIED");
  updateStatus(status);
  showTemporaryMessage(messageLine1, messageLine2);
}

// ============== SENSOR FUNCTIONS ==============
float getDistance() {
  const int NUM_READINGS = 3;
  float sum = 0;
  
  for(int i = 0; i < NUM_READINGS; i++) {
    sum += getSingleDistanceReading();
    delay(50);
  }
  return sum / NUM_READINGS;
}

float getSingleDistanceReading() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  return (duration == 0) ? EMPTY_BOX_DISTANCE : (duration * 0.034 / 2);
}

void lockMailbox(bool lock) {
  digitalWrite(RELAY_PIN, lock ? HIGH : LOW);
  Serial.println(lock ? "Mailbox LOCKED - Mail inside!" : "Mailbox UNLOCKED - Empty");
}

// ============== DISPLAY FUNCTIONS ==============
void updateDisplay() {
  if(millis() - lastDisplayChange > DISPLAY_INTERVAL) {
    displayScreen = (displayScreen + 1) % 4;
    lastDisplayChange = millis();
  }
  
  display.clearDisplay();
  display.setCursor(0, 0);
  
  switch(displayScreen) {
    case 0: displayBoxInfo(); break;
    case 1: displayUserInfo(); break;
    case 2: displaySystemStatus(); break;
  }
  display.display();
}

void displayBoxInfo() {
  display.println("BOX INFORMATION");
  display.print("\nID: "); display.println(BOX_ID);
  display.print("Status: "); display.println(boxStatus);
  display.print("Location: "); display.println(userPhoneNum.substring(0, 10));

}

void displayUserInfo() {
  display.println("USER INFORMATION");
  display.print("\nName: "); display.println(userName.substring(0, 10));
  display.print("Phone: "); display.println(userPhoneNum.substring(0, 10));
}

void displaySystemStatus() {
  display.println("SYSTEM STATUS");
  display.print("\nWiFi: "); 
  display.println(WiFi.status() == WL_CONNECTED ? "Connected" : "Offline");
  display.print("Lock: ");
  display.println(digitalRead(RELAY_PIN) ? "Engaged" : "Released");
}

void showTemporaryMessage(String line1, String line2) {
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println(line1);
  display.setCursor(0, 15);
  display.println(line2);
  display.display();
}

// ============== DATA MANAGEMENT FUNCTIONS ==============
void refreshDataPeriodically() {
  if(millis() - lastDisplayChange > DATA_REFRESH_INTERVAL) {
    fetchBoxData();
  }
}

void fetchBoxData() {
  if(WiFi.status() != WL_CONNECTED) return;
  
  HTTPClient http;
  String url = "https://humancc.site/irdinabalqis/mailbox_notification_system/arduino_php/get_box_data.php?box_id=" + String(BOX_ID);
  
  http.begin(url);
  if(http.GET() == HTTP_CODE_OK) {
    parseResponse(http.getString());
  }
  http.end();
}

void parseResponse(String payload) {
  DynamicJsonDocument doc(256);
  deserializeJson(doc, payload);
  
  boxLocation = doc["location"].as<String>();
  boxStatus = doc["status"].as<String>();
  userName = doc["user"]["name"].as<String>();    
  userPhoneNum = doc["user"]["phone"].as<String>();
  
  bool serverOccupied = (boxStatus == "OCCUPIED");
  if(serverOccupied != lastOccupiedState) {
    lastOccupiedState = serverOccupied;
    lockMailbox(serverOccupied);
  }
}

void updateStatus(String status) {
  if(WiFi.status() != WL_CONNECTED) {
    Serial.println("Cannot update status - WiFi disconnected");
    return;
  }
  
  HTTPClient http;
  String url = "https://humancc.site/irdinabalqis/mailbox_notification_system/arduino_php/update_status.php?box_id=" + String(BOX_ID) + "&box_status=" + status;
  
  http.begin(url);
  int httpCode = http.GET();
  
  if(httpCode == HTTP_CODE_OK) {
    Serial.print("Status updated to: ");
    Serial.println(status);
    boxStatus = status;
  } else {
    Serial.print("Status update failed: ");
    Serial.println(httpCode);
  }
  http.end();
}
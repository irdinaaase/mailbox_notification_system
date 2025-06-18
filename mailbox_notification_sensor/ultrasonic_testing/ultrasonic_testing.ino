#define ECHO_PIN 16 // attach pin 16 esp32 to pin Echo of HY-SRF05
#define TRIG_PIN 17 // attach pin 17 esp32 to pin Trig of HY-SRF05

void setup()
{
  Serial.begin(115200);
  pinMode(TRIG_PIN, OUTPUT); // Sets the TRIG_PIN as an OUTPUT
  pinMode(ECHO_PIN, INPUT);  // Sets the ECHO_PIN as an INPUT
}

void loop()
{
  delay(1000);

  long duration; // variable for the duration of sound wave travel
  int distance;  // variable for the distance measurement

  // Clears the TRIG_PIN condition
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  // Sets the TRIG_PIN HIGH (ACTIVE) for 10 microseconds
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  // Reads the ECHO_PIN, returns the sound wave travel time in microseconds
  duration = pulseIn(ECHO_PIN, HIGH);
  // Calculating the distance
  distance = duration * 0.034 / 2; // Speed of sound wave divided by 2 (go and back)
  // Displays the distance on the Serial Monitor
  Serial.println("Distance: " + String(distance) + " cm");
}
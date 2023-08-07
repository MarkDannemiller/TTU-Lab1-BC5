/*
* This ESP8266 code by Mark Dannemiller completes 3 functions to debug Basys data communicated over an I2C line between the devices.
    1. I2C communication with the Basys board receiving 20 bytes of debug data at a time
    2. Display debug data on a 4x20 LCD screen
    3. Communicate with a desktop application made in Unity over WiFi using the "Uduino" plugin for Unity and library for Arduino.  This super 
       useful system for Arduino communication can be found at: https://www.marcteyssier.com/uduino/

* The ESP operates in a master configuration for communication with the Basys board.  The slave
* side code implemented on the Basys board can be found in the I2C_COMMS.v module on the Nautilus Github.
*
* Uduino code can be removed and uduino.print() statements replaced by Serial.print() will convert this code to serial communication only
*
* Feel free to use any part of this code with the only requirement being attribution to this public repository so that others can access the same
* information.
*/

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// Uduino settings
#include <Uduino_Wifi.h>
Uduino_Wifi uduino("Nautilus"); // Declare and name your object

//iPhone Hotspot Settings
IPAddress ip(172, 20, 10, 10);
IPAddress gateway(172, 20, 10, 1);
IPAddress subnet(255, 255, 255, 0);

// set the LCD number of columns and rows
int lcdColumns = 20;
int lcdRows = 4;

// set LCD address, number of columns and rows
// if you don't know your display address, run an I2C scanner sketch
LiquidCrystal_I2C lcd(0x3F, lcdColumns, lcdRows);  

#define SCL_PIN D1
#define SDA_PIN D2

int address=114;

//DRIVE CONSTANTS (SENDING DATA TO BASYS HAS NOT BEEN IMPLEMENTED)
byte forward_speed = 1;
byte reverse_speed = 1;
byte rotate_speed = 1;
byte slow_forward_speed = 1;
byte slow_rotate_speed = 1;
byte box_detect_speed = 1;

byte us_detect_dist = 1;
byte char_min_ms = 55;
byte open_close = 1;
byte dispense_time = 1;

//FOR FANCY MOVEMENT (NEVER IMPLEMENTED. SEE NOTE ABOVE)
byte xbox_mode;
byte directions;
byte left_speed;
byte right_speed;

byte def = 1;


//BASYS MEASUREABLES (RECEIVED FROM BASYS AND IMPLEMENTED IN VERILOG ON SLAVE SIDE)
float battery_voltage;
float current_left;
float current_right;
unsigned int ips_state;
unsigned int pdu_state;
float us_dist_front;
float us_dist_back;
byte processed_stream[3];
unsigned int decoded_val;
unsigned int flags; //flags will be tripped for a single transaction of I2C to decipher exactly when system triggered event (avoid duplicate info)

unsigned int left_dir;
unsigned int right_dir;
unsigned int motor_speed; //not implemented

//IPS = INDUCTION PROXIMITY SENSOR
//PDU = PAYLOAD DESIGNATION UNIT (SENSOR SYSTEM ON NAUTILUS)
const String ips_states[5] = {"0", "D", "R", "T", "S"}; //LETTER REPRESENTATIONS OF STATES (DRIVE, REVERSE, TURN, SPECIAL FORWARD)
const String pdu_states[5] = {"D", "F", "B", "S", "M"}; //LETTER REPRESENTATIONS OF STATES (DRIVE, FORWARD, BACKWARD, SCAN, MARBLE DISPENSE)
int decoded_vals[10];
int val_index = 0;

//IMPLEMENTED BY UNITY (NEVER WRITTEN BUT WOULD HAVE THE PURPOSE OF UPDATING DRIVE CONSTANTS ON THE BASYS)
void setConstants() {

}

//IMPLEMENTED BY UDUINO (NEVER WRITTEN. WOULD REQUIRE A MORE COMPLEX I2C TRANSACTION SYSTEM BETWEEN ESP AND BASYS)
void getConstants() {

}

//WRITES 20 BYTES OF VALUES TO OVERRITE BASYS CONSTANTS (NEVER FINISHED AS DATA RECEPTION BY BASYS WAS NOT WRITTEN)
void writeConstants() {
    Wire.beginTransmission(address);
    Wire.write(forward_speed); //we will write 20 bytes
    Wire.write(reverse_speed);
    Wire.write(rotate_speed);
    Wire.write(slow_forward_speed);
    Wire.write(slow_rotate_speed);
    Wire.write(box_detect_speed);
    Wire.write(us_detect_dist);
    Wire.write(char_min_ms);
    Wire.write(open_close);
    Wire.write(dispense_time);
    Wire.write(def);
    Wire.write(def);
    Wire.write(def);
    Wire.write(def);
    Wire.write(def);
    Wire.write(def);
    Wire.write(def);
    Wire.write(def);
    Wire.write(def);
    Wire.write(def);
    int error = Wire.endTransmission();
     
    uduino.print("Result of Send: \t");
    uduino.println(error);  
}

//REQUESTS 20 BYTES OF BASYS DATA (FULLY IMPLEMENTED AND READY FOR OTHERS TO USE)
void getBasysValues() {
          
  Wire.requestFrom(address, 20); //change to 20 bytes
  bool failed;

  //Wire.read() 20 times and convert data into correct variables and data types
  if(true) {
    battery_voltage = Wire.read() * 0.0509803921568627f; //conversion to volts
    current_left = Wire.read() / 128.0f; //128 = 1 amp
    current_right = Wire.read() / 128.0f;
    ips_state = Wire.read();
    pdu_state = Wire.read();
    us_dist_front = (unsigned int)Wire.read() / 58.0f; //divide by native units/cm
    us_dist_back = (unsigned int)Wire.read() / 58.0f; //divide by native units/cm
    processed_stream[1] = Wire.read();
    processed_stream[2] = Wire.read();
    processed_stream[3] = Wire.read();
    decoded_val = Wire.read();
    flags = Wire.read();

    if(flags == 1) {
      decoded_vals[val_index] = decoded_val;
      val_index = val_index > 8 ? 0 : val_index + 1; //val_index shall run from 0->5
    }
  }
  else
    failed = true;


  while(Wire.available()) 
  {
    uduino.print("Extra: \t");
    uduino.println(Wire.read());
    delay(20);
  }
  
  //SEND BASYS DATA OVER WIFI TO UNITY APPLICATION (ALSO PRINTS TO SERIAL MONITOR AND CAN BE REPLACED BY SERIAL.PRINTLN)
  uduino.print("Battery Volts: ");
  uduino.println(battery_voltage);
  delay(20);
  uduino.print("Left Current: ");
  uduino.println(current_left);
  delay(20);
  uduino.print("Right Current: ");
  uduino.println(current_right);
  delay(20);
  uduino.print("IPS State: ");
  uduino.println(ips_states[ips_state]);
  delay(20);
  //uduino.println(ips_state);
  uduino.print("PDU State: ");
  uduino.println(pdu_states[pdu_state]);
  delay(20);
  uduino.print("Front US Dist: ");
  uduino.println(us_dist_front);
  delay(20);
  uduino.print("Back US Dist: ");
  uduino.println(us_dist_back);
  delay(20);
  uduino.print("Processed Stream: ");
  uduino.print(processed_stream[1], BIN); //print as a binary representation for IR morse bitstream
  uduino.print(processed_stream[2], BIN);
  uduino.println(processed_stream[3], BIN);
  delay(30);
  uduino.print("Processed Num: ");
  uduino.println(decoded_val);
  delay(30);
  uduino.print("Flags: ");
  uduino.println(flags, BIN);
  delay(20);

  uduino.print("Nums: ");
  for(int x=0; x<10; x++) {
    uduino.print(decoded_vals[x]);
    uduino.print(" ");
  }
  uduino.println("\n");
}


void setup()
{
  address = 114;

  Serial.print("\n \nListening for BASYS at address: ");
  Serial.println(address);

  delay(2000); //WAIT 2 SECONDS BEFORE INIT OF I2C
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000);
  Serial.begin(115200);
  Serial.println("Verilog I2C Connection Attempted\n\n");

  delay(2000); //WAIT 2 SECONDS BEFORE INIT OF LCD

  lcd.begin(lcdColumns, lcdRows);
  //initialize LCD
  lcd.init();
  //turn on LCD backlight                      
  lcd.backlight();


  delay(1000);
  Serial.begin(115200);

  uduino.setStaticIP(ip, gateway , subnet ); // IPAddress ip, IPAddress gateway, IPAddress subnet
  if(!uduino.connectWifi("Mark's iPhone XIV", "password")) {
    if(!uduino.connectWifi("ATTkReZTdS", "password")) {
        Serial.println("Failed to connect to hotspot or home wifi.");
    }
  }
}

void loop()
{
  uduino.update();
  if (uduino.isConnected()) {
    uduino.println("Nautilus is connected with a static IP");
    uduino.delay(20);
  }
  //HANDLE PULLING NEW CONSTANT VALUES FROM WEBSERVER
  //IF CONSTANTS HAVE CHANGED, CALL writeConstants()
  //OTHERWISE, requestVals() FROM BASYS EACH TRANSACTION
  //NEXT, READ IN VALUES TO EACH CORRESPONDING FIELD
  //PUBLISH NEW VALUES TO WEB SERVER
  //REFRESH LCD WITH NEW VALUES

  writeConstants();
  delay(10);
  getBasysValues();
  delay(10);

  
  //CONVERT ULTRASONIC DISTANCE TO STRING OF 4
  String us_front_str = String(us_dist_front);
  char us_front[4];
  us_front_str.toCharArray(us_front, 4);
  String front_spacing = us_front[1] == 0 ? "    " : us_front[2] == 0 ? "   " : "  ";

  //CONVERT ULTRASONIC DISTANCE TO STRING OF 4
  String us_back_str = String(us_dist_back);
  char us_back[4];
  us_back_str.toCharArray(us_back, 4);
  String back_spacing = us_back[1] == 0 ? "    " : us_back[2] == 0 ? "   " : "  ";

  // clears the display to print new message
  lcd.init();
  delay(10);
  // set cursor to first column, first row
  lcd.setCursor(0, 0);
  // print message
  lcd.print("USF:" + String(us_front) + front_spacing + "IPS:" + ips_states[ips_state] + " ");
  //PRINT DECODED VALUES 0 THROUGH 4
  for(int x = 0; x < 5; x++) {
    if(decoded_vals[x] < 4)
      lcd.print(decoded_vals[x]);
    else
      lcd.print("E");
  }
  lcd.setCursor(0, 1);
  lcd.print("USB:" + String(us_back) + back_spacing + "PDU:" + pdu_states[pdu_state] + " ");
  //PRINT DECODED VALUES 5 THROUGH 9
  for(int x = 5; x < 10; x++) {
    if(decoded_vals[x] < 4)
      lcd.print(decoded_vals[x]);
    else
      lcd.print("E");
  }
  lcd.setCursor(0, 2);
  lcd.print("IR:");
  lcd.print(processed_stream[1], BIN);
  lcd.print(processed_stream[2], BIN);
  lcd.print(processed_stream[3], BIN);
}
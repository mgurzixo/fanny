
// Fan control for air extractor
// MG 28/01/2022

// https://stackoverflow.com/questions/21796762/using-visual-studio-to-code-for-avr/21804988#21804988
// https://www.nongnu.org/avr-libc/user-manual/using_tools.html

#if defined(ARDUINO_AVR_DIGISPARK)
#define MCU_TINY
#pragma message "MCU: MCU_TINY"
#elif defined(ARDUINO_AVR_NANO)
#define MCU_328
#pragma message "MCU: MCU_328"
#else
#error "Unknown MCU."
#endif

// #include <Arduino.h>
#include <SoftwareSerial.h>
#include <avr/eeprom.h>
#include <avr/io.h>
#include <avr/wdt.h>
#include "mgBlinker.h"
#include "mgButton.h"

/* Configure:

ATTiny85:
  defined( __AVR_ATtiny85__ )
  Timer/Counter 0: PWM 32Khz

  PB0: (Pin0) OC0A Timer0 Compare Match A output
  PB1: (Pin1) Digital output, onboard LED
  PB2: (Pin2) digital button input, with pullup
  PB3: (pin3) software serial input RX
  PB4: (pin4) software serial output TX


AtMega328P:
  defined(__AVR_ATmega32U4__)||
  defined(__AVR_ATmega328P__)||
  defined(__AVR_ATmega328__)

  PB3: (Pin11) OC2A Timer2 Compare Match A output
  PB5: (Pin13) Digital output, onboard LED
  PD2: (Pin2) digital button input, with pullup
  PD3: (pin3) software serial input RX
  PD4: (pin4) software serial output TX

*/

#if defined MCU_TINY
#define LED_PIN 1
#define BUTTON_PIN 2
#elif defined(MCU_328)
#define LED_PIN 13
#define PWM_PIN 11
#define BUTTON_PIN 2
#define RX_PIN 3
#define TX_PIN 4
#define BLE Serial
#define DBG mySerial
// #define TPIN 12
#endif

uint8_t EEMEM espeed;
#define MAX_SPEED 4

static uint8_t speed;  // 0,1,2,3,4

static Blinker blinker(LED_PIN, 200, 200, 1500);
static Button button(BUTTON_PIN);
static SoftwareSerial mySerial(RX_PIN, TX_PIN);  // RX, TX

static void log(const __FlashStringHelper* str, const char* val) {
  DBG.print(str);
  DBG.print(val);
  DBG.println("\r\n");
}

static void setPwm() {
#if defined MCU_TINY
  switch (speed) {
    case 0:
      OCR0A = 0;
      break;  // off
    case 1:
      OCR0A = 255 - 96;
      break;  // lo
    case 2:
      OCR0A = 255 - 64;
      break;  // lo
    case 3:
      OCR0A = 255 - 32;
      break;  // med
    case 4:
    default:
      OCR0A = 255;
      break;  // hi
  }
#elif defined MCU_328
  switch (speed) {
    case 0:
      OCR2A = 255;
      break;  // off
    case 1:
      OCR2A = 96;
      break;  // lo
    case 2:
      OCR2A = 64;
      break;  // lo
    case 3:
      OCR2A = 32;
      break;  // med
    case 4:
    default:
      OCR2A = 0;
      break;  // hi
  }
#endif
}

static uint32_t nextMillis;
static bool ml;

static void theMillis() {
  if (millis() > nextMillis) {
    ml = ml ? false : true;
    nextMillis += 1000;
    // ICI
    // DBG.println("Ici Fanny");
  }
}

static void serInit() {
  DBG.begin(9600);
  DBG.println("Ici Fanny");

  BLE.begin(9600);
  BLE.print("AT\r\n");
}

static void configure() {
#if defined(MCU_TINY)
  DDRB = (1 << PB1) | (1 << PB0);  // set PB1 and PB0 as output
  // PWM
  TCCR0A = 0x00;  // Normal mode
  TCCR0A |= (1 << WGM00) | (1 << COM0A1);
  TCCR0B = 0x00;
  TCCR0B |= (1 << CS00);  // prescaling with 0
  TCNT0 = 0;
#elif defined MCU_328
  pinMode(BUTTON_PIN, INPUT_PULLUP);  // Button
  pinMode(LED_PIN, OUTPUT);
  // pinMode(TPIN, OUTPUT);

  // PWM
  DDRB |= (1 << PB3);  // pin 11 COM2A output
  // Timer 2 activation
  PRR &= ~(1 << PRTIM2);
  // Set Initial Timer value
  TCNT2 = 0;
  // Output compare register A value
  OCR2A = 127;
  // Set on compare match, clear on bottom inverting mode
  TCCR2A |= (1 << COM2A1);
  TCCR2A |= (1 << COM2A0);
  // Set fast PWM mode 3 TOP = 255
  // TCCR2A |= (1 << WGM21) | (1 << WGM20);  // fast pwm to 255
  TCCR2A |= (1 << WGM20);  // fast pwm to 255

  // Set prescaller ??? and start timer
  TCCR2B &= ~(1 << CS22);
  TCCR2B &= ~(1 << CS21);
  TCCR2B |= (1 << CS20);

  serInit();
#endif
}

void setup() {
  wdt_reset();
  // wdt_enable(WDTO_4S);
  configure();
  // EEPROM
  speed = eeprom_read_byte(&espeed);
  if (speed > MAX_SPEED) {
    // Blank part: eeprem == 0xff
    speed = MAX_SPEED;
    eeprom_write_byte(&espeed, speed);
  }
  blinker.blink(speed + 1, 3);
  setPwm();
  DBG.println(F("pwm:Setup OK"));
}

byte comdata;

char bleBuf[24];
byte idx = 0;

/* Commands
"V\n" : Version
      Response: "VIciFanny V0.01 T1\n" Version, Type
"S\n" : Query Speed
      Response: "Sx/y\n" Speed x, maxSpeed y
"SnewSpeed\n" : Set new speed
      Response: "Sx/y\n"
"N\n" : Query Name
      Response: "NcurrentName\n"
"NnewName\n" : Set Name
      Response: "NnewName\n"

If error: Response "EReason\n"
*/

#define BIS_RESET 0
#define BIS_NAME 1
#define BIS_TXPOWER 2
#define BIS_RXGAIN 3
#define BIS_SRVUUID 4
#define BIS_CHARUUID 5
#define BIS_BLEUSB 6
#define BIS_RUNNING 7

static byte initState = BIS_RESET;

/* handle a complete bleBuffer string */
static void doCommand() {
  byte c = bleBuf[0];
  if (c == 0)
    c = '?';
  log(F("doCommand:"), bleBuf);
  switch (c) {
    case '+':
    case 'O':
      // Ble-Nano is disconnected
      break;
    case 'V':
      BLE.print(F("VFanny V1 T1 S"));
      BLE.write(speed + '0');
      BLE.write('/');
      BLE.write(MAX_SPEED + '0');
      BLE.write('\n');
      break;
    case 'S':
      speed = bleBuf[1] - '0';
      if (speed > MAX_SPEED)
        speed = MAX_SPEED case 'N' : if (bleBuf[1] != 0) {
          log(F("Setting name:"), bleBuf + 1);
          delay(2000);
          BLE.print(F("AT+NAME="));
          BLE.print(bleBuf + 1);
          BLE.print("\r\n");
        }
      else
        BLE.println(F("Ntoto"));
      break;
    default:
      char str[2];
      str[0] = c;
      str[1] = 0;
      BLE.print(F("ECmd unknown:"));
      BLE.println(str);
  }
}

static void handleBle() {
  while (Serial.available() > 0) {
    comdata = Serial.read();
    // DBG.write(comdata);
    if (comdata == '\r')
      continue;
    if (comdata == '\n') {
      bleBuf[idx] = 0;
      doCommand();
      idx = 0;
    } else {
      bleBuf[idx++] = comdata;
    }
  }
}

static void handleButton() {
  if (button.pressed()) {
    speed++;
    if (speed > MAX_SPEED) {
      speed = 0;
    }
    blinker.blink(speed + 1, 3);
    eeprom_write_byte(&espeed, speed);
    setPwm();
  }
}

void loop() {
  handleButton();
  handleBle();
  blinker.update();
  theMillis();
  wdt_reset();
}

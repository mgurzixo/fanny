
// Fan control for air extractor
// MG 28/01/2022
#include <Arduino.h>
#include <avr/eeprom.h>
#include <avr/io.h>
#include <avr/wdt.h>
#include "mgBlinker.h"
#include "mgButton.h"

uint8_t EEMEM espeed;
#define MAX_SPEED 4

uint8_t speed;  // 0,1,2,3,4

Blinker blinker(1, 500, 500, 3000);
Button button(2);

// Configure:
//  PB0: PWM 32 kHz
//  PB1: Digital output, onboard LED
//  PB2: digital input, with pullup

void setOcr0a() {
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
}

void setup() {
  wdt_reset();
  wdt_enable(WDTO_4S);
  DDRB = (1 << PB1) | (1 << PB0);  // set PB1 and PB0 as output
  // PWM
  TCCR0A = 0x00;  // Normal mode
  TCCR0A |= (1 << WGM00) | (1 << COM0A1);
  TCCR0B = 0x00;
  TCCR0B |= (1 << CS00);  // prescaling with 0
  TCNT0 = 0;
  // EEPROM
  speed = eeprom_read_byte(&espeed);
  if (speed > MAX_SPEED) {
    // Blank part: eeprem == 0xff
    speed = MAX_SPEED;
    eeprom_write_byte(&espeed, speed);
  }
  blinker.blink(speed + 1, 3);
  setOcr0a();
}

void loop() {
  if (button.pressed()) {
    speed++;
    if (speed > MAX_SPEED) {
      speed = 0;
    }
    blinker.blink(speed + 1, 3);
    eeprom_write_byte(&espeed, speed);
    setOcr0a();
  }
  delay(200);  // longer than bounce time, so no bounce problem
  blinker.update();
  wdt_reset();
}

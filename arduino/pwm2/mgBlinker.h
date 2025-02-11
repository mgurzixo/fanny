
// Fan control for air extractor
// MG 28/01/2022
#include <Arduino.h>
#include <avr/eeprom.h>
#include <avr/io.h>

// Configure:
//  PB0: PWM 32 kHz
//  PB1: Digital output, onboard LED
//  PB2: digital input, with pullup

// FLASH_IDLE -> FLASH_ON -> FLASH_IDLE
#define FLASH_IDLE 0
#define FLASH_ON 1
#define FLASH_OFF 2

class Blinker {
  int8_t ledId_;
  int8_t nBlinks_;
  int8_t repeatsRemaining_;
  int8_t blinksRemaining_;  // Remaining number of flashes
  int8_t flashState_;
  uint32_t nextMillis_;
  uint32_t onMillis_;
  uint32_t offMillis_;
  uint32_t betweenMillis_;

  void flashToOn() {
    digitalWrite(ledId_, HIGH);
    nextMillis_ = (nextMillis_ ? nextMillis_ : millis()) + onMillis_;
    flashState_ = FLASH_ON;
  }

  void flashToBetween() {
    digitalWrite(ledId_, LOW);
    if (repeatsRemaining_ == 0) {
      flashState_ = FLASH_IDLE;
      nextMillis_ = 0;
      return;
    }
    nextMillis_ = nextMillis_ + betweenMillis_;
    flashState_ = FLASH_IDLE;
    --repeatsRemaining_;
    blinksRemaining_ = nBlinks_;
  }

  void flashToOff() {
    digitalWrite(ledId_, LOW);
    if (blinksRemaining_ == 0) {
      flashToBetween();
      return;
    }
    nextMillis_ = nextMillis_ + offMillis_;
    flashState_ = FLASH_OFF;
    --blinksRemaining_;
  }

 public:
  // Ctor
  Blinker(int8_t ledId,
          uint32_t onMillis = 500,
          uint32_t offMillis = 500,
          uint32_t betweenMillis = 2000)
      : ledId_(ledId),
        flashState_(FLASH_IDLE),
        nextMillis_(0),
        onMillis_(onMillis),
        offMillis_(offMillis),
        betweenMillis_(betweenMillis) {}

  void update() {
    if (nextMillis_ == 0)
      return;
    uint32_t now = millis();
    if (now < nextMillis_)
      return;
    switch (flashState_) {
      case FLASH_IDLE:
        if (repeatsRemaining_ == 0) {
          nextMillis_ = 0;
          break;
        }
        flashToOn();
        break;
      case FLASH_ON:
        flashToOff();
        break;
      case FLASH_OFF:
        if (blinksRemaining_ == 0) {
          flashToBetween();
          break;
        }
        flashToOn();
        break;
    }
  }

  void blink(int8_t nBlinks, int8_t nRepeats = 1) {
    nextMillis_ = 0;
    nBlinks_ = nBlinks;
    repeatsRemaining_ = nRepeats;
    blinksRemaining_ = nBlinks_;
    flashState_ = FLASH_IDLE;
    digitalWrite(ledId_, LOW);
    if (nBlinks == 0)
      return;
    flashToOn();
  }
};

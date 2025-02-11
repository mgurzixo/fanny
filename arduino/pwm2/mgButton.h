#include <Arduino.h>

#define DEBOUNCE_MILLIS 20

class Button {
  uint8_t pinId_;
  uint8_t currentState_;  // LOW / HIGH
  uint32_t ignoreUntil_;

  bool check() {
    uint8_t val = digitalRead(pinId_);
    if (val == currentState_)
      return false;
    currentState_ = val;
    ignoreUntil_ = millis() + DEBOUNCE_MILLIS;
    return true;
  }

 public:
  Button(uint8_t pinId) : pinId_(pinId) {
    pinMode(pinId_, INPUT);
    currentState_ = digitalRead(pinId_);
    ignoreUntil_ = millis() + DEBOUNCE_MILLIS;
  }

  bool pressed() {
    if (millis() < ignoreUntil_)
      return false;
    if (!check())
      return false;
    return currentState_ == LOW ? true : false;
  }
};

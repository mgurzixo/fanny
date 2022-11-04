"use strict";

export function mgToast(text, success){
window.plugins.toast.showWithOptions(
  {
    message: text,
    duration: 3000, position: "bottom", addPixelsY: -200, styling: {
    }
  }, success);
}

export function mgErrorToast(text, success){
  window.plugins.toast.showWithOptions(
    {
      message: text,
      duration: 3000, position: "bottom", addPixelsY: -200, styling: {
        backgroundColor: '#DD0000', // make sure you use #RRGGBB. Default #333333
      textColor: '#FFFFFF', // Ditto. Default #FFFFFF
      }
    }, success);
  }

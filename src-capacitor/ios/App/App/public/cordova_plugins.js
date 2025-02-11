
  cordova.define('cordova/plugin_list', function(require, exports, module) {
    module.exports = [
      {
          "id": "cordova-plugin-ble-central.ble",
          "file": "plugins/cordova-plugin-ble-central/www/ble.js",
          "pluginId": "cordova-plugin-ble-central",
        "clobbers": [
          "ble"
        ]
        },
      {
          "id": "cordova-plugin-x-toast.Toast",
          "file": "plugins/cordova-plugin-x-toast/www/Toast.js",
          "pluginId": "cordova-plugin-x-toast",
        "clobbers": [
          "window.plugins.toast"
        ]
        }
    ];
    module.exports.metadata =
    // TOP OF METADATA
    {
      "cordova-plugin-ble-central": "1.7.8",
      "cordova-plugin-x-toast": "2.7.3"
    };
    // BOTTOM OF METADATA
    });
    
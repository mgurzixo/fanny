<template>
  <q-page class="q-ma-sm column justify-start">
    <q-dialog v-model="isDialogOpen">
      <DoDevice :device="device" @disconnectEvent="disconnected"></DoDevice>
    </q-dialog>
    <q-list bordered>
      <div v-for="device in devices" :key="device.id">
        <q-item class="q-my-sm" clickable xv-ripple>
          <q-item-section>
            <q-item-label>{{ device.name }}</q-item-label>
            <q-item-label caption>
              Rssi:{{ device.rssi }}
            </q-item-label>
            <!-- <q-item-label caption>
              Lru:{{ device.lru }}
            </q-item-label> -->
            <q-item-label caption>
              Id:{{ device.id }}
            </q-item-label>
          </q-item-section>
          <q-item-section side top>
            <q-btn color="primary" label="Connect" @click="doConnect(device)"></q-btn>
            <q-separator color="green" />
          </q-item-section>
        </q-item>
        <q-separator />
      </div>
    </q-list>
  </q-page>

</template>

<script setup>

//
// MG Must patch Cordova BLE plugin:
// src-capacitor/node_modules/cordova-plugin-ble-central/src/android/L2CAPContext.java
// Comment the 2 references to androidx.annotation.RequiresApi
//

import { ref, onMounted, onUnmounted } from "vue";
import DoDevice from "components/DoDevice.vue";
import { isDialogOpen, devices, insertDevice, updateLru } from "@/stores/fannyStore";
import { mgErrorToast } from "src/lib/mgToast";


let device = ref({}); // Selected device

let isScanning = false;

// ble is magically given by cordova-plugin-ble-central

function doConnect(d) {
  console.log(`[IndexPage.doConnect] d:${JSON.stringify(d)}`);
  device.value = d;
  isDialogOpen.value = true;
  stopScanBle();
}

function disconnected() {
  console.log(`[IndexPage.disConnected] `);
  if (device.value != undefined) ble.refreshDeviceCache(device.value.id, 10000);
  device.value = undefined;
  isDialogOpen.value = false;
  devices.value = [];
  scanBle();
}

function srvUUID(advertisementData) {
  // Incomplete 16-bit UUIDs
  try {
    var bytes = new Uint8Array(advertisementData["0x02"]);
    // console.log(`[IndexPage.srvUUID] ${JSON.stringify(bytes)}`)
    return bytes[1] * 256 + bytes[0];
  }
  catch (error) {
    return undefined;
  }
}

// ASCII only
function bytesToString(buffer) {
  return String.fromCharCode.apply(null, new Uint8Array(buffer));
}

function getLocalName(advertisementData) {
  try {
    var localName = bytesToString(advertisementData["0x09"]);
    // console.log(`[IndexPage.getLocalName] localName:${localName}`);
    return localName;
  }
  catch (error) {
    return undefined;
  }
}

// i must be < 256
function asHexString(i) {
  var hex;
  hex = i.toString(16);
  // zero padding
  if (hex.length === 1) {
    hex = "0" + hex;
  }
  return "0x" + hex;
}

function parseAdvertisingData(buffer) {
  var length, type, data, i = 0, advertisementData = {};
  var bytes = new Uint8Array(buffer);

  while (length !== 0) {
    length = bytes[i] & 0xFF;
    i++;
    // decode type constants from https://www.bluetooth.com/specifications/assigned-numbers/
    type = bytes[i] & 0xFF;
    i++;
    data = bytes.slice(i, i + length - 1).buffer; // length includes type byte, but not length byte
    i += length - 2;  // move to end of data
    i++;
    advertisementData[asHexString(type)] = data;
  }
  return advertisementData;
}

function scanError(err) {
  console.error(`[IndexPage.failure] error:${err}`);
  mgErrorToast(`[IndexPage.failure] error:${err}`);

}

function scanOk(device) {
  // console.log(`[IndexPage.scanOk] Got Device:${JSON.stringify(device)}`);
  let d = parseAdvertisingData(device.advertising)
  // console.log(`[IndexPage.scanOk] AdvertisingData:${JSON.stringify(d)}`);
  let serviceUUID = srvUUID(d);
  let localName = getLocalName(d);
  // console.log(`[IndexPage.scanOk] device:${device.id} name:${device.name} localName:${localName}`);
  if (localName != undefined) {
    // Android caches the old name...
    device.advName = device.name;
    device.name = localName;
  }
  if (device.name != undefined && serviceUUID == 0xffe0) {
    // if (devicesById[device.id] === undefined)
    // console.log(`[IndexPage.scanOk] Real device:${JSON.stringify(device)}`);
    device.lru = Number(device.rssi);
    insertDevice(device);
  }
}


function scanBle() {
  if (isScanning === true) return;
  if (ble === undefined) return;
  isScanning = true;
  // console.log(`[IndexPage.scanBle] scanning`);
  ble.startScanWithOptions([], { reportDuplicates: true }, scanOk, scanError);
}

function stopScanBle() {
  if (isScanning === false) return;
  if (ble === undefined) return;
  console.log(`[IndexPage.stopScanBle] stop scanning`);
  ble.stopScan();
  isScanning = false;
}

let intervalId;

onUnmounted(() => {
  stopScanBle();
  if (intervalId != undefined) {
    clearInterval(intervalId);
    intervalId = undefined;
  }
});

onMounted(() => {
  let ul = updateLru;
  if (ble === undefined) {
    mgErrorToast("Bluetooth LE not Available! ");
  }
  // console.log(`[IndexPage.onMounted] ble:${ble}`);
  intervalId = setInterval(() => ul(), 2000);
  scanBle();
});

</script>

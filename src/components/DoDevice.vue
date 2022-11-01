<template>
  <q-card class="zk-card">
    <div v-if="isConnected === true">
      <q-card-section>
        <div class="text-h5">
          <q-icon size="lg" name="img:icons/computer-fan.svg"></q-icon>
          {{ device.name }}
        </div>
      </q-card-section>

      <q-card-section class="q-pt-none q-mb-sm">
        <div class="cursor-pointer" style="width: 100%">
          <q-form @submit="onSubmit" @reset="onReset" class="q-gutter-md">
            <div class="text-h5">Name:</div>
            <q-input class="col-grow q-py-none q-my-none text-h5 " rounded outlined v-model="newName"
              :rules="[val => val.length > 2 && val.length < 13 || 'Min 3, Max 12 characters']">
            </q-input>
            <div class="row justify-end items-baseline">
              <q-btn label="Reset" type="reset" color="primary" flat class="q-ml-sm" />
              <q-btn class="q-mx-lg q-mt-sm" label="Set Name" type="submit" color="primary" />
            </div>
          </q-form>

        </div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div class="text-h5">Speed:</div>
        <q-slider v-model="speed" marker-labels :min="minSpeed" :max="maxSpeed" @update:modelValue="onSpeedUpdate" />
      </q-card-section>

      <q-card-actions align="right">
        <q-btn label="Ok" color="primary" @click="doClose" />
      </q-card-actions>
    </div>


    <div v-else class="q-ma-lg column">
      <q-btn loading color="primary" class="q-px-lg">
        <template v-slot:loading>
          <q-spinner-radio class="on-left" />
          Connecting to "{{ device.name }}"
        </template>
      </q-btn>
      <q-btn class="q-mt-lg self-center" color="negative" @click="doClose" label="Stop" />
    </div>
  </q-card>
</template>
​
<style lang="scss" scoped>
.zk-card {
  width: 95vw;
  max-width: 1000px;
}
</style>

<script setup>
import { clearDevice } from "@/stores/fannyStore";

import { ref, onMounted, onUnmounted } from "vue";
import { mgToast, mgErrorToast } from "@/lib/mgToast";
// import { hexy } from "@/lib/hexy.js"

let isConnected = ref(false);
let speed = ref(0);
let minSpeed = ref(0);
let maxSpeed = ref(0);
let newName = ref("");
let fanName = ref("");

const SERVICE_UUID = "FFE0";
const CHARACTERISTIC_UUID = "FFE1";


let props = defineProps({
  device: {
    type: Object,
  },
});

const emit = defineEmits(["disconnectEvent"])

async function doClose() {
  console.log(`[DoDevice.doClose] Closing`);
  // await ble.withPromises.disconnect(props.device.id);
  // console.log(`[DoDevice.doClose] disconnected`);
  isConnected.value = false;
  emit("disconnectEvent");
}

// ASCII only
function stringToBytes(string) {
  var array = new Uint8Array(string.length);
  for (var i = 0, l = string.length; i < l; i++) {
    array[i] = string.charCodeAt(i);
  }
  return array.buffer;
}

// ASCII only
function bytesToString(buffer) {
  return String.fromCharCode.apply(null, new Uint8Array(buffer));
}


async function setName(name) {
  let id = props.device.id;
  console.log(`[DoDevice.setName] device:${id} Setting name:${name}`);
  await ble.withPromises.write(id, SERVICE_UUID, CHARACTERISTIC_UUID, stringToBytes(`N${name}\n`));
  mgToast("Name changed.\nPlease wait for new name and reconnect");
  setTimeout(() => {
    doClose();
    clearDevice(id);
  }, 100);
}

function onSubmit() {
  console.log(`[DoDevice.onSubmit] newName:${newName.value}`);
  setName(newName.value);
}

function onReset() {
  console.log(`[DoDevice.onReset] newName:${newName.value}`);
  newName.value = props.device.name;
}


function onSpeedUpdate() {
  console.log(`[DoDevice.onSpeedUpdate] newSpeed:${speed.value}`);
  doBle(stringToBytes(`S${speed.value}\n`), (data) => {
    let r = bytesToString(data);
    console.log(`[DoDevice.onSpeedUpdate] r:${r}`);
    let res = r.match(/VFanny V(\d) T(\d) S(\d)\/(\d)/);
    // if (!res) {
    //   mgErrorToast("Invalid device\nDisconnecting.")
    // }
    // else {
    //   console.log(`[DoDevice.onSpeedUpdate] res:${JSON.stringify(res)}`);
    //   speed.value = Number(res[3]);
    // }
  });
}

///////// BLE Callbacks
let bleSuccessCb = undefined;
let bleErrorCb = undefined;
let bleTimeoutId = undefined;

function bleError(reason) {
  mgErrorToast("ERROR: " + reason);
  console.log(`[DoDevice.bleError] error:${reason}. Closing connection.`);
  doClose();
}


function onData(data) {
  // data received from BLE, have to parse it
  console.log(`[DoDevice.onData] data: '${bytesToString(data)}'`);
  let x = bleSuccessCb;
  bleSuccessCb = undefined;
  bleErrorCb = undefined;
  console.log(`[DoDevice.onData] bleTimeoutId:'${bleTimeoutId}'`);
  if (bleTimeoutId != undefined) {
    console.log(`[DoDevice.onData] Clearing timeout=${bleTimeoutId}`);
    clearTimeout(bleTimeoutId);
  }
  else console.log(`[DoDevice.onData] No timeout`);
  bleTimeoutId = undefined;
  if (x) x(data);
}

function onError(reason) {
  console.log(`[DoDevice.onError] Reason: '${JSON.stringify(reason)}'`);
  let x = bleErrorCb;
  bleSuccessCb = undefined;
  bleErrorCb = undefined;
  if (bleTimeoutId != undefined) clearTimeout(bleTimeoutId);
  bleTimeoutId = undefined;
  if (x) x(reason);
}


function waitResponse(successCb, errorCb = bleError, timeoutMs = 1000) {
  if (successCb) bleSuccessCb = successCb;
  if (errorCb) bleErrorCb = errorCb;
  if (timeoutMs != undefined) {
    bleTimeoutId = setTimeout(() => {
      onError("Timeout");
    }, timeoutMs);
    console.log(`[DoDevice.waitResponse] Set bleTimeoutId:'${bleTimeoutId}'`);
  }
}

async function doBle(data, successCb, errorCb, timeoutMs) {
  console.log(`[DoDevice.doBle] sending data`);
  waitResponse(successCb, errorCb, timeoutMs);
  await ble.withPromises.write(props.device.id, SERVICE_UUID, CHARACTERISTIC_UUID, data);
}


function checkFanny() {
  console.log(`[DoDevice.checkFanny] device: ${props.device.name}`);
  doBle(stringToBytes(`V\n`), (data) => {
    let r = bytesToString(data);
    console.log(`[DoDevice.checkFanny] r:${r}`);
    let res = r.match(/VFanny V(\d) T(\d) S(\d)\/(\d)/);
    if (!res) {
      mgErrorToast("Invalid device\nDisconnecting.")
      doClose();
    }
    else {
      console.log(`[DoDevice.checkFanny] res:${JSON.stringify(res)}`);
      fanName.value = props.device.fanName;
      speed.value = Number(res[3]);
      maxSpeed.value = Number(res[4]);
      newName.value = props.device.name;
    }
  });
}

async function connectCallback() {
  console.log(`[DoDevice.connectCallback] Connected`);
  isConnected.value = true;
  ble.startNotification(props.device.id, SERVICE_UUID, CHARACTERISTIC_UUID, onData, onError);
  checkFanny();
  // setName("FFF");
}

onUnmounted(() => {
  ble.disconnect(props.device.id, doClose);
});

function connectError(e) {
  console.log(`[DoDevice.connectError] Error:${JSON.stringify(e)}`);
  mgErrorToast(e.errorMessage);
  try {
    doClose();
    clearDevice(props.device.id);
  }
  catch (e) { };
}

onMounted(() => {
  console.log(`[DoDevice.onMounted] Connecting...`);
  ble.connect(props.device.id, connectCallback, connectError);
});
</script>

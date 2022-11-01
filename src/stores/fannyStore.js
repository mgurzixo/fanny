"use strict";

import {ref} from "vue"

let isDialogOpen=ref(false);

let devices = ref([]); // List of devices
let devicesById = {}; // set of devices

function makeDevices(){
  let res = [];
  for (let id of Object.keys(devicesById)) {
    res.push(devicesById[id])
  }
  let res1 = res.sort((d1, d2) => d2.rssi - d1.rssi)
  devices.value = res1;
}

function insertDevice(device) {
  devicesById[device.id] = device;
  makeDevices();
}

function clearDevices(){
  devicesById={};
  devices.value=[];
}

function clearDevice(deviceId){
  try{
  delete   devicesById[deviceId];
  }
  catch(e){};
  makeDevices();
}


export {isDialogOpen, devices, clearDevices, clearDevice, insertDevice};

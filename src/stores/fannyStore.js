"use strict";

import {ref} from "vue"

let isDialogOpen=ref(false);

let devices = ref([]); // List of devices
let devicesById = {}; // set of devices

function lruCmp(d1, d2) {
  // console.log(`[fannyStore.lruCmp] ${d1.lru} ${d2.lru}`);
  return (d2.lru) - (d1.lru);
};

function makeDevices(){
  let res = [];
  for (let id of Object.keys(devicesById)) {
    res.push(devicesById[id]);
  }
  // console.log(`[fannyStore.makeDevices]sorting:`)
  res.sort(lruCmp);
  devices.value = res;
  // console.log(`[fannyStore.makeDevices]res:`)
  // for(let i in res){
  //   console.log(`[fannyStore.makeDevices] ${res[i].name} ${res[i].lru}`);
  // }
}

// Use Lru, so that devices out of range but still in memory go to end of list
function updateLru(){
  for (let id of Object.keys(devicesById)) {
    devicesById[id].lru -= 10;
  }
  makeDevices();
  // console.log(`[fannyStore.updateLru]`);
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


export {isDialogOpen, devices, clearDevices, clearDevice, insertDevice, updateLru};

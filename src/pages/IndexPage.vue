<template>
  <q-page class="q-ma-sm column justify-start">
    <div class="q-pa-md" style="max-width: 500px">
    <q-input
      v-model="text1"
      filled
      type="textarea"
    />
  </div>
  <div class="row justify-start items-start self-start">
    <q-input v-model="text" label="Enter text:" outlined class="" />
  </div>
  <div class="row justify-start items-start">

  <q-btn class="q-my-md " color="primary" label="Primary" />
</div>
</q-page>

</template>

<script setup>
import {ref} from "vue";
let text=ref("Salut");
let text1=ref("Hello");
</script>

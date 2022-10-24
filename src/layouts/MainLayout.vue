<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated>
      <q-toolbar>
        <q-btn
        class="q-pa-none q-ma-none mg1"
            flat
            dense
            size="xl"
        icon="img:icons/computer-fan.svg" />

        <q-toolbar-title>
          Fanny
        </q-toolbar-title>

        <div>V0.0.1</div>
      </q-toolbar>
    </q-header>



    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup>
// import { defineComponent, ref } from 'vue';
import fanSvg from "assets/computer-fan.svg";



</script>

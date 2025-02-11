# fanny makefile

PROGRAMS=
.PHONY: all
all: $(PROGRAMS)

devandroid:
	quasar dev -m capacitor -T android

buildandroid:
	quasar build -m capacitor -T android --ide

clean :



#include <JeeLib.h>
#include <avr/sleep.h>
#include <OneWire.h>
#include <DallasTemperature.h>

#define NODEID 3
#define CHANNELGROUP 1

#define TEMPERATURE_PORT 3
#define TEMPERATURE_PIN TEMPERATURE_PORT + 3

#define SLEEPTIME 60

// Datastructure to transmit to master node
struct {
	byte nodeID;
	float temperature;
	int voltage;
	long counter;
} payload;

Port temperaturePort (TEMPERATURE_PORT);
OneWire oneWire(TEMPERATURE_PIN);
DallasTemperature sensors(&oneWire);

volatile bool adcDone;

// ADC completion interrupt
ISR(ADC_vect) { adcDone = true; }

// Watchdog timer..
ISR(WDT_vect) { Sleepy::watchdogEvent(); }

void setup()
{
	// Set div 2.. 8 mhz speed.
	/*cli();
	CLKPR = bit(CLKPCE);
	CLKPR = 1;
	sei();*/

	rf12_initialize(NODEID, RF12_868MHZ, CHANNELGROUP);
	rf12_control(0xC046); // set low-battery level to 2.8V i.s.o. 3.1V
	rf12_sleep(RF12_SLEEP);

	// Use the analog pin to power/unpower DS18B20 temp sensor
	temperaturePort.mode2(OUTPUT);
	temperaturePort.digiWrite2(HIGH);

	delay(10);
	sensors.begin();
	sensors.setResolution(TEMP_12_BIT);
	delay(10);
}

static float tempRead ()
{
	// Turn on sensor and give it a moment to stabilize
	temperaturePort.digiWrite2(HIGH);
	delay(10);

	// Request and read temperature:
	sensors.requestTemperatures();
	float temperature = sensors.getTempCByIndex(0);

	// Turn off sensor
	temperaturePort.digiWrite2(LOW);
	return temperature;
}

static int vccRead (byte count = 4)
{
	set_sleep_mode(SLEEP_MODE_ADC);
	ADMUX = bit(REFS0) | 14; // use VCC as AREF and internal bandgap as input
	bitSet(ADCSRA, ADIE);

	while (count-- > 0) {
		adcDone = false;
		while (!adcDone)
			sleep_mode();
	}
	bitClear(ADCSRA, ADIE);
	// convert ADC readings to fit in one byte, i.e. 20 mV steps:
	// 1.0V = 0, 1.8V = 40, 3.3V = 115, 5.0V = 200, 6.0V = 250
	// return (55U * 1024U) / (ADC + 1) - 50;
	return ADC;
}

void prepareSensorData()
{
	payload.nodeID = NODEID;
	payload.counter++;
	payload.temperature = tempRead();
	payload.voltage = vccRead();
}

void sendSensorData()
{
	rf12_sleep(RF12_WAKEUP);
	while (!rf12_canSend())
		rf12_recvDone();

	rf12_sendStart(0, &payload, sizeof payload);
	rf12_sendWait(1);
	rf12_sleep(RF12_SLEEP);
}

void loop()
{
	// Read sensors and transmit to master node
	prepareSensorData();
	sendSensorData();

	// Put microcontroller to sleep for x seconds
	Sleepy::loseSomeTime(SLEEPTIME * 1000);
}

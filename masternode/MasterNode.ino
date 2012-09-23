
#include <JeeLib.h>

// RADIO Setting
#define NODEID          1
#define CHANNELGROUP    1

// SR Pulses
#define SR_BIT_LENGTH   32
#define SR_HDR_MARK	    9000
#define SR_HDR_SPACE	4500
#define SR_BIT_MARK	    560
#define SR_ONE_SPACE	1600
#define SR_ZERO_SPACE	560
#define SR_RPT_SPACE	2250
#define SR_FIRSTBIT     0x80000000

// SR Command codes
#define SR_VOLUME_UP    0xA55A50AF
#define SR_VOLUME_DOWN  0xA55AD02F
#define SR_TOGGLE_PWR   0xA55A38C7
#define SR_INPUT_HDMI   0xA55A7A85

// Pin Settings
#define SR_PORT         2

// Sensor data (from slave nodes)
struct {
	byte nodeID;
	float temperature;
	int voltage;
	long counter;
} payload;

char serialData[80];
byte serialIndex = 0;

char *command;

Port srport(SR_PORT);

void setup()
{
	rf12_initialize(NODEID, RF12_868MHZ, CHANNELGROUP);

	srport.mode(OUTPUT);
	srport.digiWrite(HIGH);

	Serial.begin(57600);
	Serial.println("\n[master]");
}

void sendSRPulse(long microsecs)
{
	srport.digiWrite(LOW);
	delayMicroseconds(microsecs - 3);
	srport.digiWrite(HIGH);
}

void sendSRCommand(unsigned long data)
{
	sendSRPulse(SR_HDR_MARK);
	delayMicroseconds(SR_HDR_SPACE);
	
	for (int i = 0; i < SR_BIT_LENGTH; i++) {
	
		sendSRPulse(SR_BIT_MARK);
		
		if (data & SR_FIRSTBIT)
			delayMicroseconds(SR_ONE_SPACE);
		else
			delayMicroseconds(SR_ZERO_SPACE);
		
		data <<= 1;
	}
	
	sendSRPulse(SR_BIT_MARK);
}

void receiveRadio()
{
	if (rf12_recvDone() && rf12_crc == 0) {
		if (rf12_len == sizeof payload) {
			memcpy(&payload, (void*) rf12_data, sizeof payload);
			printSensorData();
		}
	}
}

void printSensorData()
{
	Serial.print("{\"nodeid\":");
	Serial.print(payload.nodeID);
	Serial.print(",\"temperature\":");
	Serial.print(payload.temperature);
	Serial.print(",\"voltage\":");
	Serial.print(payload.voltage);
	Serial.print(",\"counter\":");
	Serial.print(payload.counter);
	Serial.println("}");
}

void resetSerialBuffer()
{
	serialIndex = 0;
	serialData[serialIndex] = NULL;
}

void parseSerialBuffer()
{
	String buffer = String(serialData);
	
	if (buffer.startsWith("SR,VOLUP"))
		sendSRCommand(SR_VOLUME_UP);
	else if (buffer.startsWith("SR,VOLDOWN"))
		sendSRCommand(SR_VOLUME_DOWN);
	else if (buffer.startsWith("SR,POWER"))
		sendSRCommand(SR_TOGGLE_PWR);
	else if (buffer.startsWith("SR,HDMI"))
		sendSRCommand(SR_INPUT_HDMI);
}

void receiveSerial()
{
	while (Serial.available() > 0) {
		char aChar = Serial.read();

		if (aChar == '\n') {
			parseSerialBuffer();
			resetSerialBuffer();
		} else {
			serialData[serialIndex++] = aChar;
			serialData[serialIndex] = '\0';
		}

		if (serialIndex == 79)
			serialIndex = 0;
	}
}

void loop()
{
	receiveRadio();
	receiveSerial();
}

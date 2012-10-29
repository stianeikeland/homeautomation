Home automation
===============

My [Coffee/NodeJS][nodejs] + [0MQ][zeromq] home automation setup.
See my blog for more details: [blagg.tadkom.net][blagg]

It consists of multiple services connected via a bus (zeromq):

 - [Broker][broker] - Push/pull + pub/sub message hub. Message central.
 - [Logger][logger] - Logs sensor data to cosm.com
 - [Event-Triggers][triggers] - Triggers events based on certain sensor data situations
 - [MCU-Relay][mcurelay] - Microcontroller relay - receives sensor data from jeenodes
 - [Notification][notification] - Sends notifications to iOS devices (prowl) and to email
 - [Powercontrol][powercontrol] - Controls and receives events from 433 mhz receivers/transmitter (RFXtrx433)
 - [Heating][heating] - Time based thermostat service (Todo: PID + motion sensors)

Also contains some microcontroller-code for arduino-compatible controllers ([Jeenode][jeenode]) with RFM12b radios.

 - [MasterNode][masternode] - Receives sensors readings from slavenodes, controls Pioneer Home-Cinema Receiver via SR-bus. Acts as a simple serial bridge.
 - [SlaveNode][slavenode] - Sleeps, wakes once every minute, gather sensor data, transmits wirelessly to masternode.

Other hardware used:

 - [Raspberry Pi][raspberry] - I have everything running on this little linux capable ARM board. It's connected via serial/TTL to a [Jeenode][jeenode].
 - [RFXtrx433][rfxcom] - 433 mhz transceiver, from [RFXcom][rfxcom]. Controls Nexa power-relays, etc.
 - [Jeenode][jeenode] - Small arduino-compatible AVR boards with HopeRF rfm12b radios on them.

[nodejs]:http://nodejs.org/
[zeromq]:http://www.zeromq.org/
[rfxcom]:http://www.rfxcom.com/store/Transceivers/12103
[jeenode]:http://jeelabs.com/products/jeenode
[masternode]:https://github.com/stianeikeland/homeautomation/tree/master/microcontroller/masternode
[slavenode]:https://github.com/stianeikeland/homeautomation/tree/master/microcontroller/slavenode
[broker]:https://github.com/stianeikeland/homeautomation/tree/master/broker
[mcurelay]:https://github.com/stianeikeland/homeautomation/tree/master/services/mcu-relay
[heating]:https://github.com/stianeikeland/homeautomation/tree/master/services/heating
[powercontrol]:https://github.com/stianeikeland/homeautomation/tree/master/services/powercontrol
[notification]:https://github.com/stianeikeland/homeautomation/tree/master/services/notification
[logger]:https://github.com/stianeikeland/homeautomation/tree/master/services/logger
[triggers]:https://github.com/stianeikeland/homeautomation/tree/master/services/event-triggers
[raspberry]:http://raspberrypi.org/
[blagg]:http://blagg.tadkom.net/tag/homeautomation/
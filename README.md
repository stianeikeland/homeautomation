Home automation
===============

System for home automation based around:
- NodeJS (most of the services on the bus)
- ZeroMQ (message bus)

Also contains some microcontroller-code for arduino-compatible controllers with RFM12b radio.

[Broker](https://github.com/stianeikeland/homeautomation/tree/master/broker)
------
Simple message broker with two zeromq sockets. One push/pull (input) and one pub/sub (output). Other services can subscribe to the events they are interested in.

NodeJS/Coffee-script

[MCU-Relay](https://github.com/stianeikeland/homeautomation/tree/master/mcu-relay)
---------
Runs on a raspberry pi, connected to a microcontroller over serial/ttl. Receives messages sent by sensor-nodes (example temperature) and relays them to the message broker. Also receives (home cinema)-receiver events from the bus and relays them to the microcontroller.

NodeJS/Coffee-script

[MasterNode](https://github.com/stianeikeland/homeautomation/tree/master/masternode) (microcontroller)
------------
Code for Master Node - receives wireless messages from sensor-nodes. Controls home cinema receiver via it's pioneer SR bus.

[SlaveNode](https://github.com/stianeikeland/homeautomation/tree/master/slavenode) (microcontroller)
------------
Code for Slave/Sensor Node - battery powered and wireless. Spends most of the time sleeping, wakes up, reads sensors and transmits results to master node.

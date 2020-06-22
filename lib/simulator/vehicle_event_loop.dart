import 'dart:isolate';
import 'vehicle_data_generator.dart';
import 'vehicle_data_calculators.dart';
import 'dart:async';

void vehicleEventLoop(SendPort sendPort) {
  var generator = VehicleDataGenerator();
  var calculator = VehicleDataCalculator();
  var journeyId = generator.journeyId();

  // Open up a ReceivePort and send a reference to its sendPort back to the
  // main isolate. This is used as a basis for establishing bi-directional
  // message passing between the main and event isolates.
  var commPort = ReceivePort();
  sendPort.send(commPort.sendPort);

  // Wait for the current vehicle state to be passed in by the main isolate
  commPort.listen((data) {
    var state = data[2];
    var eventId = data[1];

    Timer.periodic(Duration(seconds: 1), (timer) {
      var info = data[0];
      var event = data[2];

      event.engineSpeed = calculator.engineSpeed(state);
      event.vehicleSpeed = calculator.vehicleSpeed(state);
      event.latitude = calculator.latitude(state);
      event.longitude = calculator.longitude(state);
      event.torqueAtTransmission = calculator.torque(state);
      event.fuelConsumedSinceRestart = calculator.fuelConsumed(state);
      event.fuelLevel = calculator.fuelLevel(info, state);
      event.journeyID = journeyId;
      event.autoID = info.autoID;
      event.eventID = eventId++;
      event.odometer = calculator.odometer(state);
      event.timestamp = DateTime.now();

      // Cache updated state for next iteration
      state = event;

      // Send event updates back to the main isolate
      sendPort.send(event);
    });
  });
}
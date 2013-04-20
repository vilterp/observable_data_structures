part of observable_datastructures;

/**
* some Stream utils.
*/
class Streams {

  Stream<dynamic> merge(List<Stream<dynamic>> streams) {
    var controller = new StreamController();
    int stillGoing = streams.length;
    streams.forEach((stream) {
      stream.listen(controller.add, onError: controller.addError, onDone: () {
        stillGoing--;
        if(stillGoing == 0) {
          controller.close();
        }
      });
    });
    return controller.stream;
  }

  Stream<MultiplexedStreamEvent> multiplex(Map<String,Stream> streams) {
    var controller = new StreamController();
    streams.forEach((name, stream) {
      stream.listen((evt) => controller.add(new MultiplexedDataEvent(name, evt)),
                    onError: (err) => controller.add(new MultiplexedErrorEvent(name, err)),
                    onDone: () => controller.add(new MultiplexedDoneEvent(name)));
    });
    return controller.stream;
  }

  Map<String,Stream> demultiplex(Stream<MultiplexedStreamEvent> multiplexed, List<String> streamNames) {
    var controllers = <String,StreamController>{};
    streamNames.forEach((name) => controllers[name] = new StreamController());
    multiplexed.listen((evt) {
      var controller = controllers[evt.streamName];
      // wish there was pattern matching :P
      if(evt is MultiplexedDataEvent) {
        controller.add((evt as MultiplexedDataEvent).data);
      } else if(evt is MultiplexedErrorEvent) {
        controller.addError((evt as MultiplexedErrorEvent).error);
      } else {
        controller.close();
      }
    });
    // shame there's no Map#map
    var result = <String,Stream>{};
    controllers.forEach((k,v) => result[k] = v.stream);
    return result;
  }

}

abstract class MultiplexedStreamEvent {
  String streamName;
  MultiplexedStreamEvent(this.streamName);
}

class MultiplexedDataEvent extends MultiplexedStreamEvent {
  dynamic data;
  MultiplexedDataEvent(String stream, this.data) : super(stream);
}

class MultiplexedErrorEvent extends MultiplexedStreamEvent {
  AsyncError error;
  MultiplexedErrorEvent(String stream, this.error) : super(stream);
}

class MultiplexedDoneEvent extends MultiplexedStreamEvent {
  MultiplexedDoneEvent(String stream) : super(stream);
}

import 'dart:async';

import 'package:accelerometertest/backends/gps_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../widgets/map_widget.dart';
import '../widgets/gps_auth_tile.dart';

abstract class TripRecorderBackend {
  void startRecording();

  void stopRecording();

  Future<bool> persistData(Modes travelMode);

  Stream<Location> locationStream();
}

class TripRecorderWidget extends StatefulWidget {
  final Modes mode;
  final Function exit;
  final Function recorderBuilder;

  TripRecorderWidget({
    @required this.mode,
    @required this.exit,
    @required this.recorderBuilder,
  });

  @override
  State<StatefulWidget> createState() => TripRecorderWidgetState();
}

class TripRecorderWidgetState extends State<TripRecorderWidget> {
  TripRecorderBackend recorder;
  DateTime createdTime;

  @override
  void initState() {
    super.initState();
    recorder = widget.recorderBuilder();
    recorder.startRecording();
    createdTime = DateTime.now();
  }

  Future<bool> onSave() async {
    recorder.stopRecording();
    return recorder.persistData(widget.mode);
  }

  Future<bool> onCancel() async {
    recorder.stopRecording();
    return true;
  }

  Widget noGPSPane() {
    return Column(mainAxisSize: MainAxisSize.max, children: [
      Container(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: Text('Enregistrement en cours',
              style: TextStyle(fontSize: 30.0))),
      Container(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
              'Début du trajet : ' +
                  createdTime.toString().split('.').first.split(' ').last,
              style: TextStyle(fontSize: 20.0))),
      Expanded(child: Center(child: Icon(widget.mode.iconData, size: 200))),
      GpsAuthTile(),
    ]);
  }

  Widget mainPane(BuildContext context) {
    return Consumer<GPSAuth>(
        builder: (context, auth, _) {
          if (auth.value == true) {
            return Column(children: [
              Expanded(child: MapWidget(recorder.locationStream())),
              GpsAuthTile(),
            ]);
          } else {
            return noGPSPane();
          }
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[TripRecorderWidget] building UI');
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Row(children: [
                Icon(widget.mode.iconData),
                Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(widget.mode.text))
              ]),
            ),
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: mainPane(context),
                  ),
                  ButtonBar(
                    children: <Widget>[
                      OutlineButton(child: Text('Simuler'), onPressed: () {}),
                      RaisedButton(
                        child: Text('Enregistrer ce trajet'),
                        color: Colors.blue,
                        onPressed: () => saveAndExit(context),
                      ),
                      OutlineButton(
                        child: Text('Effacer ce trajet'),
                        onPressed: () => cancelDialog(context),
                      ),
                    ],
                  )
                ])));
  }

  void cancelDialog(BuildContext context) {
    Widget cancelButton = FlatButton(
      child: Text("Non"),
      onPressed: () => Navigator.of(context).pop(),
    );
    Widget continueButton = FlatButton(
        child: Text("Oui, effacer."),
        onPressed: () {
          onCancel().then((value) {
            Navigator.of(context).pop(); // pop dialog
            widget.exit();
          });
        });
    AlertDialog alert = AlertDialog(
      title: Text("Confirmation"),
      content: Text("Voulez-vous vraiment effacer les données de ce trajet ?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void saveAndExit(BuildContext context) {
    AlertDialog alert = AlertDialog(
      title: Text("Enregistrement"),
      content: Text("Enregistrement des données..."),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
    onSave().then((value) {
      Navigator.of(context, rootNavigator: true).pop(); // pop dialog
      widget.exit();
    });
  }
}

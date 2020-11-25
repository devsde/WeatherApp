import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audio_cache.dart';

void main() => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int temperature;
  var minTemperatureForecast = new List(7);
  var maxTemperatureForecast = new List(7);
  var minTemperatureForecastInFah = new List(7);
  var maxTemperatureForecastInFah = new List(7);
  String location = 'Mumbai';
  int woeid = 12586539;
  String weather = 'clear';
  String abbreviation = '';
  var abbreviationForecast = new List(7);
  String errorMessage = '';
  int temperatureInFah;

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  Position _currentPosition;

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  void didChangeDependencies() async {
    super.didChangeDependencies();
    await fetchLocation();
    await fetchLocationDay();
  }

  @override
  void dispose() {}

  fetchSearch(String input) async {
    try {
      var searchResult = await http.get(searchApiUrl + input);
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result["title"];
        woeid = result["woeid"];
        errorMessage = '';
      });
    } catch (error) {
      setState(() {
        errorMessage =
            "Sorry, we don't have data about this city. Try another one.";
      });
    }
  }

  fetchLocation() async {
    var locationResult = await http.get(locationApiUrl + woeid.toString());
    var result = json.decode(locationResult.body);
    var consolidated_weather = result["consolidated_weather"];
    var data = consolidated_weather[0];

    setState(() {
      temperature = data["the_temp"].round();
      temperatureInFah = ((temperature * 9 / 5) + 32).round();
      weather = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbreviation = data["weather_state_abbr"];
      soundEffects();
    });
  }

  fetchLocationDay() async {
    var today = new DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(locationApiUrl +
          woeid.toString() +
          '/' +
          new DateFormat('y/M/d')
              .format(today.add(new Duration(days: i + 1)))
              .toString());
      var result = json.decode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data["min_temp"].round();
        minTemperatureForecastInFah[i] =
            ((minTemperatureForecast[i] * 9 / 5) + 32).round();
        maxTemperatureForecast[i] = data["max_temp"].round();
        maxTemperatureForecastInFah[i] =
            ((maxTemperatureForecast[i] * 9 / 5) + 32).round();

        abbreviationForecast[i] = data["weather_state_abbr"];
      });
    }
  }

  AudioPlayer advancedPlayerTh = new AudioPlayer();
  AudioPlayer advancedPlayerHr = new AudioPlayer();
  AudioPlayer advancedPlayerLr = new AudioPlayer();
  AudioPlayer advancedPlayerSh = new AudioPlayer();

  void soundEffects() {
    print(weather);
    if (sound) {
      if (weather == "thunderstorm" || weather == "heavycloud") {
        AudioCache playerTsHc = new AudioCache(fixedPlayer: advancedPlayerTh);

        playerTsHc.play('thunderstorm.wav');
      }
      if (weather == "lightrain") {
        final playerLr = AudioCache(fixedPlayer: advancedPlayerLr);
        playerLr.play('lightrain.wav');
      }

      if (weather == "heavyrain") {
        final playerHr = AudioCache(fixedPlayer: advancedPlayerHr);
        playerHr.play('heavyrain.wav');
      }
      if (weather == "showers") {
        final playerShowers = AudioCache(fixedPlayer: advancedPlayerSh);
        playerShowers.play('showers.mp3');
      }
    }
  }

  void onTextFieldSubmitted(String input) async {
    advancedPlayerTh.stop();
    advancedPlayerHr.stop();
    advancedPlayerLr.stop();
    advancedPlayerSh.stop();
    await fetchSearch(input);
    await fetchLocation();
    await fetchLocationDay();
  }

  _getCurrentLocation() {
    Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await Geolocator().placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];
      print(place.locality);
      onTextFieldSubmitted(place.locality);
    } catch (e) {
      print(e);
    }
  }

  bool sound = false;
  bool fah = false;

  Widget forecastElement(
      daysFromNow, abbreviation, minTemperature, maxTemperature) {
    var now = new DateTime.now();
    var oneDayFromNow = now.add(new Duration(days: daysFromNow));
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(205, 212, 228, 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Text(
                new DateFormat.E().format(oneDayFromNow),
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
              Text(
                new DateFormat.MMMd().format(oneDayFromNow),
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              abbreviation == null
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                      child: Image.network(
                        'https://www.metaweather.com/static/img/weather/png/$abbreviation.png',
                        width: 50,
                      ),
                    ),
              fah
                  ? Text(
                      'High: ' + maxTemperature.toString() + ' °F',
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    )
                  : Text(
                      'High: ' + maxTemperature.toString() + ' °C',
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    ),
              fah
                  ? Text(
                      'High: ' + minTemperature.toString() + ' °F',
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    )
                  : Text(
                      'Low: ' + minTemperature.toString() + ' °C',
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/$weather.png'),
              fit: BoxFit.cover,
              colorFilter: new ColorFilter.mode(
                  Colors.black.withOpacity(0.6), BlendMode.dstATop),
            ),
          ),
          child: temperature == null
              ? Center(child: CircularProgressIndicator())
              : Scaffold(
                  appBar: AppBar(
                    actions: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: GestureDetector(
                          onTap: () {
                            _getCurrentLocation();
                          },
                          child: Icon(Icons.location_city, size: 36.0),
                        ),
                      )
                    ],
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                  ),
                  drawer: Drawer(
                    child: Container(
                      color: Colors.grey[350],
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          CheckboxListTile(
                            title: Text("Sound"),
                            value: sound,
                            onChanged: (val) {
                              setState(() {
                                sound = val;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: Text("Fahrenheit"),
                            value: fah,
                            onChanged: (val) {
                              setState(() {
                                fah = val;
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                  resizeToAvoidBottomInset: false,
                  backgroundColor: Colors.transparent,
                  body: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          abbreviation == ""
                              ? Container()
                              : Center(
                                  child: Image.network(
                                    'https://www.metaweather.com/static/img/weather/png/$abbreviation.png',
                                    width: 100,
                                  ),
                                ),
                          Center(
                            child: fah
                                ? Text(
                                    temperatureInFah.toString() + ' °F',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 60.0),
                                  )
                                : Text(
                                    temperature.toString() + ' °C',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 60.0),
                                  ),
                          ),
                          Center(
                            child: Text(
                              location,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 40.0),
                            ),
                          ),
                        ],
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            for (var i = 0; i < 7; i++)
                              fah
                                  ? forecastElement(
                                      i + 1,
                                      abbreviationForecast[i],
                                      minTemperatureForecastInFah[i],
                                      maxTemperatureForecastInFah[i])
                                  : forecastElement(
                                      i + 1,
                                      abbreviationForecast[i],
                                      minTemperatureForecast[i],
                                      maxTemperatureForecast[i]),
                          ],
                        ),
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            width: 300,
                            child: TextField(
                              onSubmitted: (String input) {
                                onTextFieldSubmitted(input);
                              },
                              style:
                                  TextStyle(color: Colors.white, fontSize: 25),
                              decoration: InputDecoration(
                                hintText: 'Search another location...',
                                hintStyle: TextStyle(
                                    color: Colors.white, fontSize: 18.0),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.white),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 32.0, left: 32.0),
                            child: Text(errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize:
                                        Platform.isAndroid ? 15.0 : 20.0)),
                          )
                        ],
                      ),
                    ],
                  ),
                )),
    );
  }
}

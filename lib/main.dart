import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  await Hive.initFlutter();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Forecast',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => WeatherForecastScreen(),
        '/map': (context) => MapScreen(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/Weather.jpg', // Add your weather icon image here
              height: 150,
            ),
            SizedBox(height: 20),
            Text(
              'Discover the Weather\nin Your City',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Get to know your weather maps and\nradar precipitation forecast',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherForecastScreen extends StatefulWidget {
  @override
  _WeatherForecastScreenState createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  String city = '';
  String apiKey = 'bdd03ba3a8450f43f0faa54112df4ef7';
  Map<String, dynamic>? currentWeather;
  List<dynamic>? forecast;

  @override
  void initState() {
    super.initState();
    _loadLastCity();
  }

  void _loadLastCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      city = prefs.getString('city') ?? '';
    });
    if (city.isNotEmpty) {
      _fetchWeatherData(city);
    }
  }

  Future<void> _fetchWeatherData(String city) async {
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric'));
    final forecastResponse = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric'));

    if (response.statusCode == 200 && forecastResponse.statusCode == 200) {
      setState(() {
        currentWeather = json.decode(response.body);
        forecast = json.decode(forecastResponse.body)['list'];
        _saveData();
      });
    } else {
      setState(() {
        currentWeather = null;
        forecast = null;
      });
    }
  }

  void _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', city);

    var box = await Hive.openBox('weatherData');
    await box.put('currentWeather', currentWeather);
    await box.put('forecast', forecast);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weather Forecast',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        foregroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              Navigator.pushNamed(context, '/map');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter city name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                setState(() {
                  city = value;
                });
                _fetchWeatherData(city);
              },
            ),
            SizedBox(height: 20),
            if (currentWeather == null)
              Center(
                child: Text('No data available'),
              )
            else
              Column(
                children: [
                  Text(
                    'Current Weather in $city',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xff000000),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (currentWeather!['weather'] != null)
                              Image.network(
                                'https://openweathermap.org/img/wn/${currentWeather!['weather'][0]['icon']}@2x.png',
                                width: 50,
                                height: 50,
                              ),
                            SizedBox(width: 10),
                            Column(
                              children: [
                                Text(
                                  '${currentWeather!['main']['temp']}°C',
                                  style: TextStyle(fontSize: 24),
                                ),
                                Text(
                                  currentWeather!['weather'][0]['description'],
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Humidity: ${currentWeather!['main']['humidity']}%',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Wind Speed: ${currentWeather!['wind']['speed']} m/s',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            SizedBox(height: 20),
            forecast == null
                ? Text('No forecast available')
                : Expanded(
                    child: ListView.builder(
                      itemCount: forecast!.length,
                      itemBuilder: (context, index) {
                        final day = forecast![index];
                        return Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Image.network(
                              'https://openweathermap.org/img/wn/${day['weather'][0]['icon']}@2x.png',
                              width: 50,
                              height: 50,
                            ),
                            title: Text(
                              'Date: ${day['dt_txt']}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                'Temp: ${day['main']['temp']}°C - ${day['weather'][0]['description']}'),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(37.7749, -122.4194), // Default to San Francisco
          zoom: 10,
        ),
        onMapCreated: (controller) {
          _controller = controller;
        },
      ),
    );
  }
}

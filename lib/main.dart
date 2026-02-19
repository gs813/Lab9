import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/th_cities.dart';
import 'models/weather_models.dart';
import 'providers/weather_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WeatherProvider()..load(),
      child: const WeatherApp(),
    ),
  );
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TH Weather',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        fontFamily: 'Roboto',
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatelessWidget {
  const WeatherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WeatherProvider>();
    final items = thNorthernProvinces;
    final safeValue =
        items.contains(p.selected) ? p.selected : items.first;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Thailand Weather',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.wb_sunny)),
              Tab(icon: Icon(Icons.schedule)),
              Tab(icon: Icon(Icons.calendar_today)),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A237E),
                Color(0xFF3949AB),
                Color(0xFF5C6BC0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<WeatherProvider>().refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _GlassContainer(
                    child: DropdownButtonFormField<THCity>(
                      value: safeValue,
                      dropdownColor: Colors.white,
                      decoration: const InputDecoration(
                        labelText: 'เลือกเมือง',
                        border: OutlineInputBorder(),
                      ),
                      items: items
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (c) {
                        if (c != null) {
                          context
                              .read<WeatherProvider>()
                              .selectCity(c);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (p.loading)
                    const Center(
                        child:
                            CircularProgressIndicator(color: Colors.white)),
                  if (!p.loading &&
                      p.error == null &&
                      p.bundle != null)
                    SizedBox(
                      height: 600,
                      child: TabBarView(
                        children: [
                          _NowTab(
                              bundle: p.bundle!,
                              cityName: p.selected.name),
                          _HourlyTab(bundle: p.bundle!),
                          _DailyTab(bundle: p.bundle!),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NowTab extends StatelessWidget {
  final WeatherBundle bundle;
  final String cityName;

  const _NowTab(
      {required this.bundle, required this.cityName});

  @override
  Widget build(BuildContext context) {
    final c = bundle.current;

    return _GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(cityName,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          Text(
            emojiForCode(c.weatherCode, c.isDay),
            style: const TextStyle(fontSize: 70),
          ),
          const SizedBox(height: 10),
          Text(
            '${c.temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            weatherCodeToText(c.weatherCode),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: [
              _InfoColumn("Humidity",
                  "${c.humidity.toStringAsFixed(0)}%"),
              _InfoColumn("Wind",
                  "${c.windSpeed.toStringAsFixed(1)} m/s"),
              _InfoColumn("Feels",
                  "${c.apparentTemperature.toStringAsFixed(1)}°C"),
            ],
          )
        ],
      ),
    );
  }
}

class _HourlyTab extends StatelessWidget {
  final WeatherBundle bundle;
  const _HourlyTab({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final next24 = bundle.hourly.take(24).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: next24.length,
      itemBuilder: (context, i) {
        final h = next24[i];
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          child: _GlassContainer(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                Text('${h.time.hour}:00',
                    style:
                        const TextStyle(color: Colors.white)),
                Text(
                  emojiForCode(h.weatherCode, true),
                  style: const TextStyle(fontSize: 30),
                ),
                Text('${h.temperature}°C',
                    style:
                        const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyTab extends StatelessWidget {
  final WeatherBundle bundle;
  const _DailyTab({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final days = bundle.daily;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final d = days[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _GlassContainer(
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  weatherCodeToText(d.weatherCode),
                  style:
                      const TextStyle(color: Colors.white),
                ),
                Text(
                  '${d.tMax}° / ${d.tMin}°',
                  style:
                      const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;

  const _InfoColumn(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value,
            style:
                const TextStyle(color: Colors.white)),
      ],
    );
  }
}

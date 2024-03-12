import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const MyApp());
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTHORIZED,
  AUTH_NOT_GRANTED,
  DATA_ADDED,
  DATA_DELETED,
  DATA_NOT_ADDED,
  DATA_NOT_DELETED,
  STEPS_READY,
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;

  static final types = [
    HealthDataType.WEIGHT,
    // HealthDataType.STEPS,
    // HealthDataType.HEIGHT,
    // HealthDataType.BLOOD_GLUCOSE,
    // HealthDataType.WORKOUT,
    // HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    // HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    // HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_IN_BED,
    // HealthDataType.SLEEP_SESSION,
  ];

  final permissions = types.map((e) => HealthDataAccess.READ_WRITE).toList();
  HealthFactory health = HealthFactory(useHealthConnectIfAvailable: true);

  Future authorized() async {
    await Permission.activityRecognition.request();
    await Permission.location.request();

    bool auth = false;

    try {
      auth = await health.requestAuthorization(types, permissions: permissions);
    } catch (e) {
      print(e);
    }

    setState(() {
      _state = auth ? AppState.AUTHORIZED : AppState.AUTH_NOT_GRANTED;
    });
  }

  void fetchData() async {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(hours: 24));
    _healthDataList.clear();

    try {
      List<HealthDataPoint> healthData =
          await health.getHealthDataFromTypes(yesterday, now, types);
      _healthDataList.addAll(
          (healthData.length < 100) ? healthData : healthData.sublist(0, 100));
    } catch (e) {
      print("エラーだけ");
    }

    setState(() {
      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);
    });
    print(_healthDataList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(onPressed: authorized, child: const Text("認証する")),
            TextButton(onPressed: fetchData, child: const Text("データを取得")),
            if (_healthDataList.length == 0) const Text("データがありません。")

            // SfCartesianChart(
            //     primaryXAxis: CategoryAxis(),
            //     // Chart title
            //     title: ChartTitle(text: 'Half yearly sales analysis'),
            //     // Enable legend
            //     legend: Legend(isVisible: true),
            //     // Enable tooltip
            //     tooltipBehavior: TooltipBehavior(enable: true),
            //     series: <CartesianSeries<HealthDataPoint, String>>[
            //       LineSeries<HealthDataPoint, String>(
            //           dataSource: _healthDataList,
            //           xValueMapper: (HealthDataPoint healthData, _) => sales.year,
            //           yValueMapper: (HealthDataPoint healthData, _) => sales.sales,
            //           name: 'Sales',
            //           // Enable data label
            //           dataLabelSettings: DataLabelSettings(isVisible: true))
            //     ]),
          ],
        ),
      ),
    );
  }
}

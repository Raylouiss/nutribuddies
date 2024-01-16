import 'package:flutter/material.dart';
import 'package:nutribuddies/constant/colors.dart';
import 'package:nutribuddies/models/kids.dart';
import 'package:nutribuddies/screens/add_meal.dart';
import 'package:nutribuddies/models/tracker.dart';
import 'package:nutribuddies/models/user.dart';
import 'package:nutribuddies/screens/error_screen.dart';
import 'package:nutribuddies/services/database.dart';
import 'package:nutribuddies/services/food_tracker.dart';
import 'package:nutribuddies/widgets/loading.dart';
import 'package:provider/provider.dart';
import 'package:nutribuddies/models/nutritions.dart';
import 'package:uuid/uuid.dart';

import '../models/meals.dart';
import '../services/general.dart';

class Tracker extends StatefulWidget {
  const Tracker({Key? key}) : super(key: key);

  @override
  State<Tracker> createState() => _TrackerState();
}

class _TrackerState extends State<Tracker> {
  DateTime date = DateTime.now();
  late String kidUid;
  bool loading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _initializeKidUid();
  }

  Future<void> _initializeKidUid() async {
    final Users? users = Provider.of<Users?>(context, listen: false);
    final FoodTrackerService foodTracker = FoodTrackerService();
    setState(() => loading = true);
    final firstKid = await foodTracker.getFirstKid(users!.uid);
    if (firstKid == null) {
      setState(() => isError = true);
      setState(() => loading = false);
      return;
    } else {
      setState(() {
        kidUid = firstKid.uid;
      });
    }
    // generate tracker uid
    final String trackerUid = const Uuid().v4();

    // check if uid unique
    bool flagTracker =
        await DatabaseService(uid: users.uid).isTrackerUidUnique(trackerUid);
    while (!flagTracker) {
      flagTracker =
          await DatabaseService(uid: users.uid).isTrackerUidUnique(trackerUid);
    }

    DateTime today = DateTime.now();
    Nutritions currentNutritions = Nutritions(
        calories: 0, proteins: 0, fiber: 0, fats: 0, carbs: 0, iron: 0);

    List<Meals> meals = [];

    await DatabaseService(uid: '').updateTrackerData(
      trackerUid: trackerUid,
      kidUid: firstKid.uid,
      date: DateTime(today.year, today.month, today.day),
      currentNutritions: currentNutritions,
      meals: meals,
    );

    setState(() => loading = false);
    setState(() => isError = false);
  }

  @override
  Widget build(BuildContext context) {
    final Users? users = Provider.of<Users?>(context);
    return loading
        ? const Loading()
        : isError
            ? ErrorReloadWidget(
                errorMessage: 'An error occurred. Please try again.',
                onReloadPressed: () {
                  _initializeKidUid();
                },
              )
            : Scaffold(
                backgroundColor: Colors.blue[50],
                body: StreamProvider<Trackers?>.value(
                  value: DatabaseService(uid: users!.uid).tracker(kidUid, date),
                  initialData: null,
                  catchError: (context, error) {
                    return null;
                  },
                  child: TrackerContent(
                    updateDate: updateDate,
                    updateKidUid: updateKidUid,
                    kidUid: kidUid,
                  ),
                ),
              );
  }

  void updateDate(DateTime newDate) {
    setState(() {
      date = newDate;
    });
  }

  void updateKidUid(String newKidUid) {
    setState(() {
      kidUid = newKidUid;
    });
  }
}

class TrackerContent extends StatefulWidget {
  final Function(String) updateKidUid;
  final Function(DateTime) updateDate;
  final String kidUid;
  const TrackerContent(
      {super.key,
      required this.updateKidUid,
      required this.updateDate,
      required this.kidUid});

  @override
  State<TrackerContent> createState() => _TrackerContentState();
}

class _TrackerContentState extends State<TrackerContent> {
  DateTime date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final GeneralService general = GeneralService();
    final FoodTrackerService foodTracker = FoodTrackerService();
    final tracker = Provider.of<Trackers?>(context);
    final users = Provider.of<Users?>(context);
    Nutritions currentNutritions = Nutritions(
        calories: 10, proteins: 0, fiber: 0, fats: 0, carbs: 0, iron: 0);
    Nutritions maxNutritions = Nutritions(
        calories: 100,
        proteins: 100,
        fiber: 100,
        fats: 100,
        carbs: 100,
        iron: 100);

    if (tracker != null) {
      currentNutritions = tracker.currentNutritions;
      maxNutritions = tracker.maxNutritions;
    }

    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Stack(
            children: [
              Image.asset('assets/Tracker/Rectangle_12308.png'),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.04,
                left: MediaQuery.of(context).size.width * 0.32,
                height: MediaQuery.of(context).size.height * 0.05,
                width: MediaQuery.of(context).size.width * 0.38,
                child: FutureBuilder<List<Kids>>(
                  future: DatabaseService(uid: '').getKidsList(users!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No kids available');
                    } else {
                      List<Kids> kidsList = snapshot.data!;
                      Future<Kids?> firstKidFuture =
                          foodTracker.getFirstKid(users.uid);
                      String? selectedValue;

                      return FutureBuilder<Kids?>(
                          future: firstKidFuture,
                          builder: (context, kidSnapshot) {
                            if (kidSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (kidSnapshot.hasError) {
                              return Text('Error: ${kidSnapshot.error}');
                            } else {
                              Kids? firstKid = kidSnapshot.data;
                              selectedValue = firstKid?.uid;
                              return DropdownButtonFormField<String>(
                                value: selectedValue,
                                onChanged: (String? newValue) {
                                  widget.updateKidUid(newValue ?? '');
                                  setState(() {
                                    selectedValue = newValue;
                                  });
                                },
                                items: kidsList.map<DropdownMenuItem<String>>(
                                  (Kids kid) {
                                    return DropdownMenuItem<String>(
                                      value: kid.uid,
                                      child: Text(kid.displayName as String),
                                    );
                                  },
                                ).toList(),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: primaryContainer,
                                  contentPadding: EdgeInsets.fromLTRB(
                                      MediaQuery.of(context).size.width * 0.04,
                                      0,
                                      MediaQuery.of(context).size.width * 0.03,
                                      0),
                                  border: InputBorder.none,
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(16)),
                                    borderSide:
                                        BorderSide(width: 1, color: outline),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(16)),
                                    borderSide:
                                        BorderSide(width: 1, color: outline),
                                  ),
                                ),
                                style: const TextStyle(
                                  color: onPrimaryContainer,
                                ),
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.black),
                                elevation: 16,
                                dropdownColor: primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              );
                            }
                          });
                    }
                  },
                ),
              ),
            ],
          ),
          Container(
            alignment: AlignmentDirectional.centerStart,
            padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.11,
                MediaQuery.of(context).size.height * 0.02,
                MediaQuery.of(context).size.width * 0.11,
                MediaQuery.of(context).size.height * 0.01),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: ElevatedButton(
                  onPressed: () {
                    foodTracker.selectDateTracker(context, date, (picked) {
                      widget.updateDate(picked);
                      setState(() {
                        date = picked;
                      });
                    }, users.uid, widget.kidUid);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                    minimumSize: Size(double.infinity,
                        MediaQuery.of(context).size.height * 0.06),
                    backgroundColor: primary,
                    foregroundColor: onPrimary,
                    side: const BorderSide(color: outline, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.02,
                      ),
                      Text(
                        general.formatDate(date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.03,
              ),
              const Text(
                "Nutritions",
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: black,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.15),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width * 0.8,
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.21,
                          width: MediaQuery.of(context).size.width * 0.36,
                          decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFAE4),
                                    Color(0xFFF9ECA5)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  offset: const Offset(2, 4),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]),
                          padding: EdgeInsets.fromLTRB(
                              MediaQuery.of(context).size.width * 0.035,
                              MediaQuery.of(context).size.height * 0.015,
                              MediaQuery.of(context).size.width * 0.035,
                              MediaQuery.of(context).size.height * 0.015),
                          child: Stack(
                            children: [
                              Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Image.asset(
                                      'assets/Tracker/Maskgroup(1).png')),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.11,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.055,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: secondary40,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${(currentNutritions.calories / maxNutritions.calories * 100).toStringAsFixed(0)}%',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: black,
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      const Text(
                                        'Calories',
                                        style: TextStyle(
                                          color: ontertiaryContainer,
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.045),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'Total',
                                      style: TextStyle(
                                        color: ontertiaryContainer,
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(
                                          '${(currentNutritions.calories).toStringAsFixed(0)} ',
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '/ ${(maxNutritions.calories).toStringAsFixed(0)} kcal',
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.015,
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.06,
                          width: MediaQuery.of(context).size.width * 0.36,
                          decoration: BoxDecoration(
                              color: tertiary70,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  offset: const Offset(2, 4),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]),
                          padding: EdgeInsets.fromLTRB(
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.008,
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.003),
                          child: Row(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.11,
                                height:
                                    MediaQuery.of(context).size.height * 0.055,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secondary40,
                                ),
                                child: Center(
                                  child: Text(
                                    '${(currentNutritions.fiber / maxNutritions.fiber * 100).toStringAsFixed(0)}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: black,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.01,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'Fiber',
                                      style: TextStyle(
                                        color: ontertiaryContainer,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(
                                          '${(currentNutritions.fiber).toStringAsFixed(0)} ',
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '/ ${(maxNutritions.fiber).toStringAsFixed(0)} gr',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 8,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.06,
                          width: MediaQuery.of(context).size.width * 0.36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFAE4),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.4),
                                offset: const Offset(2, 4),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.008,
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.003),
                          child: Row(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.11,
                                height:
                                    MediaQuery.of(context).size.height * 0.055,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secondary40,
                                ),
                                child: Center(
                                  child: Text(
                                    '${(currentNutritions.carbs / maxNutritions.carbs * 100).toStringAsFixed(0)}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: black,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.01,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'Carbs',
                                      style: TextStyle(
                                        color: ontertiaryContainer,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(
                                          '${(currentNutritions.carbs).toStringAsFixed(0)} ',
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '/ ${(maxNutritions.carbs).toStringAsFixed(0)} gr',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 8,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.015,
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.06,
                          width: MediaQuery.of(context).size.width * 0.36,
                          decoration: BoxDecoration(
                              color: const Color(0xFFFCF3C7),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  offset: const Offset(2, 4),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]),
                          padding: EdgeInsets.fromLTRB(
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.008,
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.003),
                          child: Row(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.11,
                                height:
                                    MediaQuery.of(context).size.height * 0.055,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secondary40,
                                ),
                                child: Center(
                                  child: Text(
                                    '${(currentNutritions.proteins / maxNutritions.proteins * 100).toStringAsFixed(0)}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: black,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.01,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'Proteins',
                                      style: TextStyle(
                                        color: ontertiaryContainer,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(
                                          '${(currentNutritions.proteins).toStringAsFixed(0)} ',
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '/ ${(maxNutritions.proteins).toStringAsFixed(0)}  gr',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 8,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.015,
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.06,
                          width: MediaQuery.of(context).size.width * 0.36,
                          decoration: BoxDecoration(
                              color: tertiary80,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  offset: const Offset(2, 4),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]),
                          padding: EdgeInsets.fromLTRB(
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.008,
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.003),
                          child: Row(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.11,
                                height:
                                    MediaQuery.of(context).size.height * 0.055,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secondary40,
                                ),
                                child: Center(
                                  child: Text(
                                    '${(currentNutritions.fats / maxNutritions.fats * 100).toStringAsFixed(0)}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: black,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.01,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'Fats',
                                      style: TextStyle(
                                        color: ontertiaryContainer,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(
                                          '${(currentNutritions.fats).toStringAsFixed(0)} ',
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '/ ${(maxNutritions.fats).toStringAsFixed(0)} gr',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 8,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.015,
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.06,
                          width: MediaQuery.of(context).size.width * 0.36,
                          decoration: BoxDecoration(
                              color: tertiary70,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  offset: const Offset(2, 4),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]),
                          padding: EdgeInsets.fromLTRB(
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.008,
                              MediaQuery.of(context).size.width * 0.03,
                              MediaQuery.of(context).size.height * 0.003),
                          child: Row(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.11,
                                height:
                                    MediaQuery.of(context).size.height * 0.055,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secondary40,
                                ),
                                child: Center(
                                  child: Text(
                                    '${(currentNutritions.iron / maxNutritions.iron * 100).toStringAsFixed(0)}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: black,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.01,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'iron',
                                      style: TextStyle(
                                        color: ontertiaryContainer,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(
                                          '${(currentNutritions.iron).toStringAsFixed(0)} ',
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '/ ${(maxNutritions.iron).toStringAsFixed(0)} mg',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: ontertiaryContainer,
                                            fontFamily: 'Poppins',
                                            fontSize: 8,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Row(
                children: [
                  const Text(
                    "Kid's Meals",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.15),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddMeal(
                                    tracker: tracker,
                                  )));
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      backgroundColor: primary,
                      foregroundColor: white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015,
                        ),
                        const Text(
                          'Add Meal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Column(
                children: tracker?.meals != null
                    ? List.generate(tracker!.meals.length, (index) {
                        Meals meal = tracker.meals[index];
                        return Column(
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height * 0.09,
                              width: MediaQuery.of(context).size.width * 0.77,
                              decoration: BoxDecoration(
                                  color: primaryContainer,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.4),
                                      offset: const Offset(2, 4),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ]),
                              padding: EdgeInsets.fromLTRB(
                                  MediaQuery.of(context).size.width * 0.05,
                                  MediaQuery.of(context).size.height * 0.01,
                                  MediaQuery.of(context).size.width * 0.02,
                                  MediaQuery.of(context).size.height * 0.01),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.15,
                                    height: MediaQuery.of(context).size.height *
                                        0.075,
                                    padding: EdgeInsets.symmetric(
                                        vertical:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    child: Image.network(
                                      meal.food.thumbnailUrl ?? '',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.025,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          meal.food.foodName,
                                          style: const TextStyle(
                                            color: black,
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(meal.food.nutritions.calories * meal.amount).toStringAsFixed(0)} kcal ',
                                        style: const TextStyle(
                                          color: primary40,
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        '${meal.amount} x (${meal.food.portion})',
                                        style: const TextStyle(
                                          color: outline,
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.black,
                                    ),
                                    onPressed: () {
                                      _warningEditModal(
                                          context, meal, tracker, index);
                                    },
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.025,
                            )
                          ],
                        );
                      })
                    : [],
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _warningEditModal(
      BuildContext context, Meals record, Trackers tracker, int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: WarningEditMealModal(
              record: record,
              index: index,
              tracker: tracker,
            ),
          );
        });
  }
}

class WarningDeleteMealModal extends StatelessWidget {
  final Meals record;
  final Trackers tracker;
  final int index;

  const WarningDeleteMealModal(
      {super.key,
      required this.tracker,
      required this.index,
      required this.record});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: background,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.19,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                  0, MediaQuery.of(context).size.width * 0.06, 0, 0),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Warning",
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 0.06,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.035,
                  ),
                  Column(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                            textAlign: TextAlign.start,
                            softWrap: true,
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text:
                                      'Are you sure want to delete your kid’s meal: ',
                                  style: TextStyle(
                                    color: onSurfaceVariant,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                    letterSpacing: 0.25,
                                  ),
                                ),
                                TextSpan(
                                  text: record.food.foodName,
                                  style: const TextStyle(
                                    color: onSurfaceVariant,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                    letterSpacing: 0.25,
                                  ),
                                ),
                                const TextSpan(
                                  text: '?',
                                  style: TextStyle(
                                    color: onSurfaceVariant,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                    letterSpacing: 0.25,
                                  ),
                                ),
                              ],
                            )),
                      )
                    ],
                  )
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.325,
                  height: MediaQuery.of(context).size.height * 0.05,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: background,
                      foregroundColor: primary,
                      elevation: 0.0,
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: outline,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        height: 0.10,
                        letterSpacing: 0.10,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.02,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: MediaQuery.of(context).size.height * 0.05,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Color(0x4C000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await DatabaseService(uid: '')
                          .deleteMealFromTracker(tracker.uid, index);
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      backgroundColor: error,
                      foregroundColor: onPrimary,
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        height: 0.10,
                        letterSpacing: 0.10,
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class WarningEditMealModal extends StatelessWidget {
  final Meals record;
  final Trackers tracker;
  final int index;

  const WarningEditMealModal(
      {super.key,
      required this.record,
      required this.tracker,
      required this.index});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: white,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.19,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                  0, MediaQuery.of(context).size.width * 0.06, 0, 0),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Edit Meal",
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 0.06,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.045,
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Do you want to edit your kid's meal?",
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 0.10,
                        letterSpacing: 0.25,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  )
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.325,
                  height: MediaQuery.of(context).size.height * 0.05,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Color(0x4C000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      _editMealModal(context, record);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      backgroundColor: primary,
                      foregroundColor: onPrimary,
                    ),
                    child: const Text(
                      "Edit portion",
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        height: 0.10,
                        letterSpacing: 0.10,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.02,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: MediaQuery.of(context).size.height * 0.05,
                  decoration: ShapeDecoration(
                    color: surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: error),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      _warningDeleteModal(
                        context,
                        record,
                        tracker,
                        index,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      backgroundColor: background,
                      foregroundColor: primary,
                      side: const BorderSide(color: error, width: 1),
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        color: error,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        height: 0.10,
                        letterSpacing: 0.10,
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _warningDeleteModal(
      BuildContext context, Meals record, Trackers tracker, int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: WarningDeleteMealModal(
              record: record,
              tracker: tracker,
              index: index,
            ),
          );
        });
  }

  void _editMealModal(BuildContext context, Meals record) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child:
                editMealModal(record: record, tracker: tracker, index: index),
          );
        });
  }
}

// ignore: camel_case_types
class editMealModal extends StatefulWidget {
  final Meals record;
  final Trackers tracker;
  final int index;

  const editMealModal(
      {super.key,
      required this.record,
      required this.tracker,
      required this.index});

  @override
  // ignore: library_private_types_in_public_api
  _editMealModalState createState() => _editMealModalState();
}

// ignore: camel_case_types
class _editMealModalState extends State<editMealModal> {
  int counter = 1;

  void _incrementCounter() {
    setState(() {
      counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      if (counter != 0) {
        counter--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: white,
      content: SizedBox(
        height: 268,
        width: 369,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 150,
                            height: 24,
                            child: Text(
                              'Edit Meal',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 0.09,
                                letterSpacing: 0.15,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          SizedBox(
                              width: 200,
                              child: Text(
                                widget.record.food.foodName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  height: 0.05,
                                ),
                                overflow: TextOverflow.visible,
                              )),
                        ],
                      ),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Image.network(
                          widget.record.food.thumbnailUrl ?? '',
                          fit: BoxFit.cover,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Portion: ${widget.record.food.portion}",
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Color(0xFF5674A7),
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        height: 0.13,
                        letterSpacing: 0.50,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Column(
                        children: [
                          const SizedBox(
                            width: 65,
                            child: Text(
                              "Calories",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF74747E),
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 0.16,
                                letterSpacing: 0.50,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(top: 15),
                            width: 65,
                            child: Text(
                              "${widget.record.food.nutritions.calories} kcal",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF5674A7),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 0.10,
                                letterSpacing: 0.10,
                              ),
                            ),
                          )
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(
                            width: 65,
                            child: Text(
                              "Carbs",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF74747E),
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 0.16,
                                letterSpacing: 0.50,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(top: 15),
                            width: 65,
                            child: Text(
                              "${widget.record.food.nutritions.carbs} gr",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF5674A7),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 0.10,
                                letterSpacing: 0.10,
                              ),
                            ),
                          )
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(
                            width: 65,
                            child: Text(
                              "Proteins",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF74747E),
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 0.16,
                                letterSpacing: 0.50,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(top: 15),
                            width: 65,
                            child: Text(
                              "${widget.record.food.nutritions.proteins} gr",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF5674A7),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 0.10,
                                letterSpacing: 0.10,
                              ),
                            ),
                          )
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(
                            width: 65,
                            child: Text(
                              "Fats",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF74747E),
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 0.16,
                                letterSpacing: 0.50,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(top: 15),
                            width: 65,
                            child: Text(
                              "${widget.record.food.nutritions.fats} gr",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF5674A7),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 0.10,
                                letterSpacing: 0.10,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    height: 40,
                    width: 299,
                    decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(40),
                        color: const Color(0x00fafafa),
                        border: Border.all(color: primary, width: 1)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_rounded),
                          color: primary,
                          onPressed: () {
                            _decrementCounter();
                          },
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            "$counter",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              height: 0.06,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded),
                          color: primary,
                          onPressed: () {
                            _incrementCounter();
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 66,
                  ),
                  Container(
                    width: 95,
                    height: 32,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF9F9F9),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            width: 1, color: Color(0xFF74747E)),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100.0),
                        ),
                        backgroundColor: background,
                        foregroundColor: primary,
                        side: const BorderSide(color: outline, width: 1),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Color(0xFF5674A7),
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          height: 0.13,
                          letterSpacing: 0.50,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Container(
                    width: 75,
                    height: 32,
                    decoration: BoxDecoration(
                        color: black,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(20.0)),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Saving algorithm
                        await DatabaseService(uid: '').editMealInTracker(
                            widget.tracker.uid,
                            widget.index,
                            widget.record.food,
                            counter);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100.0),
                        ),
                        backgroundColor: primary,
                        foregroundColor: onPrimary,
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: white,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          height: 0.13,
                          letterSpacing: 0.50,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

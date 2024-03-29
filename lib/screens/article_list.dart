import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutribuddies/constant/colors.dart';
import 'package:nutribuddies/models/article.dart';
import 'package:nutribuddies/models/user.dart';
import 'package:nutribuddies/services/debouncer.dart';
import 'package:provider/provider.dart';
import 'package:nutribuddies/services/database.dart';

class ArticleList extends StatefulWidget {
  const ArticleList({Key? key}) : super(key: key);
  @override
  State<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<ArticleList>
    with TickerProviderStateMixin {
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  late TabController _tabController;
  List<String> selectedTopic = [];
  List<String> topics = [
    "All Topics",
    "Parenting",
    "Kids' Nutrition",
    "Kids' Lifestyle",
    "Kids' Health",
    "Kids' Diet",
    "Cooking"
  ];
  List<Article> articles = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    selectedTopic = ["All Topics"];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Users? users = Provider.of<Users?>(context);

    Future<List<Article>> getListOfArticlesFiltered(
        String searchQuery, List<String> selectedTopics) async {
      List<Article> articlesList = [];

      QuerySnapshot querySnapshot =
          await DatabaseService(uid: '').articleCollection.get();

      for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        Article article = Article(
          uid: data['uid'] ?? '',
          title: data['title'],
          date: data['date'],
          topics: List<String>.from(data['topics'] ?? []),
          imageUrl: data['imageUrl'],
          content: data['content'],
        );
        // Check if any selected topic is present in the article's topics
        for (String topic in selectedTopics) {
          if (article.title.toLowerCase().contains(searchQuery.toLowerCase()) &&
              topic == "All Topics") {
            articlesList.add(article);
          } else if (article.title
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) &&
              article.topics.contains(topic) &&
              !articlesList.contains(article)) {
            articlesList.add(article);
            break; // No need to continue checking topics if one is found
          }
        }
      }

      // Sort the articlesList by date
      articlesList.sort((a, b) => a.date.compareTo(b.date));

      return articlesList;
    }

    Future<void> loadData(String searchQuery) async {
      List<Article> data = await getListOfArticlesFiltered(
          searchController.text,
          (users!.topicsInterest.isEmpty) ? topics : users.topicsInterest);
      setState(() {
        articles = data;
      });
    }

    return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          shadowColor: Colors.transparent,
          toolbarHeight: 110,
          title: SizedBox(
            height: MediaQuery.of(context).size.height * 0.065,
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                _debouncer.run(() {
                  loadData(value);
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search articles...",
                border: InputBorder.none,
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: outline, width: 2.0),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: outline, width: 2.0),
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            unselectedLabelColor: primary,
            labelColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: primary,
            ),
            tabs: [
              Tab(
                child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: primary,
                          width: 1,
                        )),
                    child: const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'For You',
                        style: TextStyle(
                          // color: Colors.white,
                          // fontSize: 32,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.10,
                        ),
                      ),
                    )),
              ),
              Tab(
                child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: primary,
                          width: 1,
                        )),
                    child: const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Latest',
                        style: TextStyle(
                          // color: Colors.white,
                          // fontSize: 32,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.10,
                        ),
                      ),
                    )),
              ),
              Container(
                decoration: (selectedTopic[0] == 'All Topics')
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: primary,
                          width: 1,
                        ),
                      )
                    : BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: primary,
                          width: 1,
                        ),
                        color: primary,
                      ),
                child: DropdownButton<String?>(
                  value: selectedTopic[0],
                  onChanged: (value) {
                    setState(() {
                      selectedTopic[0] = value!;
                    });
                  },
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.03,
                    right: MediaQuery.of(context).size.width * 0.015,
                  ),
                  underline: Container(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: selectedTopic[0] == 'All Topics'
                        ? primary
                        : Colors.white,
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return topics
                        .map(
                          (e) => Text(
                            e,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedTopic[0] == 'All Topics'
                                  ? primary
                                  : Colors.white,
                            ),
                          ),
                        )
                        .toList();
                  },
                  isExpanded: true,
                  alignment: Alignment.center,
                  items: topics
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            // overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: primary,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // ignore: avoid_unnecessary_containers
            Container(
              child: FutureBuilder<List<Article>>(
                future: getListOfArticlesFiltered(
                    searchController.text, selectedTopic),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<Article> articleRecords = snapshot.data!;
                    return ListView(
                        children: articleRecords.map(
                      (record) {
                        return Container(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.08,
                              right: MediaQuery.of(context).size.width * 0.08,
                            ),
                            margin: EdgeInsets.only(
                                top:
                                    MediaQuery.of(context).size.height * 0.0125,
                                bottom: MediaQuery.of(context).size.height *
                                    0.0125),
                            child: InkWell(
                              onTap: () {
                                _articleViewPage(context, record);
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.77,
                                decoration: BoxDecoration(
                                  color: surfaceBright,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10)),
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
                                  MediaQuery.of(context).size.width * 0.05,
                                  MediaQuery.of(context).size.height * 0.01,
                                  MediaQuery.of(context).size.width * 0.02,
                                  MediaQuery.of(context).size.height * 0.01,
                                ),
                                margin: EdgeInsets.only(
                                    bottom: MediaQuery.of(context).size.height *
                                        0.001),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.225,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.11,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: outline,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: FittedBox(
                                        fit: BoxFit.fitHeight,
                                        child: Image.asset(record.imageUrl),
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
                                        Text(
                                          DateFormat('yyyy-MM-dd')
                                              .format(record.date.toDate()),
                                          style: const TextStyle(
                                            color: outline,
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.0025),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          child: Text(
                                            record.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.1,
                                                height: 1.25),
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.0075),
                                        Row(
                                          children: [
                                            for (int i = 0;
                                                i < record.topics.length;
                                                i++) ...[
                                              if (i == record.topics.length - 1)
                                                Text(
                                                  "#${record.topics[i]}",
                                                  style: const TextStyle(
                                                    color: Color(0xFF5674A7),
                                                    fontSize: 11,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1,
                                                    letterSpacing: 0.50,
                                                  ),
                                                ),
                                              if (i != record.topics.length - 1)
                                                Text(
                                                  "#${record.topics[i]} ",
                                                  style: const TextStyle(
                                                    color: Color(0xFF5674A7),
                                                    fontSize: 11,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1,
                                                    letterSpacing: 0.50,
                                                  ),
                                                ),
                                            ]
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ));
                      },
                    ).toList());
                  }
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Article>>(
                future: getListOfArticlesFiltered(
                    searchController.text, selectedTopic),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<Article> articleRecords = snapshot.data!;
                    return ListView(
                        children: articleRecords.map(
                      (record) {
                        return Container(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.08,
                              right: MediaQuery.of(context).size.width * 0.08,
                            ),
                            margin: EdgeInsets.only(
                                top:
                                    MediaQuery.of(context).size.height * 0.0125,
                                bottom: MediaQuery.of(context).size.height *
                                    0.0125),
                            child: InkWell(
                              onTap: () {
                                _articleViewPage(context, record);
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.77,
                                decoration: BoxDecoration(
                                  color: surfaceBright,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10)),
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
                                  MediaQuery.of(context).size.width * 0.05,
                                  MediaQuery.of(context).size.height * 0.01,
                                  MediaQuery.of(context).size.width * 0.02,
                                  MediaQuery.of(context).size.height * 0.01,
                                ),
                                margin: EdgeInsets.only(
                                    bottom: MediaQuery.of(context).size.height *
                                        0.001),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.225,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.11,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: outline,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: FittedBox(
                                        fit: BoxFit.fitHeight,
                                        child: Image.asset(record.imageUrl),
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
                                        Text(
                                          DateFormat('yyyy-MM-dd')
                                              .format(record.date.toDate()),
                                          style: const TextStyle(
                                            color: outline,
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.0025),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          child: Text(
                                            record.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.1,
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.0075),
                                        Row(
                                          children: [
                                            for (int i = 0;
                                                i < record.topics.length;
                                                i++) ...[
                                              if (i == record.topics.length - 1)
                                                Text(
                                                  "#${record.topics[i]}",
                                                  style: const TextStyle(
                                                    color: Color(0xFF5674A7),
                                                    fontSize: 11,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1,
                                                    letterSpacing: 0.50,
                                                  ),
                                                ),
                                              if (i != record.topics.length - 1)
                                                Text(
                                                  "#${record.topics[i]} ",
                                                  style: const TextStyle(
                                                    color: Color(0xFF5674A7),
                                                    fontSize: 11,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1,
                                                    letterSpacing: 0.50,
                                                  ),
                                                ),
                                            ]
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ));
                      },
                    ).toList());
                  }
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Article>>(
                future: getListOfArticlesFiltered(
                    searchController.text, selectedTopic),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<Article> articleRecords = snapshot.data!;
                    return ListView(
                        children: articleRecords.map(
                      (record) {
                        return Container(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.08,
                              right: MediaQuery.of(context).size.width * 0.08,
                            ),
                            margin: EdgeInsets.only(
                                top:
                                    MediaQuery.of(context).size.height * 0.0125,
                                bottom: MediaQuery.of(context).size.height *
                                    0.0125),
                            child: InkWell(
                              onTap: () {
                                _articleViewPage(context, record);
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.77,
                                decoration: BoxDecoration(
                                  color: surfaceBright,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10)),
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
                                  MediaQuery.of(context).size.width * 0.05,
                                  MediaQuery.of(context).size.height * 0.01,
                                  MediaQuery.of(context).size.width * 0.02,
                                  MediaQuery.of(context).size.height * 0.01,
                                ),
                                margin: EdgeInsets.only(
                                    bottom: MediaQuery.of(context).size.height *
                                        0.001),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.225,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.11,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: outline,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: FittedBox(
                                        fit: BoxFit.fitHeight,
                                        child: Image.asset(record.imageUrl),
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
                                        Text(
                                          DateFormat('yyyy-MM-dd')
                                              .format(record.date.toDate()),
                                          style: const TextStyle(
                                            color: outline,
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.0025),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          child: Text(
                                            record.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.1,
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.0075),
                                        Row(
                                          children: [
                                            for (int i = 0;
                                                i < record.topics.length;
                                                i++) ...[
                                              if (i == record.topics.length - 1)
                                                Text(
                                                  "#${record.topics[i]}",
                                                  style: const TextStyle(
                                                    color: Color(0xFF5674A7),
                                                    fontSize: 11,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1,
                                                    letterSpacing: 0.50,
                                                  ),
                                                ),
                                              if (i != record.topics.length - 1)
                                                Text(
                                                  "#${record.topics[i]} ",
                                                  style: const TextStyle(
                                                    color: Color(0xFF5674A7),
                                                    fontSize: 11,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1,
                                                    letterSpacing: 0.50,
                                                  ),
                                                ),
                                            ]
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ));
                      },
                    ).toList());
                  }
                },
              ),
            ),
          ],
        ));
  }

  void _articleViewPage(BuildContext context, Article record) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ArticleView(record: record)));
  }
}

class ArticleView extends StatefulWidget {
  final Article record;

  const ArticleView({Key? key, required this.record}) : super(key: key);

  @override
  State<ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends State<ArticleView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        toolbarHeight: 110,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Article',
          style: TextStyle(
            color: black,
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
        elevation: 0.0,
        backgroundColor: background,
        foregroundColor: black,
      ),
      body: Container(
          padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.08,
              right: MediaQuery.of(context).size.width * 0.08,
              bottom: MediaQuery.of(context).size.width * 0.07),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.015,
                    bottom: MediaQuery.of(context).size.width * 0.025,
                  ),
                  child: Text(
                    widget.record.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.025),
                  child: Text(
                    DateFormat.yMMMMd('en_US')
                        .format(widget.record.date.toDate()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: outline,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.025),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Image.asset(widget.record.imageUrl),
                ),
                Text(
                  widget.record.content.replaceAll("\\n", "\n"),
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

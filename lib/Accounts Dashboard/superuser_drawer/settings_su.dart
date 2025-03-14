import 'package:attendance_app/hover_extensions.dart';
import 'package:flutter/material.dart';

class SettingsSU extends StatefulWidget {
  const SettingsSU({super.key});

  @override
  State<SettingsSU> createState() => _SettingsSUState();
}

class _SettingsSUState extends State<SettingsSU> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width / 40),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Personal Information",
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width / 50,
                    color: Color.fromARGB(255, 11, 55, 99),
                    fontFamily: "BL"),
              ),
              Divider(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 5.5,
                    height: MediaQuery.of(context).size.width / 5,
                    child: Column(
                      children: [
                        Spacer(),
                        CircleAvatar(
                          radius: MediaQuery.of(context).size.width / 15,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.person,
                            size: MediaQuery.of(context).size.width / 12,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.width / 40,
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: MediaQuery.of(context).size.width / 40,
                            width: MediaQuery.of(context).size.width / 8,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 11, 55, 99),
                              borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.width / 150),
                            ),
                            child: Center(
                              child: Text(
                                "Edit Profile",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 80,
                                    color: Colors.white,
                                    fontFamily: "R"),
                              ),
                            ),
                          ),
                        ).showCursorOnHover,
                      ],
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.width/5,
                    width: MediaQuery.of(context).size.width/1.75,
                    child: Column(
                      children: [
                        Spacer(),
                        Row(
                          children: [
                            Column(
                              children: [
                                Text("First Name",
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width / 70,
                                        color: Colors.black,
                                        fontFamily: "R")),
                                SizedBox(
                                  height: MediaQuery.of(context).size.width / 100,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 6,
                                  color: Colors.white,
                                  child: TextField(
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width / 90,
                                        color: Colors.black,
                                        fontFamily: "R"),
                                    decoration: InputDecoration(
                                      hintText: "First Name",
                                      hintStyle: TextStyle(
                                          fontSize:
                                              MediaQuery.of(context).size.width / 90,
                                          color: Colors.grey,
                                          fontFamily: "R"),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width / 150),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 50,
                            ),
                            Column(
                              children: [
                                Text("Middle Name",
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width / 70,
                                        color: Colors.black,
                                        fontFamily: "R")),
                                SizedBox(
                                  height: MediaQuery.of(context).size.width / 100,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 6,
                                  color: Colors.white,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Middle Name",
                                      hintStyle: TextStyle(
                                          fontSize:
                                              MediaQuery.of(context).size.width / 90,
                                          color: Colors.grey,
                                          fontFamily: "R"),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width / 150),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 50,
                            ),
                            Column(
                              children: [
                                Text("Last Name",
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width / 70,
                                        color: Colors.black,
                                        fontFamily: "R")),
                                SizedBox(
                                  height: MediaQuery.of(context).size.width / 100,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 6,
                                  color: Colors.white,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Last Name",
                                      hintStyle: TextStyle(
                                          fontSize:
                                              MediaQuery.of(context).size.width / 90,
                                          color: Colors.grey,
                                          fontFamily: "R"),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width / 150),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.width/50,),
                        Row(
                          children: [
                            Column(
                              children: [
                                Text("Suffix",
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width / 70,
                                        color: Colors.black,
                                        fontFamily: "R")),
                                SizedBox(
                                  height: MediaQuery.of(context).size.width / 100,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 6,
                                  color: Colors.white,
                                  child: TextField(
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width / 90,
                                        color: Colors.black,
                                        fontFamily: "R"),
                                    decoration: InputDecoration(
                                      hintText: "Suffix",
                                      hintStyle: TextStyle(
                                          fontSize:
                                              MediaQuery.of(context).size.width / 90,
                                          color: Colors.grey,
                                          fontFamily: "R"),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width / 150),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 50,
                            ),
                            Column(
                              children: [
                                Text("Sex",
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width / 70,
                                        color: Colors.black,
                                        fontFamily: "R")),
                                SizedBox(
                                  height: MediaQuery.of(context).size.width / 100,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 6,
                                  color: Colors.white,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Sex",
                                      hintStyle: TextStyle(
                                          fontSize:
                                              MediaQuery.of(context).size.width / 90,
                                          color: Colors.grey,
                                          fontFamily: "R"),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width / 150),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 50,
                            ),
                            Column(
                              children: [
                                Text("Citizenship",
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width / 70,
                                        color: Colors.black,
                                        fontFamily: "R")),
                                SizedBox(
                                  height: MediaQuery.of(context).size.width / 100,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 6,
                                  color: Colors.white,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Citizenship",
                                      hintStyle: TextStyle(
                                          fontSize:
                                              MediaQuery.of(context).size.width / 90,
                                          color: Colors.grey,
                                          fontFamily: "R"),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width / 150),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

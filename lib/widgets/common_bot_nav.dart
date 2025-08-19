import 'package:flutter/material.dart';

PreferredSizeWidget buildCreateFoodAppBar(placeholder) {
  return AppBar(
    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    centerTitle: true,
    title: Text(
      placeholder,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    ),
  );
}
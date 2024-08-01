import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelectButton extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPressed;

  const DateSelectButton({
    Key? key,
    required this.selectedDate,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Added padding around the button
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16), // Increased padding inside the button
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed to spaceBetween for better distribution
          children: [
            Text(
              'Log Date',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white),
                SizedBox(width: 12), // Increased space between icon and date
                Text(
                  DateFormat('MMM d, yyyy').format(selectedDate),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
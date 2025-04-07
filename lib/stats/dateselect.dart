import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelectButton extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPressed;

  const DateSelectButton({
    super.key,
    required this.selectedDate,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Added padding around the button
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // Increased padding inside the button
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed to spaceBetween for better distribution
          children: [
            const Text(
              'Log Date',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white),
                const SizedBox(width: 12), // Increased space between icon and date
                Text(
                  DateFormat('MMM d, yyyy').format(selectedDate),
                  style: const TextStyle(
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
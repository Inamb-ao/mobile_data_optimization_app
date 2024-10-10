import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;  // The text label of the button
  final VoidCallback onPressed;  // The function to execute when the button is pressed
  final Color? buttonColor;  // Optional: Button color
  final Color? textColor;  // Optional: Text color
  final double? fontSize;  // Optional: Text font size

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.buttonColor = Colors.blue,  // Default button color is blue
    this.textColor = Colors.white,  // Default text color is white
    this.fontSize = 16.0,  // Default font size is 16.0
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,  // Callback for button press
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,  // Button background color
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),  // Padding for the button
        textStyle: TextStyle(fontSize: fontSize),  // Text style (font size)
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor),  // Text color
      ),
    );
  }
}

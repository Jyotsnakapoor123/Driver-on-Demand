import 'package:flutter/material.dart';

class Booking {
  final String bookingId;
  final String pickupAddress;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final int hours;
  final int totalFare;
  final String status;

  Booking({
    required this.bookingId,
    required this.pickupAddress,
    required this.selectedDate,
    required this.selectedTime,
    required this.hours,
    required this.totalFare,
    this.status = 'Confirmed',
  });
}

class BookingStore {
  static final List<Booking> bookings = [];

  static void addBooking(Booking booking) {
    bookings.add(booking);
  }
}
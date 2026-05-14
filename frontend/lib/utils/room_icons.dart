import 'package:flutter/material.dart';
import '../models/room.dart';

class RoomIconOption {
  const RoomIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const roomIconOptions = [
  RoomIconOption(key: 'room', label: 'Room', icon: Icons.meeting_room_outlined),
  RoomIconOption(key: 'kitchen', label: 'Kitchen', icon: Icons.kitchen),
  RoomIconOption(key: 'bathroom', label: 'Bathroom', icon: Icons.bathtub),
  RoomIconOption(key: 'toilet', label: 'Toilet', icon: Icons.wc),
  RoomIconOption(key: 'bedroom', label: 'Bedroom', icon: Icons.bed),
  RoomIconOption(key: 'living', label: 'Living', icon: Icons.weekend),
  RoomIconOption(key: 'garden', label: 'Garden', icon: Icons.yard),
  RoomIconOption(
    key: 'laundry',
    label: 'Laundry',
    icon: Icons.local_laundry_service,
  ),
  RoomIconOption(key: 'garage', label: 'Garage', icon: Icons.garage_outlined),
  RoomIconOption(key: 'office', label: 'Office', icon: Icons.desk_outlined),
];

RoomIconOption roomIconOptionForKey(String key) {
  final normalized = key.trim().toLowerCase();
  for (final option in roomIconOptions) {
    if (option.key == normalized) return option;
  }
  return roomIconOptions.first;
}

IconData iconForRoom(Room room) {
  final configured = room.icon.trim();
  if (configured.isNotEmpty) return roomIconOptionForKey(configured).icon;

  final name = room.name.toLowerCase();
  if (name.contains('kitchen')) return Icons.kitchen;
  if (name.contains('toilet') || name.contains('wc')) return Icons.wc;
  if (name.contains('bath')) return Icons.bathtub;
  if (name.contains('bed')) return Icons.bed;
  if (name.contains('living')) return Icons.weekend;
  if (name.contains('garden')) return Icons.yard;
  if (name.contains('laundry')) return Icons.local_laundry_service;
  if (name.contains('garage')) return Icons.garage_outlined;
  if (name.contains('office')) return Icons.desk_outlined;
  return Icons.meeting_room_outlined;
}

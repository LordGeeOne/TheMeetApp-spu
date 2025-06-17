import 'package:flutter/foundation.dart';

class SafeButton {
  final String id;
  final String name;
  final String type;
  final String action;
  
  SafeButton({
    required this.id,
    required this.name,
    required this.type,
    required this.action,
  });
  
  factory SafeButton.fromMap(Map<String, dynamic> map) {
    return SafeButton(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      action: map['action'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'action': action,
    };
  }
  
  SafeButton copyWith({
    String? id,
    String? name,
    String? type,
    String? action,
  }) {
    return SafeButton(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      action: action ?? this.action,
    );
  }
}
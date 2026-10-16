import 'package:flutter/material.dart';

import '../../rider/notifications_screen.dart';
import '../../rider/profile_screen.dart';
import '../../rider/ride_history_screen.dart';

// The old screens the new app still opens, until their stages replace them: activity
// and account (6). This file goes with them.

Future<void> openLegacyNotifications(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );

Widget legacyActivityTab() => const RideHistoryScreen();

Widget legacyAccountTab() => const ProfileScreen();

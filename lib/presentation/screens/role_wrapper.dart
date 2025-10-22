import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/screens/guest/guest_home.dart';
import 'package:linux_test2/presentation/screens/customer/customer_home.dart';
import 'package:linux_test2/presentation/screens/admin/admin_home.dart';
import 'package:linux_test2/presentation/screens/courier/courier_home.dart';

class RoleBasedWrapper extends StatelessWidget {
  const RoleBasedWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    if (user == null) {
      print('→ Showing GuestHome');
      return GuestHome();
    }

    switch (user.role) {
      case 'admin':
        return AdminHome();
      case 'courier':
        return CourierHome();
      case 'customer':
      default:
        print('→ Showing CustomerHome');
        return CustomerHome();
    }
  }
}
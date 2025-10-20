import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/models/brew.dart';
import 'package:linux_test2/screens/home/brew_tile.dart';

class BrewList extends StatefulWidget {
  const BrewList({super.key});

  @override
  State<BrewList> createState() => _BrewListState();
}

class _BrewListState extends State<BrewList> {
  @override
  Widget build(BuildContext context) {
    final brews = Provider.of<List<Brew>?>(context) ?? [];
    if (brews != null) {
      for (var brew in brews) {
        print('Name: ${brew.name}');
        print('Sugars: ${brew.sugars}');
        print('Strength: ${brew.strength}');
        print('---');
      }
    } else {
      print('No brews data available');
    }

    if (brews == null) {
      return const Center(child: Text('No brews available'));
    }

    if (brews.isEmpty) {
      return const Center(child: Text('No brews found'));
    }

    return ListView.builder(
      itemCount: brews.length,
      itemBuilder: (context, index) {
        return BrewTile(brew: brews[index]);
      },
    );
  }
}

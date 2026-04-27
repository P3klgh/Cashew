import 'package:budget/colors.dart';
import 'package:budget/pages/appliancesPage.dart';
import 'package:budget/pages/cookingRosterPage.dart';
import 'package:budget/pages/groceryListsPage.dart';
import 'package:budget/widgets/householdFeatureCard.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/functions.dart';
import 'package:flutter/material.dart';

class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  State<HouseholdPage> createState() => HouseholdPageState();
}

class HouseholdPageState extends State<HouseholdPage> {
  void scrollToTop() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            surfaceTintColor: Colors.transparent,
            floating: true,
            snap: true,
            title: const Text(
              'Household',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: false,
            automaticallyImplyLeading: false,
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              start: 16,
              end: 16,
              top: 8,
              bottom: getBottomInsetOfFAB(context) + 16,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: enableDoubleColumn(context) ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildListDelegate([
                HouseholdFeatureCard(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Cooking Roster',
                  description: 'Assign cooking duties and plan meals for the week.',
                  color: const Color(0xFFE87721),
                  onTap: () => pushRoute(context, const CookingRosterPage()),
                ),
                HouseholdFeatureCard(
                  icon: Icons.shopping_cart_rounded,
                  title: 'Grocery Lists',
                  description: 'Manage shopping lists with recurring items.',
                  color: const Color(0xFF3DAE6B),
                  onTap: () => pushRoute(context, const GroceryListsPage()),
                ),
                HouseholdFeatureCard(
                  icon: Icons.build_rounded,
                  title: 'Maintenance',
                  description: 'Track appliance service schedules and get reminders.',
                  color: const Color(0xFF5C6BC0),
                  onTap: () => pushRoute(context, const AppliancesPage()),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

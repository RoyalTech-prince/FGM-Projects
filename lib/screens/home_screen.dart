import 'package:flutter/material.dart';
import 'package:full_gospel_hymnal/providers/hymn_provider.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/screens/lyrics_screen.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});

  @override
Widget build(BuildContext context) {
  // Access the theme defined in the provider
  final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor, // Switches Red/Black/White
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
            child: SearchBarWidget(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              decoration: BoxDecoration(
                // As per the theme
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
            
              ),
              child: const HymnListView(),
            ),
          ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFD32F2F),
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      items: const[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
      ],
      onTap: (index){
        print("Ready to move!!!");
      },
    ),
  );
 }
}

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) {
        // Update search results as user types
        context.read<HymnProvider>().search(value);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Search by Title or by number',
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  context.read<HymnProvider>().search('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class HymnListView extends StatelessWidget {
  const HymnListView({super.key});

  @override
  Widget build(BuildContext context) {
    final hymnProvider = context.watch<HymnProvider>();

    if (hymnProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
    }

    if (hymnProvider.hymns.isEmpty) {
      return const Center(child: Text("No hymns found!!"));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: hymnProvider.hymns.length,
      separatorBuilder: (context, index) => const Divider(indent: 70, endIndent: 20),
      itemBuilder: (context, index) {
        final hymn = hymnProvider.hymns[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFD32F2F),
            child: Text("${hymn.number}", style: const TextStyle(color: Colors.white)),
          ),
          title: Text(
            hymn.titleEn,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(hymn.titleFr, style: const TextStyle(fontStyle: FontStyle.italic)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LyricsScreen(hymn: hymn),
              ),
            );
          },
        );
      },
    );
  }
}
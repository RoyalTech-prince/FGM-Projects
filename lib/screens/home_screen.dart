import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/hymn_provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/lyrics_screen.dart';
import 'package:full_gospel_hymnal/screens/settings_screen.dart';
import 'package:full_gospel_hymnal/utils/app_strings.dart';
import 'package:full_gospel_hymnal/screens/favorites_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:full_gospel_hymnal/utils/update_checker.dart';


// ─────────────────────────────────────────────────────────────────────────────
// FluidPagePhysics
//
// UNCHANGED. Custom scroll physics for the PageView that delivers three
// behaviours: free 1:1 scroll, one page per gesture, hard edge lock, and a
// speed-sensitive smart commit on release. None of this was touched.
// ─────────────────────────────────────────────────────────────────────────────

class FluidPagePhysics extends ScrollPhysics {
  const FluidPagePhysics({super.parent});

  @override
  FluidPagePhysics applyTo(ScrollPhysics? ancestor) {
    return FluidPagePhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // True dead ends — screen must not move at all.
    if (position.pixels <= position.minScrollExtent && offset < 0) return 0;
    if (position.pixels >= position.maxScrollExtent && offset > 0) return 0;

    final double viewport = position.viewportDimension;
    final double startPage = (position.pixels / viewport).roundToDouble();
    final double lowerBound = (startPage - 1) * viewport;
    final double upperBound = (startPage + 1) * viewport;

    final double projected = position.pixels + offset;

    if (projected < lowerBound) {
      return lowerBound - position.pixels;
    }
    if (projected > upperBound) {
      return upperBound - position.pixels;
    }
    return offset;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.minScrollExtent) {
      return value - position.minScrollExtent;
    }
    if (value > position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    final double page = position.pixels / position.viewportDimension;

    int targetPage;

    if (velocity.abs() > 300) {
      targetPage = velocity < 0 ? page.ceil() : page.floor();
    } else {
      final double fraction = page - page.truncate();
      if (fraction > 0.35) {
        targetPage = page.truncate() + 1;
      } else if (fraction < -0.35) {
        targetPage = page.truncate() - 1;
      } else {
        targetPage = page.round();
      }
    }

    final int pageCount =
        (position.maxScrollExtent / position.viewportDimension).round() + 1;
    targetPage = targetPage.clamp(0, pageCount - 1);

    final double targetPixels = targetPage * position.viewportDimension;

    if ((targetPixels - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }

    return SpringSimulation(
      const SpringDescription(
        mass: 1.0,
        stiffness: 600.0,
        damping: 38.0,
      ),
      position.pixels,
      targetPixels,
      velocity,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}


// ─────────────────────────────────────────────────────────────────────────────
// ElasticTextStretch
//
// Tiny immutable value describing the current text-stretch state:
//   • scaleX     : 1.0 = no stretch, >1.0 = stretched horizontally.
//   • alignment  : anchor point the stretch grows away from (opposite the
//                  drag direction), so the anchored side of each line of
//                  text stays visually fixed.
// ─────────────────────────────────────────────────────────────────────────────

class ElasticTextStretch {
  final double scaleX;
  final Alignment alignment;
  const ElasticTextStretch(this.scaleX, this.alignment);

  static const none = ElasticTextStretch(1.0, Alignment.center);
}


// ─────────────────────────────────────────────────────────────────────────────
// ElasticTextProvider
//
// Plain InheritedWidget (NOT InheritedNotifier) — it only ever hands down a
// reference to a ValueNotifier and never itself triggers a rebuild
// (updateShouldNotify always false). Widgets that actually want to react to
// the live stretch value wrap themselves in a ValueListenableBuilder using
// the notifier obtained here, so only those small widgets rebuild on every
// drag frame — not the whole screen.
// ─────────────────────────────────────────────────────────────────────────────

class ElasticTextProvider extends InheritedWidget {
  final ValueNotifier<ElasticTextStretch> notifier;

  const ElasticTextProvider({
    super.key,
    required this.notifier,
    required super.child,
  });

  static ValueNotifier<ElasticTextStretch>? of(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<ElasticTextProvider>();
    final widget = element?.widget as ElasticTextProvider?;
    return widget?.notifier;
  }

  @override
  bool updateShouldNotify(covariant ElasticTextProvider oldWidget) => false;
}


// ─────────────────────────────────────────────────────────────────────────────
// StretchableText
//
// Drop-in replacement for Text that subscribes to the nearest
// ElasticTextProvider (if any) and applies a horizontal-only stretch via a
// Matrix4 transform, anchored at the stretch's current alignment. Only this
// small widget rebuilds when the stretch value changes — cheap.
// ─────────────────────────────────────────────────────────────────────────────

class StretchableText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const StretchableText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final notifier = ElasticTextProvider.of(context);
    final textWidget = Text(text, style: style);

    if (notifier == null) return textWidget;

    return ValueListenableBuilder<ElasticTextStretch>(
      valueListenable: notifier,
      builder: (context, stretch, child) {
        if (stretch.scaleX == 1.0) return child!;
        return Transform(
          transform: Matrix4.diagonal3Values(stretch.scaleX, 1.0, 1.0),
          alignment: stretch.alignment,
          child: child,
        );
      },
      child: textWidget,
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  // ── Page state ─────────────────────────────────────────────────────────────

  int _currentIndex = 0;
  late PageController _pageController;

  // ── Edge elastic text stretch ───────────────────────────────────────────────
  //
  // When the user drags on the first or last screen, the PageView itself
  // stays frozen (FluidPagePhysics returns 0 offset at edges). For tactile
  // feedback, only the hymn list's text briefly stretches horizontally —
  // the card, its margins, icons, and layout never move.
  //
  // IMPORTANT — performance: none of this uses setState. Every update goes
  // through `_textStretchNotifier`, a ValueNotifier consumed only by
  // StretchableText widgets via ValueListenableBuilder. That means a drag
  // at the edge no longer rebuilds the BottomNavigationBar, theme lookups,
  // or the rest of the screen on every frame — only the few words of text
  // actually stretching repaint. This also removes the dropped-frame
  // gesture interference that was making swipe-back from Settings to
  // Favorites unreliable.
  //
  // _elasticOffset      : live drag distance (px) accumulated at an edge.
  // _atEdge             : true while the current drag is at a boundary screen.
  // _elasticController  : drives the spring-back animation on finger release.
  // _elasticAnimation   : tween from the release offset back to 0.

  final ValueNotifier<ElasticTextStretch> _textStretchNotifier =
      ValueNotifier(ElasticTextStretch.none);

  late AnimationController _elasticController;
  late Animation<double> _elasticAnimation;
  double _elasticOffset = 0.0;
  Alignment _elasticAlignment = Alignment.center;
  bool _atEdge = false;

  // How much the stretched edge of the text is allowed to grow, in actual
  // pixels — kept small since this now only affects glyph width, not the
  // whole layout. Tune to taste.
  static const double _maxStretchPixels = 6.0;
  // Pixel offset at which the stretch reaches its maximum (matches the
  // existing ±30px clamp on _elasticOffset).
  static const double _maxElasticOffset = 30.0;

  late final List<Widget> _screens;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _currentIndex);

    // Controller used only for the spring-back animation after an edge drag.
    _elasticController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _screens = [
      const HymnListBody(),
      const FavoritesScreen(),
      const SettingsScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.checkForUpdates(_showUpdateDialog);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _elasticController.dispose();
    _textStretchNotifier.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// Programmatic navigation used by the bottom navigation bar.
  /// UNCHANGED.
  void _navigateTo(int index) {
    if (index == _currentIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Edge elastic handlers ──────────────────────────────────────────────────

  /// Fires on every pointer move event (raw, non-consuming).
  ///
  /// We use a [Listener] instead of [GestureDetector] so that pointer events
  /// are NOT consumed — the [PageView] underneath still receives the full
  /// drag and [FluidPagePhysics] can handle normal page swipes freely on
  /// every screen, including swiping back from Settings to Favorites.
  ///
  /// Only when the drag is at a true dead end (no adjacent page to go to)
  /// do we accumulate an elastic offset and push it to the text-stretch
  /// notifier — no setState, so no full-screen rebuild on every frame:
  ///   • First screen (Home)     + dragging right → past the start boundary
  ///     → anchor text stretch at the LEFT edge (centerLeft).
  ///   • Last screen  (Settings) + dragging left  → past the end boundary
  ///     → anchor text stretch at the RIGHT edge (centerRight).
  void _onPointerMove(PointerMoveEvent event) {
    final dx = event.delta.dx;
    final bool draggingPastStart = _currentIndex == 0 && dx > 0;
    final bool draggingPastEnd   = _currentIndex == 2 && dx < 0;

    if (draggingPastStart || draggingPastEnd) {
      _atEdge = true;
      _elasticAlignment =
          draggingPastStart ? Alignment.centerLeft : Alignment.centerRight;
      _elasticOffset =
          (_elasticOffset + dx * 0.25).clamp(-_maxElasticOffset, _maxElasticOffset);
      _publishStretch();
    } else {
      _atEdge = false;
    }
  }

  /// Fires when the finger lifts (raw pointer up, non-consuming).
  ///
  /// If an edge stretch was active, animates the stretch back to resting
  /// (scaleX 1.0) using [Curves.elasticOut] — a slight overshoot then
  /// settle — purely via the notifier, no setState.
  void _onPointerUp(PointerUpEvent event) {
    if (!_atEdge) return;
    _atEdge = false;

    final double startOffset = _elasticOffset;

    _elasticController.reset();

    _elasticAnimation = Tween<double>(begin: startOffset, end: 0.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_elasticController)
      ..addListener(() {
        _elasticOffset = _elasticAnimation.value;
        _publishStretch();
      });

    _elasticController.forward();
  }

  /// Converts the current `_elasticOffset` (px, screen-width independent
  /// pixel cap) into a small scaleX and pushes it to the notifier.
  void _publishStretch() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxScaleDelta = _maxStretchPixels / screenWidth;
    final double scaleX =
        1.0 + (_elasticOffset.abs() / _maxElasticOffset) * maxScaleDelta;
    _textStretchNotifier.value = ElasticTextStretch(scaleX, _elasticAlignment);
  }

  // ── Update dialog ──────────────────────────────────────────────────────────

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final settings = context.read<SettingsProvider>();
        final lang     = settings.defaultLanguage;

        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(
            lang == AppLanguage.en
                ? 'Update Available'
                : 'Mise à jour disponible',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Text(
            lang == AppLanguage.en
                ? 'A new version of the Full Gospel Mission Hymnal is available. Update now for the better experience.'
                : 'Une nouvelle version du cantique de la Mission du Plein Evangile est disponible. Veuillez mettre à jour.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final box = Hive.box('settings');
                box.put('lastUpdateSnoozeDate',
                    DateTime.now().toIso8601String());
                Navigator.of(context).pop();
              },
              child: Text(
                lang == AppLanguage.en ? 'Remind me later' : 'Plus tard',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                UpdateChecker.launchPlayStore();
                Navigator.of(context).pop();
              },
              child: Text(
                lang == AppLanguage.en ? 'Update Now' : 'Mettre à jour',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings   = context.watch<SettingsProvider>();
    final theme      = Theme.of(context);
    final lang       = settings.defaultLanguage;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Listener(
        // Listener (not GestureDetector) so pointer events are NOT consumed.
        // The PageView beneath still receives every drag and handles normal
        // page-to-page swiping freely via FluidPagePhysics, on every screen.
        // We only piggy-back on the events to drive the text-stretch effect.
        onPointerMove: _onPointerMove,
        onPointerUp:   _onPointerUp,
        // ElasticTextProvider hands the notifier down to StretchableText
        // widgets (currently used in HymnListView). It causes no rebuilds
        // itself — only the individual StretchableText widgets that listen
        // via ValueListenableBuilder repaint on each drag frame.
        child: ElasticTextProvider(
          notifier: _textStretchNotifier,
          child: PageView(
            controller: _pageController,
            physics: const FluidPagePhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isRedTheme
            ? Colors.white
            : (theme.brightness == Brightness.dark
                ? Colors.black
                : Colors.white),
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _navigateTo,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: lang == AppLanguage.en ? 'Home' : 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: lang == AppLanguage.en ? 'Favorites' : 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppStrings.settings(lang),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// HymnListBody — Tab 0
// UNCHANGED
// ─────────────────────────────────────────────────────────────────────────────

class HymnListBody extends StatelessWidget {
  const HymnListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final settings   = context.watch<SettingsProvider>();
    final isRedTheme = settings.selectedtheme == AppThemeType.red;

    return SafeArea(
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
                  color: isRedTheme ? Colors.white : theme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const HymnListView(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// SearchBarWidget
// UNCHANGED
// ─────────────────────────────────────────────────────────────────────────────

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final settings   = context.watch<SettingsProvider>();
    final theme      = Theme.of(context);
    final isDark     = theme.brightness == Brightness.dark;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;

    return TextField(
      controller: _controller,
      style: TextStyle(
        color: isRedTheme
            ? Colors.black
            : (isDark ? Colors.white : Colors.black),
      ),
      onChanged: (value) {
        context.read<HymnProvider>().search(value);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: isRedTheme
            ? Colors.white
            : (isDark
                ? const Color(0xFF1E1E1E)
                : const Color.fromARGB(255, 228, 227, 227)),
        hintText: AppStrings.searchHint(settings.defaultLanguage),
        hintStyle: TextStyle(
          color: isRedTheme
              ? Colors.black54
              : (isDark
                  ? const Color.fromARGB(137, 206, 204, 204)
                  : Colors.black54),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isRedTheme
              ? const Color(0xFFD32F2F)
              : (isDark ? Colors.white54 : Colors.black54),
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: isRedTheme
                      ? const Color(0xFFD32F2F)
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
                onPressed: () {
                  _controller.clear();
                  context.read<HymnProvider>().search('');
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// HymnListView
//
// title/subtitle Text widgets are now StretchableText so they pick up the
// edge text-stretch effect. Everything else (layout, colors, ListTile
// structure, navigation) is unchanged.
// ─────────────────────────────────────────────────────────────────────────────

class HymnListView extends StatelessWidget {
  const HymnListView({super.key});

  @override
  Widget build(BuildContext context) {
    final hymnProvider = context.watch<HymnProvider>();
    final settings     = context.watch<SettingsProvider>();
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final isRedTheme   = settings.selectedtheme == AppThemeType.red;

    if (hymnProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
      );
    }

    if (hymnProvider.hymns.isEmpty) {
      return Center(
        child: Text(
          settings.defaultLanguage == AppLanguage.en
              ? "No hymns found!"
              : "Aucun cantique trouvé !",
          style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: hymnProvider.hymns.length,
      separatorBuilder: (context, index) => Divider(
        indent: 70,
        endIndent: 20,
        color: isRedTheme
            ? const Color(0xFFD32F2F)
            : (isDark
                ? Colors.white10
                : const Color.fromARGB(255, 128, 126, 126)),
      ),
      itemBuilder: (context, index) {
        final hymn      = hymnProvider.hymns[index];
        final mainTitle = settings.defaultLanguage == AppLanguage.en
            ? hymn.titleEn
            : hymn.titleFr;
        final subTitle  = settings.defaultLanguage == AppLanguage.en
            ? hymn.titleFr
            : hymn.titleEn;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isRedTheme
                ? const Color(0xFFD32F2F)
                : (isDark ? Colors.black : const Color(0xFFD32F2F)),
            child: Text(
              hymn.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          title: StretchableText(
            mainTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isRedTheme
                  ? Colors.black
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
          subtitle: StretchableText(
            subTitle,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isRedTheme
                  ? Colors.black54
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    LyricsScreen(hymn: hymn),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slideIn = Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutQuart,
                  ));

                  final slideOut = Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(-0.3, 0.0),
                  ).animate(CurvedAnimation(
                    parent: secondaryAnimation,
                    curve: Curves.easeInOutQuart,
                  ));

                  return SlideTransition(
                    position: slideOut,
                    child: SlideTransition(
                      position: slideIn,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
        );
      },
    );
  }
}
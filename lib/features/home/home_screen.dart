import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/pokemon_collection_model.dart';
import '../auth/login_screen.dart';
import '../trivia/trivia_screen.dart';
import '../trade/trade_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final pendingCount = provider.incomingPendingTrades.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('hola ${user?.username ?? ''}'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.refresh(),
          ),
          IconButton(
            tooltip: 'salir',
            icon: const Icon(Icons.logout),
            onPressed: () {
              provider.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _CollectionTab(),
          TradeScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.catching_pokemon_outlined),
            selectedIcon: Icon(Icons.catching_pokemon),
            label: 'mis pokemones',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.swap_horiz_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.swap_horiz),
            ),
            label: 'cambios',
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TriviaScreen()),
              ),
              icon: const Icon(Icons.quiz),
              label: const Text('conseguir pokemon'),
            )
          : null,
    );
  }
}

class _CollectionTab extends StatelessWidget {
  const _CollectionTab();

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<AppProvider>().collection;

    if (collection.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.catching_pokemon,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'no tienes ningun pokemon todavia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'toca el boton de abajo y responde las preguntas\npara ganarte uno',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: collection.length,
      itemBuilder: (context, index) =>
          _PokemonCard(pokemon: collection[index]),
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final PokemonCollectionModel pokemon;
  const _PokemonCard({required this.pokemon});

  Color _typeColor(String type) {
    const map = {
      'Fire': Color(0xFFFF9C54),
      'Water': Color(0xFF4FC1FF),
      'Grass': Color(0xFF63BB5B),
      'Electric': Color(0xFFF3D23B),
      'Psychic': Color(0xFFFA7179),
      'Ice': Color(0xFF74CEC0),
      'Dragon': Color(0xFF756EEB),
      'Dark': Color(0xFF5A5366),
      'Fairy': Color(0xFFEC8FE6),
      'Fighting': Color(0xFFCE4169),
      'Poison': Color(0xFFAB6AC8),
      'Ground': Color(0xFFD97746),
      'Flying': Color(0xFF89AAE3),
      'Bug': Color(0xFF90C12C),
      'Rock': Color(0xFFC5B78C),
      'Ghost': Color(0xFF5269AC),
      'Steel': Color(0xFF5A8EA1),
      'Normal': Color(0xFF9099A1),
    };
    return map[type] ?? const Color(0xFF9099A1);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(pokemon.types.first);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [typeColor.withValues(alpha: 0.7), typeColor.withValues(alpha: 0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: pokemon.spriteUrl,
              width: 100,
              height: 100,
              placeholder: (_, _) => const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, _, _) =>
                  const Icon(Icons.catching_pokemon, size: 60),
            ),
            const SizedBox(height: 6),
            Text(
              '#${pokemon.pokemonId.toString().padLeft(3, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              pokemon.pokemonName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: pokemon.types
                  .map((t) => Chip(
                        label: Text(t,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white)),
                        backgroundColor: _typeColor(t),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

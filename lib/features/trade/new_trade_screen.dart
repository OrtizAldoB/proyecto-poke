import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/pokemon_collection_model.dart';
import '../../core/models/user_model.dart';

enum _Step { selectUser, selectMyPokemon, selectTheirPokemon, confirm }

class NewTradeScreen extends StatefulWidget {
  const NewTradeScreen({super.key});

  @override
  State<NewTradeScreen> createState() => _NewTradeScreenState();
}

class _NewTradeScreenState extends State<NewTradeScreen> {
  _Step _step = _Step.selectUser;
  bool _loading = false;

  List<UserModel> _users = [];
  List<PokemonCollectionModel> _myPokemon = [];
  List<PokemonCollectionModel> _theirPokemon = [];

  UserModel? _selectedUser;
  PokemonCollectionModel? _mySelectedPokemon;
  PokemonCollectionModel? _theirSelectedPokemon;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final users = await context.read<AppProvider>().getOtherUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _selectUser(UserModel user) async {
    setState(() {
      _loading = true;
      _selectedUser = user;
    });
    final provider = context.read<AppProvider>();
    final myPokemon = await provider.getMyTradableCollection();
    final theirPokemon = await provider.getOtherUserCollection(user.id!);
    if (!mounted) return;
    setState(() {
      _myPokemon = myPokemon;
      _theirPokemon = theirPokemon;
      _loading = false;
      _step = _Step.selectMyPokemon;
    });
  }

  Future<void> _sendTrade() async {
    if (_selectedUser == null ||
        _mySelectedPokemon == null ||
        _theirSelectedPokemon == null) {
      return;
    }
    setState(() => _loading = true);
    await context.read<AppProvider>().sendTradeOffer(
          toUser: _selectedUser!,
          myPokemon: _mySelectedPokemon!,
          theirPokemon: _theirSelectedPokemon!,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('propuesta enviada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nuevo cambio'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == _Step.selectUser || !mounted) {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _step = _Step.values[_step.index - 1];
              });
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (_step) {
                _Step.selectUser => _SelectUserStep(
                    key: const ValueKey('user'),
                    users: _users,
                    onSelect: _selectUser,
                  ),
                _Step.selectMyPokemon => _SelectPokemonStep(
                    key: const ValueKey('myPokemon'),
                    title: 'cual pokemon ofreces',
                    pokemon: _myPokemon,
                    selected: _mySelectedPokemon,
                    onSelect: (p) {
                      setState(() {
                        _mySelectedPokemon = p;
                        _step = _Step.selectTheirPokemon;
                      });
                    },
                  ),
                _Step.selectTheirPokemon => _SelectPokemonStep(
                    key: const ValueKey('theirPokemon'),
                    title: 'cual pokemon quieres',
                    pokemon: _theirPokemon,
                    selected: _theirSelectedPokemon,
                    onSelect: (p) {
                      setState(() {
                        _theirSelectedPokemon = p;
                        _step = _Step.confirm;
                      });
                    },
                  ),
                _Step.confirm => _ConfirmStep(
                    key: const ValueKey('confirm'),
                    toUser: _selectedUser!,
                    myPokemon: _mySelectedPokemon!,
                    theirPokemon: _theirSelectedPokemon!,
                    onConfirm: _sendTrade,
                  ),
              },
            ),
    );
  }
}

class _SelectUserStep extends StatelessWidget {
  final List<UserModel> users;
  final void Function(UserModel) onSelect;

  const _SelectUserStep(
      {super.key, required this.users, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'no hay otros usuarios registrados\ncrea otra cuenta en otro celu para probar',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('con quien quieres cambiar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.avatarUrl),
                    onBackgroundImageError: (_, _) {},
                    child: const Icon(Icons.person),
                  ),
                  title: Text(user.username,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('desde ${user.createdAt.year}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onSelect(user),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectPokemonStep extends StatelessWidget {
  final String title;
  final List<PokemonCollectionModel> pokemon;
  final PokemonCollectionModel? selected;
  final void Function(PokemonCollectionModel) onSelect;

  const _SelectPokemonStep({
    super.key,
    required this.title,
    required this.pokemon,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (pokemon.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.catching_pokemon, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'no hay pokemones disponibles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: pokemon.length,
            itemBuilder: (context, index) {
              final p = pokemon[index];
              final isSelected = selected?.id == p.id;
              return GestureDetector(
                onTap: () => onSelect(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                      width: isSelected ? 3 : 1,
                    ),
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.08)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: p.spriteUrl,
                        width: 60,
                        height: 60,
                        placeholder: (_, _) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.catching_pokemon, size: 40),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.pokemonName,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  final UserModel toUser;
  final PokemonCollectionModel myPokemon;
  final PokemonCollectionModel theirPokemon;
  final VoidCallback onConfirm;

  const _ConfirmStep({
    super.key,
    required this.toUser,
    required this.myPokemon,
    required this.theirPokemon,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'confirmar cambio',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'le vas a mandar esto a ${toUser.username}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ConfirmPokemonCard(label: 'das', pokemon: myPokemon),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.swap_horiz, size: 40, color: Colors.grey),
              ),
              _ConfirmPokemonCard(label: 'recibes', pokemon: theirPokemon),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.send),
            label: const Text('mandar propuesta',
                style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmPokemonCard extends StatelessWidget {
  final String label;
  final PokemonCollectionModel pokemon;
  const _ConfirmPokemonCard({required this.label, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        CachedNetworkImage(
          imageUrl: pokemon.spriteUrl,
          width: 90,
          height: 90,
          placeholder: (_, _) =>
              const CircularProgressIndicator(strokeWidth: 2),
          errorWidget: (_, _, _) =>
              const Icon(Icons.catching_pokemon, size: 60),
        ),
        const SizedBox(height: 6),
        Text(
          pokemon.pokemonName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

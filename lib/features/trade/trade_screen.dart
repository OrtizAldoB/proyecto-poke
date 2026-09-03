import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/trade_model.dart';
import 'new_trade_screen.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final incoming = provider.incomingPendingTrades;
    final outgoing = provider.outgoingTrades;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('recibidos'),
                  if (incoming.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Badge(label: Text('${incoming.length}')),
                  ],
                ],
              ),
            ),
            const Tab(text: 'enviados'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _IncomingTradesTab(trades: incoming),
              _OutgoingTradesTab(trades: outgoing),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewTradeScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('proponer cambio'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IncomingTradesTab extends StatelessWidget {
  final List<TradeModel> trades;
  const _IncomingTradesTab({required this.trades});

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('nadie te ha mandado cambios',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: trades.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _IncomingTradeCard(trade: trades[index]),
    );
  }
}

class _IncomingTradeCard extends StatelessWidget {
  final TradeModel trade;
  const _IncomingTradeCard({required this.trade});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${trade.fromUsername} te quiere cambiar:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniPokemonCard(
                  name: trade.offeredPokemonName,
                  sprite: trade.offeredPokemonSprite,
                  label: 'te da',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.swap_horiz, size: 32, color: Colors.grey),
                ),
                _MiniPokemonCard(
                  name: trade.requestedPokemonName,
                  sprite: trade.requestedPokemonSprite,
                  label: 'te pide',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await provider.rejectTrade(trade);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('cambio rechazado')),
                        );
                      }
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('no gracias',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await provider.acceptTrade(trade);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('trato hecho!!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('acepto'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingTradesTab extends StatelessWidget {
  final List<TradeModel> trades;
  const _OutgoingTradesTab({required this.trades});

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('no has mandado nada todavia',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: trades.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _OutgoingTradeCard(trade: trades[index]),
    );
  }
}

class _OutgoingTradeCard extends StatelessWidget {
  final TradeModel trade;
  const _OutgoingTradeCard({required this.trade});

  Color _statusColor(TradeStatus s) => switch (s) {
        TradeStatus.pending => Colors.orange,
        TradeStatus.accepted => Colors.green,
        TradeStatus.rejected => Colors.red,
        TradeStatus.cancelled => Colors.grey,
      };

  String _statusLabel(TradeStatus s) => switch (s) {
        TradeStatus.pending => 'esperando',
        TradeStatus.accepted => 'aceptado',
        TradeStatus.rejected => 'rechazado',
        TradeStatus.cancelled => 'cancelado',
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'para: ${trade.toUsername}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(trade.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(trade.status)),
                  ),
                  child: Text(
                    _statusLabel(trade.status),
                    style: TextStyle(
                        color: _statusColor(trade.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniPokemonCard(
                  name: trade.offeredPokemonName,
                  sprite: trade.offeredPokemonSprite,
                  label: 'doy',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.swap_horiz, size: 32, color: Colors.grey),
                ),
                _MiniPokemonCard(
                  name: trade.requestedPokemonName,
                  sprite: trade.requestedPokemonSprite,
                  label: 'pido',
                ),
              ],
            ),
            if (trade.status == TradeStatus.pending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await provider.cancelTrade(trade);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('cambio cancelado')),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('cancelar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniPokemonCard extends StatelessWidget {
  final String name;
  final String sprite;
  final String label;

  const _MiniPokemonCard({
    required this.name,
    required this.sprite,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          CachedNetworkImage(
            imageUrl: sprite,
            width: 64,
            height: 64,
            placeholder: (_, _) => const SizedBox(
                width: 64,
                height: 64,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2))),
            errorWidget: (_, _, _) =>
                const Icon(Icons.catching_pokemon, size: 48),
          ),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

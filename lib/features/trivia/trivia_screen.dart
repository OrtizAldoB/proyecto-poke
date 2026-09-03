import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/app_provider.dart';
import '../../core/services/pokeapi_service.dart';
import '../../core/models/pokemon_collection_model.dart';

enum _TriviaState { loading, question, result, reward, error }

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  _TriviaState _state = _TriviaState.loading;
  List<TriviaQuestion> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  String? _selectedAnswer;
  bool _answered = false;
  String? _errorMsg;
  PokemonCollectionModel? _reward;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _state = _TriviaState.loading);
    try {
      final questions =
          await context.read<AppProvider>().loadTriviaQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _currentIndex = 0;
        _correctCount = 0;
        _selectedAnswer = null;
        _answered = false;
        _state = _TriviaState.question;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'no se pudo cargar, revisa el internet';
        _state = _TriviaState.error;
      });
    }
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    final correct = _questions[_currentIndex].correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (answer == correct) _correctCount++;
    });
  }

  Future<void> _next() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      setState(() => _state = _TriviaState.result);
      if (_correctCount == 3) {
        await _giveReward();
      }
    }
  }

  Future<void> _giveReward() async {
    try {
      final reward = await context.read<AppProvider>().awardRandomPokemon();
      if (!mounted) return;
      setState(() {
        _reward = reward;
        _state = _TriviaState.reward;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'algo salio mal: $e';
        _state = _TriviaState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('preguntas pokemon'),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_state) {
          _TriviaState.loading => const Center(
              key: ValueKey('loading'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('cargando preguntas...'),
                ],
              ),
            ),
          _TriviaState.question => _QuestionView(
              key: ValueKey('q$_currentIndex'),
              question: _questions[_currentIndex],
              questionNumber: _currentIndex + 1,
              totalQuestions: _questions.length,
              selectedAnswer: _selectedAnswer,
              answered: _answered,
              onSelect: _selectAnswer,
              onNext: _next,
            ),
          _TriviaState.result => _ResultView(
              key: const ValueKey('result'),
              correct: _correctCount,
              total: _questions.length,
              onRetry: _loadQuestions,
              onClose: () => Navigator.of(context).pop(),
            ),
          _TriviaState.reward => _RewardView(
              key: const ValueKey('reward'),
              pokemon: _reward!,
              onClose: () => Navigator.of(context).pop(),
            ),
          _TriviaState.error => Center(
              key: const ValueKey('error'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_errorMsg ?? 'erro raro',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadQuestions,
                      child: const Text('reintentar'),
                    ),
                  ],
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final TriviaQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final String? selectedAnswer;
  final bool answered;
  final void Function(String) onSelect;
  final VoidCallback onNext;

  const _QuestionView({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selectedAnswer,
    required this.answered,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: questionNumber / totalQuestions,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            'pregunta $questionNumber de $totalQuestions',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                question.question,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...question.options.map((opt) => _OptionButton(
                option: opt,
                isSelected: selectedAnswer == opt,
                isCorrect: opt == question.correctAnswer,
                answered: answered,
                onTap: () => onSelect(opt),
              )),
          const Spacer(),
          if (answered)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onNext,
              child: Text(
                questionNumber == totalQuestions
                    ? 'ver resultados'
                    : 'siguiente',
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool isCorrect;
  final bool answered;
  final VoidCallback onTap;

  const _OptionButton({
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color? borderColor;
    if (answered) {
      if (isCorrect) {
        bgColor = Colors.green.shade100;
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.shade100;
        borderColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: answered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor ?? Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(option, style: const TextStyle(fontSize: 15)),
              ),
              if (answered && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green),
              if (answered && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ResultView({
    super.key,
    required this.correct,
    required this.total,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final passed = correct == total;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 80,
              color: passed ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              passed ? 'lo lograste!!' : 'fallaste mano',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'acertaste $correct de $total',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (passed) ...[
              const SizedBox(height: 8),
              const Text(
                'espera que te mandamos un pokemon',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'necesitas las $total para ganar un pokemon',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('intentar otra vez'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onClose,
                child: const Text('volver'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RewardView extends StatelessWidget {
  final PokemonCollectionModel pokemon;
  final VoidCallback onClose;

  const _RewardView({super.key, required this.pokemon, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'conseguiste un pokemon!!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CachedNetworkImage(
              imageUrl: pokemon.spriteUrl,
              width: 180,
              height: 180,
              placeholder: (_, _) => const CircularProgressIndicator(),
              errorWidget: (_, _, _) =>
                  const Icon(Icons.catching_pokemon, size: 100),
            ),
            const SizedBox(height: 16),
            Text(
              pokemon.pokemonName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '#${pokemon.pokemonId.toString().padLeft(3, '0')}  -  ${pokemon.types.join(' / ')}',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.catching_pokemon),
              label: const Text('ver mi coleccion'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/database_providers.dart';
import '../../services/ai_service.dart';
import '../../models/quiz_model.dart';
import 'package:intl/intl.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  void _startNewQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ActiveQuizPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizHistoryAsync = ref.watch(quizHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Quizzes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Card
            quizHistoryAsync.when(
              data: (history) {
                final totalQuizzes = history.length;
                final avgScore = totalQuizzes > 0
                    ? (history.map((q) => q.score).reduce((a, b) => a + b) / totalQuizzes).toStringAsFixed(1)
                    : '0';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            avgScore,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Average Score',
                            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      Column(
                        children: [
                          Text(
                            totalQuizzes.toString(),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quizzes Taken',
                            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            Text(
              'Quiz History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // History List
            Expanded(
              child: quizHistoryAsync.when(
                data: (history) {
                  if (history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quizzes taken yet.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final quiz = history[index];
                      final dateStr = DateFormat('MMM dd, yyyy').format(quiz.createdAt);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(
                            quiz.quizTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Taken on $dateStr'),
                          trailing: Text(
                            '${quiz.score}/${quiz.totalQuestions}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Failed to load history: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewQuiz,
        label: const Text('Start AI Quiz'),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }
}

// Interactive Quiz Page
class ActiveQuizPage extends ConsumerStatefulWidget {
  const ActiveQuizPage({super.key});

  @override
  ConsumerState<ActiveQuizPage> createState() => _ActiveQuizPageState();
}

class _ActiveQuizPageState extends ConsumerState<ActiveQuizPage> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isSaving = false;
  bool _isLoadingQuiz = true;
  String _quizTitle = 'AI Generated Quiz';

  final List<Map<String, dynamic>> _fallbackQuestions = [
    {
      'question': 'Which data structure follows the LIFO (Last In First Out) principle?',
      'options': ['Queue', 'Linked List', 'Stack', 'Tree'],
      'correctIndex': 2,
    },
    {
      'question': 'What is the time complexity of searching in a Balanced Binary Search Tree?',
      'options': ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
      'correctIndex': 1,
    },
    {
      'question': 'Which database system is Supabase built on top of?',
      'options': ['MongoDB', 'MySQL', 'PostgreSQL', 'SQLite'],
      'correctIndex': 2,
    },
    {
      'question': 'In Flutter, which widget is commonly used for managing tab views?',
      'options': ['DefaultTabController', 'Navigator', 'ListView', 'Stack'],
      'correctIndex': 0,
    },
    {
      'question': 'What design pattern does Riverpod primarily help with in Flutter?',
      'options': ['Singleton', 'State Management', 'Builder', 'Observer'],
      'correctIndex': 1,
    },
  ];

  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadAIQuiz();
  }

  Future<void> _loadAIQuiz() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('No user');

      // Get the user's notes to use as context
      final notesRepo = ref.read(notesRepositoryProvider);
      final notesStream = notesRepo.getNotesStream(user.id);
      final notes = await notesStream.first;

      if (notes.isEmpty) throw Exception('No notes available');

      // Combine note content as context
      final notesText = notes
          .map((n) => '${n.title}\n${n.content}')
          .join('\n\n---\n\n');

      final aiService = ref.read(aiServiceProvider);
      final aiQuestions = await aiService.generateQuiz(notesText);

      if (aiQuestions.length >= 3) {
        if (mounted) {
          setState(() {
            _questions = aiQuestions;
            _quizTitle = 'AI Quiz — Based on Your Notes';
            _isLoadingQuiz = false;
          });
        }
        return;
      }
      throw Exception('Not enough questions generated');
    } catch (_) {
      // Fallback to hardcoded questions
      if (mounted) {
        setState(() {
          _questions = _fallbackQuestions;
          _quizTitle = 'CS & Algorithms Quick Quiz';
          _isLoadingQuiz = false;
        });
      }
    }
  }

  void _submitAnswer() {
    if (_selectedAnswerIndex == null) return;

    if (_selectedAnswerIndex == _questions[_currentQuestionIndex]['correctIndex']) {
      _score++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() async {
    setState(() => _isSaving = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final result = QuizModel(
          id: '',
          userId: user.id,
          quizTitle: _quizTitle,
          score: _score,
          totalQuestions: _questions.length,
          createdAt: DateTime.now(),
        );

        await ref.read(quizRepositoryProvider).saveQuizResult(result);
      }
    } catch (e) {
      // Failed silently
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Quiz Completed!'),
            content: Text('Your Score: $_score / ${_questions.length}'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dismiss dialog
                  Navigator.of(context).pop(); // pop quiz page
                },
                child: const Text('Back to History'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuiz) {
      return Scaffold(
        appBar: AppBar(title: const Text('Generating AI Quiz...')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Generating personalized quiz\nfrom your notes...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentQuestionIndex + 1}/${_questions.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _questions.length,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    currentQuestion['question'] as String,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ...List.generate(
                    (currentQuestion['options'] as List).length,
                    (index) {
                      final option = currentQuestion['options'][index] as String;
                      final isSelected = _selectedAnswerIndex == index;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Theme.of(context).cardTheme.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          title: Text(option),
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            child: isSelected
                                ? Icon(Icons.check, size: 14, color: Theme.of(context).colorScheme.onPrimary)
                                : null,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedAnswerIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _selectedAnswerIndex == null ? null : _submitAnswer,
                      child: Text(
                        _currentQuestionIndex == _questions.length - 1 ? 'Finish Quiz' : 'Next Question',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

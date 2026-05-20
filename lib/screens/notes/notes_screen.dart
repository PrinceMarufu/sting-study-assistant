import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../providers/auth_providers.dart';
import '../../providers/database_providers.dart';
import '../../services/ai_service.dart';
import '../../models/note_model.dart';
import 'package:intl/intl.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isUploading = false;

  Future<void> _uploadPDF() async {
    setState(() => _isUploading = true);
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Uploading $fileName & generating AI summary...')),
          );
        }

        // Upload to Storage
        final pdfUrl = await ref.read(notesRepositoryProvider).uploadPDF(
          bytes: fileBytes,
          fileName: fileName,
        );

        if (pdfUrl != null) {
          final user = ref.read(currentUserProvider);
          if (user != null) {
            // Extract real text from PDF using Syncfusion
            String extractedText = '';
            try {
              final document = PdfDocument(inputBytes: fileBytes);
              extractedText = PdfTextExtractor(document).extractText();
              document.dispose();
            } catch (_) {
              extractedText = '';
            }

            String summaryContent;
            if (extractedText.trim().isNotEmpty) {
              // Generate real AI summary via Gemini
              try {
                final aiService = ref.read(aiServiceProvider);
                summaryContent = await aiService.summarizeText(extractedText);
                summaryContent = 'File Link: $pdfUrl\n\n$summaryContent';
              } catch (e) {
                summaryContent =
                    'File Link: $pdfUrl\n\n[AI Summary unavailable — error: $e]\n\nExtracted text preview:\n${extractedText.substring(0, extractedText.length > 500 ? 500 : extractedText.length)}...';
              }
            } else {
              summaryContent =
                  'File Link: $pdfUrl\n\n[Could not extract text from this PDF. It may be image-based or scanned.]';
            }

            final newNote = NoteModel(
              id: '',
              userId: user.id,
              title: 'Summary: ${fileName.replaceAll('.pdf', '')}',
              content: summaryContent,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await ref.read(notesRepositoryProvider).createNote(newNote);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF Uploaded & AI Summary Generated!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showNoteDialog({NoteModel? note}) {
    final titleController = TextEditingController(text: note?.title);
    final contentController = TextEditingController(text: note?.content);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: Text(
            note == null ? 'Create Note' : 'Edit Note',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: contentController,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Content required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;

                  if (note == null) {
                    final newNote = NoteModel(
                      id: '',
                      userId: user.id,
                      title: titleController.text.trim(),
                      content: contentController.text.trim(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await ref.read(notesRepositoryProvider).createNote(newNote);
                  } else {
                    final updatedNote = note.copyWith(
                      title: titleController.text.trim(),
                      content: contentController.text.trim(),
                      updatedAt: DateTime.now(),
                    );
                    await ref.read(notesRepositoryProvider).updateNote(updatedNote);
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: const Text('Delete Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this note permanently?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notesRepositoryProvider).deleteNote(noteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              )
            : const Text(
                'My Notes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Clean Study/Workspace background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/study_notes.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. High-contrast Dark Frosted Glass filter
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Page content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                children: [
                  // Premium glassmorphic upload banner
                  InkWell(
                    onTap: _isUploading ? null : _uploadPDF,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                _isUploading
                                    ? const SizedBox(
                                        height: 44,
                                        width: 44,
                                        child: CircularProgressIndicator(strokeWidth: 3),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 32,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                const SizedBox(height: 16),
                                Text(
                                  _isUploading ? 'Uploading PDF...' : 'Upload PDF Study Notes',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Let AI automatically extract and summarize key sections',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Header title
                  Row(
                    children: [
                      Icon(Icons.notes_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Saved Summaries',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notes List with translucent cards
                  Expanded(
                    child: notesAsync.when(
                      data: (notes) {
                        final filteredNotes = notes.where((note) {
                          final title = note.title.toLowerCase();
                          final content = note.content.toLowerCase();
                          return title.contains(_searchQuery) || content.contains(_searchQuery);
                        }).toList();

                        if (filteredNotes.isEmpty) {
                          return Center(
                            child: Text(
                              'No study notes saved yet.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 15,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 110), // Padding to clear bottom floating bar
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            final formattedDate = DateFormat('MMM dd, yyyy').format(note.updatedAt);
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.09),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(18),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.description_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      note.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Updated $formattedDate',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      color: Colors.grey[900],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showNoteDialog(note: note);
                                        } else if (val == 'delete') {
                                          _deleteNote(note.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit', style: TextStyle(color: Colors.white)),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      _showNoteDialog(note: note);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
                        child: Text('Failed to load notes: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96.0, right: 10.0), // Floats comfortably above bottom bar
        child: FloatingActionButton(
          onPressed: () => _showNoteDialog(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.black87, size: 28),
        ),
      ),
    );
  }
}

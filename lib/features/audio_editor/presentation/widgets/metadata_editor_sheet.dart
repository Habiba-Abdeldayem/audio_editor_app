import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/audio_metadata_model.dart';

class MetadataEditorSheet extends StatefulWidget {
  final AudioMetadataModel initial;
  final bool isSaving;
  final ValueChanged<AudioMetadataModel> onChanged;
  final VoidCallback onSave;

  const MetadataEditorSheet({
    super.key,
    required this.initial,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
  });

  @override
  State<MetadataEditorSheet> createState() => _MetadataEditorSheetState();
}

class _MetadataEditorSheetState extends State<MetadataEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _artistCtrl;
  late final TextEditingController _albumCtrl;
  late final TextEditingController _genreCtrl;
  List<int>? _artwork;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initial.title);
    _artistCtrl = TextEditingController(text: widget.initial.artist);
    _albumCtrl = TextEditingController(text: widget.initial.album);
    _genreCtrl = TextEditingController(text: widget.initial.genre);
    _artwork = widget.initial.artwork;
  }

  void _emitChange() {
    widget.onChanged(AudioMetadataModel(
      title: _titleCtrl.text,
      artist: _artistCtrl.text,
      album: _albumCtrl.text,
      genre: _genreCtrl.text,
      artwork: _artwork,
    ));
  }

  Future<void> _pickArtwork() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _artwork = bytes);
    _emitChange();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    _genreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.editMetadata,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _pickArtwork,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _artwork != null
                            ? Image.memory(
                                Uint8List.fromList(_artwork!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: const Icon(Icons.music_note, size: 40),
                              ),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.edit,
                            size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(labelText: l10n.fieldTitle),
                onChanged: (_) => _emitChange(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _artistCtrl,
                decoration: InputDecoration(labelText: l10n.fieldArtist),
                onChanged: (_) => _emitChange(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _albumCtrl,
                decoration: InputDecoration(labelText: l10n.fieldAlbum),
                onChanged: (_) => _emitChange(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _genreCtrl,
                decoration: InputDecoration(labelText: l10n.fieldGenre),
                onChanged: (_) => _emitChange(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: widget.isSaving ? null : widget.onSave,
                child: widget.isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveMetadata),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ControlsSection extends StatelessWidget {
  final File selectedImage;
  final TextEditingController promptController;
  final String customPrompt;
  final String? selectedScene;
  final bool isGenerating;
  final VoidCallback onClose;
  final ValueChanged<String> onPromptChanged;
  final ValueChanged<String?> onSceneSelected;
  final VoidCallback onGenerate;

  const ControlsSection({
    Key? key,
    required this.selectedImage,
    required this.promptController,
    required this.customPrompt,
    required this.selectedScene,
    required this.isGenerating,
    required this.onClose,
    required this.onPromptChanged,
    required this.onSceneSelected,
    required this.onGenerate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                selectedImage,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Custom Prompt (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: promptController,
          onChanged: onPromptChanged,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe the scene you want...',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Or Choose a Scene',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 600 ? 1.1 : 0.85,
              ),
              itemCount: AppScenes.all.length,
              itemBuilder: (context, index) {
                final scene = AppScenes.all[index];
                final isSelected = selectedScene == scene['id'];
                return InkWell(
                  onTap: () {
                    onSceneSelected(isSelected ? null : scene['id']);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.purpleLight
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.borderLight,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scene['emoji']!,
                          style: TextStyle(
                              fontSize: constraints.maxWidth > 600 ? 36 : 28),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scene['label']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: constraints.maxWidth > 600 ? 15 : 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            scene['description']!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: constraints.maxWidth > 600 ? 11 : 10,
                              color: AppColors.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isGenerating ? null : onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text('Generate Images',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
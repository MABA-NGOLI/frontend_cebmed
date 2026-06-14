import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/caregiver_link_view_model.dart';

class CaregiverLinkView extends StatefulWidget {
  const CaregiverLinkView({
    super.key,
    required this.onBack,
    required this.onSuccess,
  });

  final VoidCallback onBack;
  final VoidCallback onSuccess;

  @override
  State<CaregiverLinkView> createState() => _CaregiverLinkViewState();
}

class _CaregiverLinkViewState extends State<CaregiverLinkView> {
  late final CaregiverLinkViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CaregiverLinkViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await _viewModel.redeem();
    if (!mounted) return;
    if (ok) {
      widget.onSuccess();
      return;
    }

    if (_viewModel.errorMessage != null &&
        _viewModel.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_viewModel.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.primaryPink,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Code patient',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Entrez le code partage par votre patient',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _viewModel.codeController,
                          onChanged: (_) => _viewModel.onFieldChanged(),
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (_viewModel.canSubmit) {
                              _submit();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Ex: A7B8C9',
                            filled: true,
                            fillColor: const Color(0xFFF2F2F2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                        if (_viewModel.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _viewModel.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _viewModel.canSubmit ? _submit : null,
                            child: _viewModel.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Valider le code'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'perfil_wizard_controller.dart';
import 'steps/step_foto.dart';
import 'steps/step_fisico.dart';
import 'steps/step_experiencia_objetivo.dart';
import 'steps/step_disponibilidad.dart';
import 'steps/step_limitaciones.dart';
import 'steps/step_resumen.dart';

/// Pantalla principal del Wizard. Controla pages + barra de progreso.
class PerfilWizardScreen extends StatelessWidget {
  final String uid;
  const PerfilWizardScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerfilWizardController(uid: uid),
      child: const _PerfilWizardBody(),
    );
  }
}

class _PerfilWizardBody extends StatefulWidget {
  const _PerfilWizardBody({Key? key}) : super(key: key);

  @override
  State<_PerfilWizardBody> createState() => _PerfilWizardBodyState();
}

class _PerfilWizardBodyState extends State<_PerfilWizardBody> {
  late PageController _page;

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<PerfilWizardController>();
    _page = PageController(initialPage: ctrl.currentStep);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _syncToPage(int step) {
    if (_page.hasClients && _page.page?.round() != step) {
      _page.jumpToPage(step);
    }
  }

  Widget _buildStepper(PerfilWizardController c) {
    final labels = [
      'Foto',
      'Físico',
      'Experiencia',
      'Disponibilidad',
      'Limitaciones',
      'Resumen'
    ];
    return Column(
      children: [
        LinearProgressIndicator(value: c.progress()),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: List.generate(labels.length, (i) {
            final active = i == c.currentStep;
            return Chip(
              label: Text(labels[i],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal)),
              backgroundColor:
                  active ? Theme.of(context).colorScheme.primary.withOpacity(.2) : null,
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PerfilWizardController>(
      builder: (context, c, _) {
        _syncToPage(c.currentStep);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Completar Perfil'),
            leading: c.currentStep > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      c.back();
                      _page.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    },
                  )
                : null,
          ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildStepper(c)),
                  Expanded(
                    child: PageView(
                      controller: _page,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        StepFotoScreen(),
                        StepFisicoScreen(),
                        StepExperienciaObjetivoScreen(),
                        StepDisponibilidadDuracionScreen(),
                        StepLimitacionesScreen(),
                        StepResumenScreen(),
                      ],
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
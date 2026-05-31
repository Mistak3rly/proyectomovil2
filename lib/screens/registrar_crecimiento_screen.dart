import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

import '../services/control_calidad_service.dart';
import '../services/sanidad_service.dart';
import '../models/lote_model.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CU18 — Registrar Crecimiento: Edad y Peso del Pollo
/// ─────────────────────────────────────────────────────────────────────────────
/// Pantalla de recolección de datos en campo optimizada para operarios
/// en galpones de crianza.  Envía el payload al endpoint
/// `/lotes/control-calidad/` mediante [ControlCalidadService].
///
/// El backend calcula automáticamente: edad_dias, peso_estandar,
/// porcentaje_diferencia, estado_desarrollo, empresa_id, usuario_id.
/// ─────────────────────────────────────────────────────────────────────────────
class RegistrarCrecimientoScreen extends StatefulWidget {
  const RegistrarCrecimientoScreen({super.key});

  @override
  State<RegistrarCrecimientoScreen> createState() =>
      _RegistrarCrecimientoScreenState();
}

class _RegistrarCrecimientoScreenState
    extends State<RegistrarCrecimientoScreen> {
  // ── Form Key & Controllers ───────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();
  final _observacionController = TextEditingController();

  // ── Estado interno ───────────────────────────────────────────────────
  final ControlCalidadService _service = ControlCalidadService();
  final SanidadService _sanidadService = SanidadService();

  bool _isLoading = false;
  bool _isLoadingLotes = true;

  List<LoteModel> _lotes = [];
  LoteModel? _selectedLote;
  DateTime _fechaRegistro = DateTime.now();

  // ── Ciclo de vida ────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _cargarLotes();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  // ── Cargar lotes activos desde el backend ─────────────────────────────
  Future<void> _cargarLotes() async {
    try {
      final lotes = await _sanidadService.getActiveLots();
      if (mounted) {
        setState(() {
          _lotes = lotes;
          _isLoadingLotes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLotes = false);
        _mostrarSnackBar('Error al cargar lotes: $e', esError: true);
      }
    }
  }

  // ── Seleccionar fecha de registro ─────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaRegistro,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Fecha de registro',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null && mounted) {
      setState(() => _fechaRegistro = picked);
    }
  }

  // ── Enviar formulario al backend ──────────────────────────────────────
  Future<void> _enviarFormulario() async {
    // Validar el formulario y la selección del lote.
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLote == null) {
      _mostrarSnackBar('Seleccione un lote activo', esError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Formatear fecha como ISO (YYYY-MM-DD).
      final String fechaISO =
          '${_fechaRegistro.year}-${_fechaRegistro.month.toString().padLeft(2, '0')}-${_fechaRegistro.day.toString().padLeft(2, '0')}';

      await _service.registrarCrecimiento(
        idLote: _selectedLote!.id,
        pesoRegistrado: double.parse(_pesoController.text),
        observacion: _observacionController.text,
        fechaRegistro: fechaISO,
      );

      // ── Éxito ─────────────────────────────────────────────────────
      _mostrarSnackBar(
        '✓ Registro de crecimiento guardado exitosamente',
        esError: false,
      );
      _limpiarFormulario();
    } on DioException catch (dioError) {
      // ── Error de red o validación del backend ─────────────────────
      String mensajeError = 'Error al registrar crecimiento';

      if (dioError.response != null) {
        final data = dioError.response?.data;
        if (data is Map) {
          // Extraer mensajes de validación del backend DRF.
          final errores = data.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(' | ');
          mensajeError = errores;
        } else {
          mensajeError =
              'Error ${dioError.response?.statusCode}: ${data.toString()}';
        }
      } else if (dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout) {
        mensajeError = 'Tiempo de espera agotado. Verifique su conexión.';
      } else if (dioError.type == DioExceptionType.connectionError) {
        mensajeError = 'Sin conexión a Internet. Intente más tarde.';
      }

      _mostrarSnackBar(mensajeError, esError: true);
    } catch (e) {
      _mostrarSnackBar('Error inesperado: $e', esError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Utilidades ────────────────────────────────────────────────────────
  void _limpiarFormulario() {
    _pesoController.clear();
    _observacionController.clear();
    setState(() => _selectedLote = null);
  }

  void _mostrarSnackBar(String mensaje, {required bool esError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: esError ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: Duration(seconds: esError ? 5 : 3),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  B U I L D
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrar Crecimiento',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE67E22),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoadingLotes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Encabezado informativo ───────────────────────
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // ── Campo: Selección de Lote ────────────────────
                    _buildLoteDropdown(),
                    const SizedBox(height: 20),

                    // ── Campo: Peso Registrado (kg) ─────────────────
                    _buildPesoInput(),
                    const SizedBox(height: 20),

                    // ── Campo: Fecha de Registro ────────────────────
                    _buildFechaSelector(),
                    const SizedBox(height: 20),

                    // ── Campo: Observaciones ────────────────────────
                    _buildObservacionInput(),
                    const SizedBox(height: 32),

                    // ── Botón Enviar / Indicador de carga ───────────
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  W I D G E T S   P R I V A D O S
  // ═══════════════════════════════════════════════════════════════════════

  /// Encabezado descriptivo con ícono del módulo.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              size: 32,
              color: Color(0xFFE67E22),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control de Peso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Registre el peso promedio de la muestra para el seguimiento del crecimiento del lote.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF636E72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdown predictivo de lotes activos.
  Widget _buildLoteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(icon: Icons.inventory_2, label: 'Lote *'),
        const SizedBox(height: 8),
        DropdownButtonFormField<LoteModel>(
          decoration: _inputDecoration(
            hint: 'Seleccione el lote de aves',
            prefixIcon: Icons.search,
          ),
          isExpanded: true,
          initialValue: _selectedLote,
          items: _lotes
              .map(
                (lote) => DropdownMenuItem<LoteModel>(
                  value: lote,
                  child: Text(
                    '${lote.nombre} — Pob: ${lote.poblacionActual}  |  ${lote.diasDeVida}d',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _isLoading
              ? null
              : (value) => setState(() => _selectedLote = value),
          validator: (value) =>
              value == null ? 'Seleccione un lote activo' : null,
        ),
      ],
    );
  }

  /// Input numérico decimal para el peso registrado (kg).
  Widget _buildPesoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(icon: Icons.scale, label: 'Peso Registrado (kg) *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pesoController,
          enabled: !_isLoading,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            // Permitir solo dígitos y un punto decimal.
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: _inputDecoration(
            hint: 'Ej: 2.45',
            prefixIcon: Icons.monitor_weight,
            suffixText: 'kg',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingrese el peso registrado';
            }
            final peso = double.tryParse(value);
            if (peso == null) {
              return 'Ingrese un valor numérico válido';
            }
            if (peso <= 0.0) {
              return 'El peso debe ser estrictamente mayor a 0';
            }
            if (peso > 10.0) {
              return 'Verifique: el peso parece demasiado alto (máx 10 kg)';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Selector de fecha de registro con DatePicker.
  Widget _buildFechaSelector() {
    final String fechaFormateada =
        '${_fechaRegistro.day.toString().padLeft(2, '0')}/${_fechaRegistro.month.toString().padLeft(2, '0')}/${_fechaRegistro.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(icon: Icons.calendar_today, label: 'Fecha de Registro'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isLoading ? null : _seleccionarFecha,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _inputDecoration(
              hint: '',
              prefixIcon: Icons.event,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fechaFormateada,
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF636E72)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de texto multilínea para observaciones opcionales.
  Widget _buildObservacionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(icon: Icons.notes, label: 'Observaciones (Opcional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _observacionController,
          enabled: !_isLoading,
          maxLines: 4,
          maxLength: 500,
          decoration: _inputDecoration(
            hint: 'Notas del galponero: condiciones de la muestra, clima, etc.',
            prefixIcon: Icons.edit_note,
          ),
        ),
      ],
    );
  }

  /// Botón de envío con indicador de carga.
  Widget _buildSubmitButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLoading
          ? Container(
              key: const ValueKey('loading'),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFE67E22),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Enviando registro...',
                      style: TextStyle(
                        color: Color(0xFF636E72),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              key: const ValueKey('button'),
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _enviarFormulario,
                icon: const Icon(Icons.save_outlined, size: 22),
                label: const Text('Guardar Registro'),
              ),
            ),
    );
  }

  // ── Decoración reutilizable para los inputs ───────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB2BEC3)),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFFE67E22)),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        color: Color(0xFFE67E22),
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE67E22), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE74C3C)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  W I D G E T   A U X I L I A R :  E T I Q U E T A   D E   C A M P O
// ═════════════════════════════════════════════════════════════════════════════

/// Etiqueta consistente para cada campo del formulario.
class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FieldLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2D3436)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }
}

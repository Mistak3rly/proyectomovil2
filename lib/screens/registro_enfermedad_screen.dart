import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/enfermedad_model.dart';
import '../models/lote_model.dart';
import '../services/enfermedad_service.dart';

const _enfermedadesComunes = [
  'Coccidiosis',
  'Coriza Infecciosa',
  'Newcastle',
  'Gumboro',
  'Marek',
  'Bronquitis Infecciosa',
  'Salmonelosis',
  'Diarrea',
  'Aerosaculitis',
  'Micoplasmosis',
];

const _colores = {
  'activo': Color(0xFFDC3545),
  'en_tratamiento': Color(0xFFFD7E14),
  'resuelto': Color(0xFF198754),
};

const _etiquetas = {
  'activo': 'Activo',
  'en_tratamiento': 'En Tratamiento',
  'resuelto': 'Resuelto',
};

// ── Screen principal ──────────────────────────────────────────────────────────

class RegistroEnfermedadScreen extends StatefulWidget {
  const RegistroEnfermedadScreen({super.key});

  @override
  State<RegistroEnfermedadScreen> createState() =>
      _RegistroEnfermedadScreenState();
}

class _RegistroEnfermedadScreenState extends State<RegistroEnfermedadScreen> {
  final _service = EnfermedadService();
  List<LoteModel> _lotes = [];
  List<EnfermedadModel> _enfermedades = [];
  bool _cargando = true;
  String? _error;
  String? _filtroLoteId;
  String? _filtroEstado;
  DateTime? _filtroFechaInicio;
  DateTime? _filtroFechaFin;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lotes = await _service.getLotesActivos();
      final enfermedades = await _service.getEnfermedades();
      setState(() {
        _lotes = lotes;
        _enfermedades = enfermedades;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  List<EnfermedadModel> get _enfermedadesFiltradas {
    return _enfermedades.where((e) {
      if (_filtroLoteId != null && e.lote.toString() != _filtroLoteId)
        return false;
      if (_filtroEstado != null && e.estadoEnfermedad != _filtroEstado)
        return false;
      if (_filtroFechaInicio != null &&
          e.fechaRegistro != null &&
          e.fechaRegistro!.isBefore(_filtroFechaInicio!))
        return false;
      if (_filtroFechaFin != null &&
          e.fechaRegistro != null &&
          e.fechaRegistro!.isAfter(
            _filtroFechaFin!.add(const Duration(days: 1)),
          ))
        return false;
      return true;
    }).toList();
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroLoteId = null;
      _filtroEstado = null;
      _filtroFechaInicio = null;
      _filtroFechaFin = null;
    });
  }

  void _abrirFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEnfermedad(
        lotes: _lotes,
        service: _service,
        onGuardado: () {
          Navigator.pop(context);
          _cargarDatos();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registro sanitario guardado exitosamente'),
              backgroundColor: Color(0xFF198754),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _enfermedadesFiltradas;
    final hayFiltros =
        _filtroLoteId != null ||
        _filtroEstado != null ||
        _filtroFechaInicio != null ||
        _filtroFechaFin != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Enfermedades por Lote',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _cargarDatos)
          : Column(
              children: [
                // Panel de filtros
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.filter_list,
                            size: 18,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Filtros',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (hayFiltros)
                            TextButton.icon(
                              onPressed: _limpiarFiltros,
                              icon: const Icon(
                                Icons.clear,
                                size: 14,
                                color: Colors.grey,
                              ),
                              label: const Text(
                                'Limpiar',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Fila 1: Lote + Estado
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filtroLoteId,
                              decoration: _filterDec('Lote'),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Todos'),
                                ),
                                ..._lotes.map(
                                  (l) => DropdownMenuItem(
                                    value: l.id.toString(),
                                    child: Text('Lote ${l.id}'),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _filtroLoteId = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filtroEstado,
                              decoration: _filterDec('Estado'),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('Todos'),
                                ),
                                DropdownMenuItem(
                                  value: 'activo',
                                  child: Text('Activo'),
                                ),
                                DropdownMenuItem(
                                  value: 'en_tratamiento',
                                  child: Text('En trat.'),
                                ),
                                DropdownMenuItem(
                                  value: 'resuelto',
                                  child: Text('Resuelto'),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _filtroEstado = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Fila 2: Fecha inicio + Fecha fin
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _filtroFechaInicio ?? DateTime.now(),
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime.now(),
                                  builder: (ctx, child) => Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.orange,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (d != null) {
                                  setState(() => _filtroFechaInicio = d);
                                }
                              },
                              child: InputDecorator(
                                decoration: _filterDec('Desde'),
                                child: Text(
                                  _filtroFechaInicio != null
                                      ? DateFormat(
                                          'dd/MM/yy',
                                        ).format(_filtroFechaInicio!)
                                      : 'Desde',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _filtroFechaInicio != null
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _filtroFechaFin ?? DateTime.now(),
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime.now(),
                                  builder: (ctx, child) => Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.orange,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (d != null) {
                                  setState(() => _filtroFechaFin = d);
                                }
                              },
                              child: InputDecorator(
                                decoration: _filterDec('Hasta'),
                                child: Text(
                                  _filtroFechaFin != null
                                      ? DateFormat(
                                          'dd/MM/yy',
                                        ).format(_filtroFechaFin!)
                                      : 'Hasta',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _filtroFechaFin != null
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${filtradas.length} registro(s) encontrado(s)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Lista filtrada
                Expanded(child: _ListaEnfermedades(enfermedades: filtradas)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar enfermedad'),
      ),
    );
  }

  InputDecoration _filterDec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    isDense: true,
  );
}

// ── Lista ─────────────────────────────────────────────────────────────────────

class _ListaEnfermedades extends StatelessWidget {
  final List<EnfermedadModel> enfermedades;
  const _ListaEnfermedades({required this.enfermedades});

  @override
  Widget build(BuildContext context) {
    if (enfermedades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No hay enfermedades registradas',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: enfermedades.length,
      itemBuilder: (context, i) => _TarjetaEnfermedad(e: enfermedades[i]),
    );
  }
}

class _TarjetaEnfermedad extends StatelessWidget {
  final EnfermedadModel e;
  const _TarjetaEnfermedad({required this.e});

  @override
  Widget build(BuildContext context) {
    final color = _colores[e.estadoEnfermedad] ?? Colors.grey;
    final etiqueta = _etiquetas[e.estadoEnfermedad] ?? e.estadoEnfermedad;
    final fecha = e.fechaRegistro != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(e.fechaRegistro!.toLocal())
        : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Lote ${e.lote}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    etiqueta,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.coronavirus_outlined,
                  size: 18,
                  color: Colors.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    e.enfermedadSintoma.isNotEmpty
                        ? e.enfermedadSintoma
                        : 'Sin especificar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (e.cantidadAvesAfectadas != null) ...[
                  const Icon(Icons.pets, size: 15, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${e.cantidadAvesAfectadas} aves',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                ],
                if (e.porcentajeAfectacion != null) ...[
                  const Icon(Icons.percent, size: 15, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${e.porcentajeAfectacion!.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ],
            ),
            if (e.observacion != null && e.observacion!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                e.observacion!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              fecha,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formulario ────────────────────────────────────────────────────────────────

class _FormularioEnfermedad extends StatefulWidget {
  final List<LoteModel> lotes;
  final EnfermedadService service;
  final VoidCallback onGuardado;

  const _FormularioEnfermedad({
    required this.lotes,
    required this.service,
    required this.onGuardado,
  });

  @override
  State<_FormularioEnfermedad> createState() => _FormularioEnfermedadState();
}

class _FormularioEnfermedadState extends State<_FormularioEnfermedad> {
  final _formKey = GlobalKey<FormState>();
  LoteModel? _loteSeleccionado;
  String _enfermedadSintoma = '';
  final _cantidadCtrl = TextEditingController();
  final _porcentajeCtrl = TextEditingController();
  final _observacionCtrl = TextEditingController();
  bool _guardando = false;
  String? _errorMsg;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _porcentajeCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  void _calcularPorcentaje(String cantidadStr) {
    if (_loteSeleccionado == null) return;
    final cantidad = int.tryParse(cantidadStr);
    if (cantidad == null || _loteSeleccionado!.poblacionActual == 0) return;
    final pct = (cantidad / _loteSeleccionado!.poblacionActual * 100)
        .toStringAsFixed(2);
    setState(() => _porcentajeCtrl.text = pct);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loteSeleccionado == null) {
      setState(() => _errorMsg = 'Debe seleccionar un lote para continuar.');
      return;
    }
    if (_enfermedadSintoma.trim().isEmpty) {
      setState(() => _errorMsg = 'El campo de enfermedad es obligatorio.');
      return;
    }
    final cantidad = int.tryParse(_cantidadCtrl.text);
    final porcentaje = double.tryParse(_porcentajeCtrl.text);
    if (cantidad == null && porcentaje == null) {
      setState(
        () => _errorMsg =
            'Ingresa la cantidad de aves afectadas o el porcentaje.',
      );
      return;
    }

    setState(() {
      _guardando = true;
      _errorMsg = null;
    });

    try {
      await widget.service.registrarEnfermedad(
        EnfermedadModel(
          lote: _loteSeleccionado!.id,
          enfermedadSintoma: _enfermedadSintoma.trim(),
          cantidadAvesAfectadas: cantidad,
          porcentajeAfectacion: porcentaje,
          observacion: _observacionCtrl.text.trim(),
        ),
      );
      widget.onGuardado();
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
        _guardando = false;
      });
    }
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registrar enfermedad / problema sanitario',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),

              const Text(
                'Lote afectado *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<LoteModel>(
                value: _loteSeleccionado,
                decoration: _inputDec('Seleccionar lote activo...'),
                items: widget.lotes
                    .map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text(
                          'Lote ${l.id} — ${l.razaTipo} (${l.poblacionActual} aves)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _loteSeleccionado = val;
                    _errorMsg = null;
                    if (_cantidadCtrl.text.isNotEmpty) {
                      _calcularPorcentaje(_cantidadCtrl.text);
                    }
                  });
                },
                validator: (v) => v == null
                    ? 'Debe seleccionar un lote para continuar.'
                    : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Enfermedad o síntoma *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _enfermedadesComunes;
                  }
                  return _enfermedadesComunes.where(
                    (e) => e.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                onSelected: (val) => setState(() => _enfermedadSintoma = val),
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: _inputDec('Ej: Coccidiosis, Coriza...'),
                        onChanged: (val) =>
                            setState(() => _enfermedadSintoma = val),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El campo de enfermedad es obligatorio.'
                            : null,
                      );
                    },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aves afectadas',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cantidadCtrl,
                          decoration: _inputDec('ej: 50'),
                          keyboardType: TextInputType.number,
                          onChanged: _calcularPorcentaje,
                          validator: (v) {
                            if ((v == null || v.isEmpty) &&
                                _porcentajeCtrl.text.isEmpty) {
                              return 'Requerido';
                            }
                            if (v != null &&
                                v.isNotEmpty &&
                                (int.tryParse(v) == null || int.parse(v) < 0)) {
                              return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '% Afectación',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _porcentajeCtrl,
                          decoration: _inputDec('auto'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              final d = double.tryParse(v);
                              if (d == null || d < 0 || d > 100) return '0-100';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Observaciones (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _observacionCtrl,
                decoration: _inputDec('Detalles sobre los síntomas...'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Text(
                '* La fecha y hora se registran automáticamente al guardar.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _guardando ? 'Guardando...' : 'Guardar Registro Sanitario',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'Ocurrió un error al cargar los datos:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

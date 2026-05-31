import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/insumo_model.dart';
import '../models/lote_model.dart';
import '../services/auth_service.dart';
import '../services/sanidad_service.dart';

class SanidadActivitiesScreen extends StatefulWidget {
  const SanidadActivitiesScreen({super.key});

  @override
  State<SanidadActivitiesScreen> createState() =>
      _SanidadActivitiesScreenState();
}

class _SanidadActivitiesScreenState extends State<SanidadActivitiesScreen> {
  static const _primary = Color(0xFFE67E22);

  final _formKey = GlobalKey<FormState>();
  final SanidadService _service = SanidadService();
  final AuthService _authService = AuthService();

  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _dosisController = TextEditingController();
  final TextEditingController _responsableController = TextEditingController();
  final TextEditingController _observacionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _estadoFocusNode = FocusNode();
  final FocusNode _responsableFocusNode = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isOffline = false;

  List<LoteModel> _lotes = const [];
  List<InsumoModel> _insumos = const [];
  List<String> _estadoSuggestions = const [
    'Preventivo',
    'Curativo',
    'Tratamiento',
  ];
  List<String> _userSuggestions = [];
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];

  LoteModel? _selectedLote;
  LoteModel? _filterLote;
  String? _filterTipo;
  InsumoModel? _selectedInsumo;
  String _unidadDosis = 'ml';

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _estadoController.dispose();
    _estadoFocusNode.dispose();
    _responsableFocusNode.dispose();
    _dosisController.dispose();
    _responsableController.dispose();
    _observacionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final username = await _authService.getCurrentUsername();
      if (username != null && username.trim().isNotEmpty) {
        _responsableController.text = username.trim();
      }

      // Si hay conexión, intentamos sincronizar pendientes al abrir.
      try {
        final synced = await _service.syncPendingControlSanitario();
        if (synced > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se sincronizaron $synced registros pendientes.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (mounted) {
          setState(() => _isOffline = false);
        }
      } on SocketException {
        if (mounted) setState(() => _isOffline = true);
      } catch (_) {
        // Ignorar
      }

      List<LoteModel> lotes;
      List<InsumoModel> insumos;

      try {
        lotes = await _service.getActiveLots(allowCache: false);
        insumos = await _service.getSanitarySupplies(allowCache: false);
        if (mounted) setState(() => _isOffline = false);
      } on SocketException {
        if (mounted) setState(() => _isOffline = true);
        lotes = await _service.getActiveLots(allowCache: true);
        insumos = await _service.getSanitarySupplies(allowCache: true);
      }

      lotes = lotes.toList()..sort((a, b) => b.id.compareTo(a.id));
      insumos = insumos.toList()..sort((a, b) => a.nombre.compareTo(b.nombre));

      final suggestions = await _service.getEstadoEnfermedadSuggestions(
        loteId: _selectedLote?.id,
        allowCache: true,
      );

      final users = await _authService.getCompanyUsers();

      if (!mounted) return;
      setState(() {
        _lotes = lotes;
        _insumos = insumos;
        _estadoSuggestions = suggestions.isNotEmpty
            ? suggestions
            : _estadoSuggestions;
        _userSuggestions = users;
      });

      await _loadRecords();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar datos sanitarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecords() async {
    try {
      final recs = await _service.getControlSanitarioRecords(allowCache: true);
      recs.sort((a, b) {
        final fa = a['fecha_aplicacion'] ?? '';
        final fb = b['fecha_aplicacion'] ?? '';
        int comp = fb.compareTo(fa);
        if (comp == 0) {
          final ida = a['id'] ?? 0;
          final idb = b['id'] ?? 0;
          return idb.compareTo(ida);
        }
        return comp;
      });
      if (mounted) {
        setState(() {
          _records = recs;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error cargando registros sanitarios: $e');
    }
  }

  void _applyFilter() {
    _currentPage = 1;
    final query = _searchController.text.toLowerCase().trim();

    _filteredRecords = _records.where((r) {
      if (_filterLote != null && r['lote'] != _filterLote!.id) return false;
      if (_filterTipo != null && r['tipo_tratamiento'] != _filterTipo) return false;

      if (query.isNotEmpty) {
        final insumo = (r['insumo_nombre'] ?? '').toString().toLowerCase();
        final obs = (r['observacion'] ?? '').toString().toLowerCase();
        final tipo = (r['tipo_tratamiento'] ?? '').toString().toLowerCase();
        if (!insumo.contains(query) && !obs.contains(query) && !tipo.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedRecords {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _filteredRecords.length) return [];
    return _filteredRecords.sublist(
        startIndex,
        endIndex > _filteredRecords.length ? _filteredRecords.length : endIndex);
  }

  int get _totalPages => (_filteredRecords.length / _itemsPerPage).ceil();

  String _formatHoy() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String _tipoTratamientoDesdeInsumo(InsumoModel insumo) {
    switch (insumo.tipo) {
      case 'Vacuna':
        return 'Vacuna';
      case 'Medicamento':
        return 'Medicamento';
      default:
        return 'Otro';
    }
  }

  List<String> _unitOptionsFor(InsumoModel? insumo) {
    final set = <String>{'ml', 'g', 'kg', 'U', 'Dosis'};
    if (insumo != null && insumo.unidadMedida.trim().isNotEmpty) {
      set.add(insumo.unidadMedida.trim());
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  bool _isLoteFinalizado(LoteModel? lote) {
    final estado = (lote?.estado ?? '').toLowerCase().trim();
    return estado == 'finalizado';
  }

  double? _parseDouble(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _handleSubmit({int? updateId}) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_selectedLote == null) {
      _snack('Seleccione un lote.', isError: true);
      return;
    }
    if (_isLoteFinalizado(_selectedLote)) {
      _snack('No se puede registrar en un lote finalizado.', isError: true);
      return;
    }
    if (_selectedInsumo == null) {
      _snack('Seleccione un insumo.', isError: true);
      return;
    }

    final dosis = _parseDouble(_dosisController.text);
    if (dosis == null || dosis <= 0) {
      _snack('La dosis debe ser mayor que 0.', isError: true);
      return;
    }

    // Permitir editar sin validar stock si es el mismo insumo
    // Para simplificar, ignoramos validación si es edición
    if (updateId == null) {
      if (_selectedInsumo!.stockActual <= 0) {
        _snack('Stock insuficiente: el insumo está en 0.', isError: true);
        return;
      }
      if (_selectedInsumo!.stockActual < dosis) {
        _snack(
          'Stock insuficiente. Disponible: ${_selectedInsumo!.stockActual.toStringAsFixed(2)} ${_selectedInsumo!.unidadMedida}.',
          isError: true,
        );
        return;
      }
    }

    final payload = <String, dynamic>{
      'lote': _selectedLote!.id,
      'insumo': _selectedInsumo!.id,
      'tipo_tratamiento': _tipoTratamientoDesdeInsumo(_selectedInsumo!),
      'dosis': dosis,
      'unidad_dosis': _unidadDosis,
      'fecha_aplicacion': _formatHoy(),
      'responsable': _responsableController.text.trim(),
      'observacion': _observacionController.text.trim(),
      'estado_enfermedad': _estadoController.text.trim(),
    };

    setState(() {
      _isSaving = true;
    });

    try {
      if (updateId != null) {
        if (_isOffline) {
          _snack('No se puede editar sin conexión', isError: true);
          setState(() => _isSaving = false);
          return;
        }
        await _service.updateControlSanitario(updateId, payload);
        if (!mounted) return;
        _snack('Registro actualizado correctamente.', isError: false);
      } else {
        if (_isOffline) {
          await _service.queueControlSanitario(payload);
          _snack(
            'Guardado localmente. Se sincronizará al volver la conexión.',
            isError: false,
          );
        } else {
          await _service.createControlSanitario(payload);
          if (!mounted) return;
          _snack('Tratamiento registrado correctamente.', isError: false);
        }
      }
      _clearForm();
      Navigator.of(context).pop();
      await _loadRecords();
    } on SocketException {
      if (!mounted) return;
      setState(() => _isOffline = true);
      if (updateId == null) {
        await _service.queueControlSanitario(payload);
        _snack(
          'Sin conexión: se guardó localmente y se sincronizará luego.',
          isError: false,
        );
      } else {
        _snack('Error de red al actualizar.', isError: true);
      }
      _clearForm();
      Navigator.of(context).pop();
      await _loadRecords();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _clearForm() {
    _estadoController.clear();
    _dosisController.clear();
    _observacionController.clear();
    setState(() {
      _selectedInsumo = null;
      _unidadDosis = 'ml';
    });
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _deleteRecord(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: const Text('¿Estás seguro de eliminar este registro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (conf != true) return;
    setState(() => _isLoading = true);
    try {
      await _service.deleteControlSanitario(id);
      _snack('Registro eliminado', isError: false);
      await _loadRecords();
    } catch (e) {
      _snack('Error al eliminar: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRegisterModal([Map<String, dynamic>? recordToEdit]) {
    _clearForm();
    if (recordToEdit != null) {
      _selectedLote = _lotes.firstWhere((l) => l.id == recordToEdit['lote'], orElse: () => _lotes.first);
      try {
        _selectedInsumo = _insumos.firstWhere((i) => i.nombre == recordToEdit['insumo_nombre']);
      } catch (_) {}
      _dosisController.text = recordToEdit['dosis']?.toString() ?? '';
      _unidadDosis = recordToEdit['unidad_dosis'] ?? 'ml';
      _responsableController.text = recordToEdit['responsable'] ?? '';
      _observacionController.text = recordToEdit['observacion'] ?? '';
      _estadoController.text = recordToEdit['estado_enfermedad'] ?? '';
    } else {
      if (_lotes.isNotEmpty && _selectedLote == null) {
        _selectedLote = _lotes.first;
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final lote = _selectedLote;
            final raza = lote?.razaTipo ?? '—';
            final edad = lote != null ? '${lote.diasDeVida}' : '—';

            final insumo = _selectedInsumo;
            final stockTxt = insumo == null
                ? '—'
                : '${insumo.stockActual.toStringAsFixed(2)} ${insumo.unidadMedida}';
            final stockColor = (insumo?.stockActual ?? 0) <= 0
                ? Colors.red
                : (insumo?.bajoStock ?? false)
                ? Colors.orange
                : Colors.green;

            final unitOptions = _unitOptionsFor(insumo);
            if (!unitOptions.contains(_unidadDosis)) {
              _unidadDosis = unitOptions.first;
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        recordToEdit == null ? 'Registrar Aplicación Sanitaria' : 'Editar Aplicación Sanitaria',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<LoteModel>(
                        decoration: const InputDecoration(
                          labelText: 'Lote',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedLote,
                        items: _lotes
                            .map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text(
                                  '${l.nombre} • ${l.estado ?? ''}'.trim(),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (val) async {
                                setModalState(() {
                                  _selectedLote = val;
                                });
                                final suggestions = await _service
                                    .getEstadoEnfermedadSuggestions(
                                      loteId: val?.id,
                                      allowCache: true,
                                    );
                                setModalState(() {
                                  _estadoSuggestions = suggestions.isNotEmpty
                                      ? suggestions
                                      : _estadoSuggestions;
                                });
                              },
                        validator: (value) =>
                            value == null ? 'Seleccione un lote' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Raza',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                raza.isEmpty ? '—' : raza,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Edad (días)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                edad,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      RawAutocomplete<String>(
                        textEditingController: _estadoController,
                        focusNode: _estadoFocusNode,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text
                              .trim()
                              .toLowerCase();
                          if (query.isEmpty)
                            return const Iterable<String>.empty();
                          return _estadoSuggestions.where(
                            (o) => o.toLowerCase().contains(query),
                          );
                        },
                        displayStringForOption: (o) => o,
                        onSelected: (value) {
                          _estadoController.text = value;
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Enfermedad / Sintomatología',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingrese o seleccione una opción';
                                  }
                                  return null;
                                },
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 180,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      title: Text(option),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<InsumoModel>(
                        decoration: const InputDecoration(
                          labelText: 'Insumo',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedInsumo,
                        items: _insumos
                            .map(
                              (i) => DropdownMenuItem(
                                value: i,
                                child: Text('${i.nombre} • ${i.tipo}'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setModalState(() {
                            _selectedInsumo = val;
                            if (val != null &&
                                val.unidadMedida.trim().isNotEmpty) {
                              _unidadDosis = val.unidadMedida.trim();
                            }
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Seleccione un insumo' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Stock disponible: ',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            stockTxt,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: stockColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _dosisController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Dosis',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Ingrese la dosis';
                                final d = _parseDouble(v);
                                if (d == null || d <= 0) return 'Debe ser > 0';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Unidad',
                                border: OutlineInputBorder(),
                              ),
                              value: _unidadDosis,
                              items: unitOptions
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setModalState(() => _unidadDosis = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      RawAutocomplete<String>(
                        textEditingController: _responsableController,
                        focusNode: _responsableFocusNode,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text.trim().toLowerCase();
                          if (query.isEmpty) return const Iterable<String>.empty();
                          return _userSuggestions.where(
                            (u) => u.toLowerCase().contains(query),
                          );
                        },
                        displayStringForOption: (o) => o,
                        onSelected: (value) {
                          _responsableController.text = value;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Responsable',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Campo requerido';
                              }
                              return null;
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 180,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      title: Text(option),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _observacionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones (Opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  setModalState(() => _isSaving = true);
                                  await _handleSubmit(updateId: recordToEdit?['id']);
                                  setModalState(() => _isSaving = false);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isOffline ? 'Guardar Localmente' : 'Guardar',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final tipo = record['tipo_tratamiento'] ?? 'Otro';
    final insumoNombre = record['insumo_nombre'] ?? 'Insumo N/A';
    final dosis = record['dosis'] ?? '0';
    final unidad = record['unidad_dosis'] ?? '';
    final fecha = record['fecha_aplicacion'] ?? '';
    final responsable = record['responsable'] ?? 'Desconocido';
    final observacion = record['observacion'] ?? '';
    final estadoEnfermedad = record['estado_enfermedad'] ?? '';
    final loteId = record['lote'];

    final loteObj = _lotes.firstWhere(
      (l) => l.id == loteId,
      orElse: () => LoteModel(
        id: loteId ?? 0,
        nombre: 'Lote $loteId',
        idGalpon: 0,
        razaTipo: '—',
        poblacionInicial: 0,
        poblacionActual: 0,
        diasDeVida: 0,
        fechaIngreso: DateTime.now(),
        estado: '',
      ),
    );
    final loteNombre = loteObj.nombre;

    Color badgeColor;
    switch (tipo.toString().toLowerCase()) {
      case 'vacuna':
        badgeColor = Colors.teal;
        break;
      case 'medicamento':
        badgeColor = Colors.redAccent;
        break;
      case 'vitamina':
        badgeColor = Colors.blue;
        break;
      default:
        badgeColor = Colors.orange;
    }

    Color stateColor;
    switch (estadoEnfermedad.toString().toLowerCase()) {
      case 'preventivo':
        stateColor = Colors.green;
        break;
      case 'en tratamiento':
      case 'tratamiento':
        stateColor = Colors.orange;
        break;
      case 'recuperado':
        stateColor = Colors.teal;
        break;
      case 'crítico':
      case 'critico':
        stateColor = Colors.red;
        break;
      default:
        stateColor = Colors.blueGrey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    insumoNombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                      onPressed: () => _showRegisterModal(record),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                      onPressed: () => _deleteRecord(record['id']),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tipo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.widgets_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Lote: $loteNombre',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const Spacer(),
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  responsable,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dosis: $dosis $unidad',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stateColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estadoEnfermedad,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stateColor,
                    ),
                  ),
                ),
              ],
            ),
            if (observacion.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                observacion,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  fecha,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrar Tratamientos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por insumo, observación...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _applyFilter();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<LoteModel?>(
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por Lote',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        isExpanded: true,
                        value: _filterLote,
                        items: [
                          const DropdownMenuItem<LoteModel?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ..._lotes.map(
                            (l) => DropdownMenuItem<LoteModel?>(
                              value: l,
                              child: Text(l.nombre),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _filterLote = val;
                            _applyFilter();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        isExpanded: true,
                        value: _filterTipo,
                        items: const [
                          DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                          DropdownMenuItem<String?>(value: 'Vacuna', child: Text('Vacunas')),
                          DropdownMenuItem<String?>(value: 'Medicamento', child: Text('Medicamentos')),
                          DropdownMenuItem<String?>(value: 'Vitamina', child: Text('Vitaminas')),
                          DropdownMenuItem<String?>(value: 'Desparasitante', child: Text('Desparasitantes')),
                          DropdownMenuItem<String?>(value: 'Suministro', child: Text('Suministros')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _filterTipo = val;
                            _applyFilter();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: _primary.withOpacity(0.12),
              child: const Text(
                'Modo Offline: Los datos se sincronizarán cuando la conexión retorne.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadRecords,
                    child: _filteredRecords.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                              ),
                              Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 80,
                                color: Colors.grey.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              const Center(
                                child: Text(
                                  'No hay registros sanitarios',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Center(
                                child: Text(
                                  'Toca "+" para registrar una aplicación.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _paginatedRecords.length,
                            itemBuilder: (context, index) {
                              return _buildRecordCard(_paginatedRecords[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterModal,
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Registrar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: _totalPages > 1
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Text(
                      'Página $_currentPage de $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

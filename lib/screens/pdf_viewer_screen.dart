import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import '../services/pdf_generator_service.dart';
import 'add_edit_record_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final Vehicle vehicle;
  final ServiceRecord record;
  final StorageService storageService;

  const PdfViewerScreen({
    super.key,
    required this.vehicle,
    required this.record,
    required this.storageService,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late ServiceRecord _record;
  late Vehicle _vehicle;
  int _refreshKey = 0;
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _vehicle = widget.vehicle;
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  void _zoomIn() {
    final target = (_currentScale + 0.5).clamp(1.0, 5.0);
    _setZoom(target);
  }

  void _zoomOut() {
    final target = (_currentScale - 0.5).clamp(1.0, 5.0);
    _setZoom(target);
  }

  void _setZoom(double scale) {
    setState(() {
      _transformationController.value = Matrix4.diagonal3Values(scale, scale, 1.0);
      _currentScale = scale;
    });
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.2) {
      _resetZoom();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      const targetScale = 2.0;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);
      final matrix = Matrix4.identity()
        ..translateByDouble(x, y, 0.0, 1.0)
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
      setState(() {
        _transformationController.value = matrix;
        _currentScale = targetScale;
      });
    }
  }

  Future<Uint8List> _getOrGeneratePdf() async {
    // If a saved PDF exists on disk, load it; otherwise generate fresh
    if (_record.pdfPath != null) {
      final file = File(_record.pdfPath!);
      if (await file.exists()) {
        try {
          return await file.readAsBytes();
        } catch (_) {}
      }
    }

    return await PdfGeneratorService.generateServiceReport(
      vehicle: _vehicle,
      record: _record,
    );
  }

  Future<void> _navigateToEditRecord() async {
    final updatedRecord = await Navigator.of(context).push<ServiceRecord>(
      MaterialPageRoute(
        builder: (context) => AddEditRecordScreen(
          vehicle: _vehicle,
          storageService: widget.storageService,
          recordToEdit: _record,
        ),
      ),
    );

    if (updatedRecord != null && mounted) {
      final updatedVehicle = widget.storageService.getVehicleById(_vehicle.id) ?? _vehicle;
      setState(() {
        _record = updatedRecord;
        _vehicle = updatedVehicle;
        _refreshKey++;
        _resetZoom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _record.serviceName.isEmpty ? 'Service Report' : _record.serviceName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _vehicle.name,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print Report',
            onPressed: () async {
              final bytes = await _getOrGeneratePdf();
              await Printing.layoutPdf(
                onLayout: (_) => bytes,
                name: 'Rido_Service_Report_${_record.id.length > 8 ? _record.id.substring(0, 8) : _record.id}.pdf',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Report',
            onPressed: () async {
              final bytes = await _getOrGeneratePdf();
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'Rido_Service_Report_${_record.id.length > 8 ? _record.id.substring(0, 8) : _record.id}.pdf',
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          KeyedSubtree(
            key: ValueKey(_refreshKey),
            child: PdfPreview.builder(
              build: (format) => _getOrGeneratePdf(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              dpi: 160,
              maxPageWidth: 700,
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              actions: const [],
              initialPageFormat: PdfPageFormat.a4,
              pagesBuilder: (context, pages) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth > 700 ? 700.0 : constraints.maxWidth;
                    return GestureDetector(
                      onDoubleTapDown: (details) => _doubleTapDetails = details,
                      onDoubleTap: _handleDoubleTap,
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0,
                        maxScale: 5.0,
                        panEnabled: true,
                        scaleEnabled: true,
                        boundaryMargin: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 90,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxWidth),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: pages.map((page) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.18),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image(
                                      image: page.image,
                                      fit: BoxFit.contain,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Floating Zoom Pill Controls (Above Green Belt)
          Positioned(
            bottom: (56.0 + MediaQuery.of(context).padding.bottom) + 14,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      tooltip: 'Zoom Out',
                      onPressed: _currentScale > 1.05 ? _zoomOut : null,
                      visualDensity: VisualDensity.compact,
                    ),
                    GestureDetector(
                      onTap: _resetZoom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          '${(_currentScale * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      tooltip: 'Zoom In',
                      onPressed: _currentScale < 4.95 ? _zoomIn : null,
                      visualDensity: VisualDensity.compact,
                    ),
                    if (_currentScale > 1.1) ...[
                      Container(
                        height: 16,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      IconButton(
                        icon: const Icon(Icons.fit_screen_rounded, size: 18),
                        tooltip: 'Fit to Screen',
                        onPressed: _resetZoom,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Pencil Edit Button (Positioned Above Green Belt)
          Positioned(
            bottom: (56.0 + MediaQuery.of(context).padding.bottom) + 10,
            right: 16,
            child: FloatingActionButton(
              onPressed: _navigateToEditRecord,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 6,
              tooltip: 'Edit Service Record',
              child: const Icon(Icons.edit_rounded, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

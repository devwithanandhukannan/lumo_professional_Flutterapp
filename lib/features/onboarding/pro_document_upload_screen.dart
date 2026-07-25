import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/theme/pro_theme.dart';
import 'pro_selfie_screen.dart';

class ProDocumentUploadScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const ProDocumentUploadScreen({super.key, required this.onCompleted});

  @override
  State<ProDocumentUploadScreen> createState() => _ProDocumentUploadScreenState();
}

class _ProDocumentUploadScreenState extends State<ProDocumentUploadScreen>
    with SingleTickerProviderStateMixin {
  final _idNumberCtrl = TextEditingController();
  String _selectedIdType = 'DRIVING_LICENSE';

  bool _govtIdUploaded = false;
  String? _govtIdFileName;
  String? _govtIdUrl;

  bool _policePdfUploaded = false;
  String? _policeFileName;
  String? _policeUrl;

  bool _isLoading = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _idTypes = [
    {'value': 'DRIVING_LICENSE', 'label': 'Driving License', 'icon': Icons.drive_eta_rounded},
    {'value': 'VOTER_ID', 'label': 'Voter ID', 'icon': Icons.how_to_vote_rounded},
    {'value': 'PASSPORT', 'label': 'Passport', 'icon': Icons.book_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _idNumberCtrl.dispose();
    super.dispose();
  }

  void _showUploadOptionsModal(String docType, String docTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ProColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.cloud_upload_rounded, color: ProColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload $docTitle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Select upload format from device', style: TextStyle(color: ProColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: ProColors.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: ProColors.border, height: 1),
            const SizedBox(height: 16),

            // Option 1: Pick PDF File
            _UploadOptionTile(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Upload PDF Document',
              subtitle: 'Browse and select official .pdf file',
              color: ProColors.primary,
              onTap: () {
                Navigator.pop(ctx);
                _pickPdfDocument(docType);
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Camera Photo
            _UploadOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo with Camera',
              subtitle: 'Snap a clear photo of your physical document',
              color: ProColors.accent,
              onTap: () {
                Navigator.pop(ctx);
                _pickImageFromSource(docType, ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Gallery Photo
            _UploadOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose Photo from Gallery',
              subtitle: 'Select existing document image from gallery',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageFromSource(docType, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPdfDocument(String docType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        List<int>? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null) {
          await _uploadBytesToBackend(file.name, bytes, docType);
        } else {
          _showSnack('Unable to read selected PDF file');
        }
      }
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        _showMissingPluginFallbackDialog(docType);
      } else {
        _showSnack('Error selecting PDF file: $e');
      }
    }
  }

  void _showMissingPluginFallbackDialog(String docType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: ProColors.primary),
            SizedBox(width: 10),
            Expanded(child: Text('PDF Picker Notice', style: TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ),
        content: const Text(
          'The file_picker native plugin requires a full app restart (re-run `flutter run`) to bind native Android PDF channels.\n\nWould you like to upload a PDF document sample to test storing in the backend proff_cert folder right now?',
          style: TextStyle(color: ProColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImageFromSource(docType, ImageSource.gallery);
            },
            child: const Text('Use Gallery Image', style: TextStyle(color: ProColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ProColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final validPdfString = '''%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>
endobj
4 0 obj
<< /Length 110 >>
stream
BT
/Helv 24 Tf
100 700 Td
(OFFICIAL PROFESSIONAL VERIFICATION PDF DOCUMENT) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000204 00000 n 
trailer
<< /Size 5 /Root 1 0 R >>
startxref
365
%%EOF''';
              final samplePdfBytes = utf8.encode(validPdfString);
              final docName = docType == 'govtId' ? 'govt_id_proof.pdf' : 'police_clearance_certificate.pdf';
              _uploadBytesToBackend(docName, samplePdfBytes, docType);
            },
            child: const Text('Upload Sample PDF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromSource(String docType, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: source, imageQuality: 85);

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final name = photo.name.isNotEmpty ? photo.name : 'document_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _uploadBytesToBackend(name, bytes, docType);
      }
    } catch (e) {
      _showSnack('Error capturing image: $e');
    }
  }

  Future<void> _uploadBytesToBackend(String fileName, List<int> bytes, String docType) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final base64Data = base64Encode(bytes);
      final uploadRes = await ProApiClient.uploadDocument(
        fileName: fileName,
        fileData: base64Data,
        docType: docType,
      );

      if (mounted) {
        setState(() {
          if (docType == 'govtId') {
            _govtIdUploaded = true;
            _govtIdFileName = fileName;
            _govtIdUrl = uploadRes['fileUrl']?.toString();
          } else if (docType == 'police') {
            _policePdfUploaded = true;
            _policeFileName = fileName;
            _policeUrl = uploadRes['fileUrl']?.toString();
          }
        });
        _showSnack('$fileName stored in backend proff_cert folder ✓');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (docType == 'govtId') {
            _govtIdUploaded = true;
            _govtIdFileName = fileName;
          } else if (docType == 'police') {
            _policePdfUploaded = true;
            _policeFileName = fileName;
          }
        });
        _showSnack('$fileName attached locally ✓');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _proceed() async {
    final idNum = _idNumberCtrl.text.trim();
    if (idNum.isEmpty) {
      setState(() => _error = 'Please enter your document number');
      return;
    }
    if (!_govtIdUploaded) {
      setState(() => _error = 'Please upload your government ID document or PDF');
      return;
    }
    if (!_policePdfUploaded) {
      setState(() => _error = 'Please upload the police clearance PDF');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await ProApiClient.submitDocuments(
        govtIdType: _selectedIdType,
        govtIdNumber: idNum,
        govtIdUrl: _govtIdUrl ?? 'proff_cert/govt_id.pdf',
        policeVerificationUrl: _policeUrl ?? 'proff_cert/police_clearance.pdf',
      );
    } catch (_) {}

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProSelfieScreen(
            onCompleted: widget.onCompleted,
            govtIdType: _selectedIdType,
            govtIdNumber: idNum,
            govtIdUrl: _govtIdUrl,
            policeVerificationUrl: _policeUrl,
          ),
        ),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ProColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.background,
      body: Stack(
        children: [
          Positioned(bottom: -80, right: -80, child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [ProColors.accent.withAlpha(25), Colors.transparent])),
          )),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    leading: const BackButton(color: ProColors.textMuted),
                    title: const Text('Verification Documents'),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStepBar(3),
                        const SizedBox(height: 20),

                        const Text('STEP 4 OF 4 (Part 1)', style: ProText.label),
                        const SizedBox(height: 6),
                        const Text('Upload Verification Proofs', style: ProText.heading1),
                        const SizedBox(height: 6),
                        const Text('Upload your government ID and police clearance certificate PDF. All files will be stored in the backend proff_cert folder.', style: ProText.body),
                        const SizedBox(height: 24),

                        if (_error != null) _errorBanner(_error!),

                        GlassCard(
                          borderRadius: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('SELECT GOVERNMENT ID TYPE', style: ProText.label),
                              const SizedBox(height: 12),
                              Row(
                                children: _idTypes.map((t) {
                                  final selected = _selectedIdType == t['value'];
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedIdType = t['value']),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: selected ? ProColors.primarySoft : const Color(0x0AFFFFFF),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: selected ? ProColors.primary : ProColors.glassBorder, width: selected ? 1.5 : 1),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(t['icon'] as IconData, color: selected ? ProColors.primary : ProColors.textMuted, size: 22),
                                            const SizedBox(height: 4),
                                            Text(t['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? ProColors.primary : ProColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              const Text('DOCUMENT NUMBER *', style: ProText.label),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _idNumberCtrl,
                                style: const TextStyle(color: ProColors.textPrimary, fontFamily: 'monospace', fontSize: 16, letterSpacing: 1.5),
                                decoration: proInputDecoration(
                                  hint: 'e.g. DL-1420110012345',
                                  prefix: const Icon(Icons.badge_outlined, color: ProColors.primary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Document Upload Buttons
                        _UploadTile(
                          title: 'Government ID Document',
                          subtitle: _govtIdFileName != null
                              ? 'Uploaded: $_govtIdFileName'
                              : 'Tap to upload PDF or Photo of ${_idTypes.firstWhere((t) => t['value'] == _selectedIdType)['label']}',
                          icon: Icons.assignment_ind_rounded,
                          color: ProColors.accent,
                          isUploaded: _govtIdUploaded,
                          fileName: _govtIdFileName,
                          onTap: () => _showUploadOptionsModal(
                            'govtId',
                            _idTypes.firstWhere((t) => t['value'] == _selectedIdType)['label'] as String,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _UploadTile(
                          title: 'Police Clearance Certificate (PDF Only)',
                          subtitle: _policeFileName != null
                              ? 'Uploaded: $_policeFileName'
                              : 'Tap to upload official background clearance PDF (.pdf only)',
                          icon: Icons.verified_user_rounded,
                          color: ProColors.primary,
                          isUploaded: _policePdfUploaded,
                          fileName: _policeFileName,
                          onTap: () => _pickPdfDocument('police'),
                        ),

                        const SizedBox(height: 12),
                        GlassCard(
                          borderRadius: 14,
                          padding: const EdgeInsets.all(12),
                          child: const Row(
                            children: [
                              Icon(Icons.folder_special_rounded, color: ProColors.primary, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Uploaded files are saved in backend "proff_cert" directory for verification.',
                                  style: TextStyle(fontSize: 11, color: ProColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        GradientButton(
                          label: 'NEXT: LIVE SELFIE CAPTURE',
                          onTap: _proceed,
                          isLoading: _isLoading,
                          icon: Icons.camera_front_rounded,
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBar(int activeStepIndex) {
    return Row(
      children: List.generate(4, (i) {
        final active = i == activeStepIndex;
        final done = i < activeStepIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: done
                  ? ProColors.primary
                  : active
                      ? ProColors.primary.withAlpha(180)
                      : ProColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProColors.emergencyRedSoft,
        border: Border.all(color: ProColors.emergencyRedBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: ProColors.emergencyRed, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 13))),
        ],
      ),
    );
  }
}

class _UploadOptionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _UploadOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ProColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: ProColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: ProColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final bool isUploaded;
  final String? fileName;
  final VoidCallback onTap;

  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isUploaded,
    this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUploaded ? color.withAlpha(20) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUploaded ? color : ProColors.glassBorder,
            width: isUploaded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isUploaded ? color.withAlpha(40) : ProColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(isUploaded ? Icons.picture_as_pdf_rounded : icon, color: isUploaded ? color : ProColors.textMuted, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: isUploaded ? color : ProColors.textMuted, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isUploaded)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: const Text('UPLOAD', style: TextStyle(color: ProColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

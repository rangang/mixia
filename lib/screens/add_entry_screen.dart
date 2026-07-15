import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/password_entry.dart';
import '../models/entry_type_config.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../utils/password_generator.dart';
import '../utils/responsive.dart';
import 'password_generator_screen.dart';

class AddEntryScreen extends StatefulWidget {
  final PasswordEntry? entry;

  const AddEntryScreen({super.key, this.entry});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _obscureFields = {};

  late EntryType _selectedType;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.entry != null;
    if (_isEditing) {
      _selectedType = widget.entry!.type;
    } else {
      _selectedType = EntryType.login;
    }
    _initControllers();
  }

  void _initControllers() {
    _controllers.clear();
    _obscureFields.clear();

    final fields = EntryTypes.getFields(_selectedType);
    for (final field in fields) {
      final controller = TextEditingController();
      if (_isEditing && widget.entry != null) {
        controller.text = widget.entry!.getField(field.key);
      }
      _controllers[field.key] = controller;
      _obscureFields[field.key] = field.isSensitive;
    }

    if (!_isEditing) {
      _controllers['title']?.text = '';
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(EntryType newType) {
    if (_isEditing) return;
    setState(() {
      _selectedType = newType;
      final oldValues = <String, String>{};
      for (final entry in _controllers.entries) {
        oldValues[entry.key] = entry.value.text;
        entry.value.dispose();
      }
      _initControllers();
      for (final entry in oldValues.entries) {
        if (_controllers.containsKey(entry.key)) {
          _controllers[entry.key]?.text = entry.value;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑条目' : '添加条目'),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Responsive(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _buildFormFields(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: SizedBox(
        width: 700,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: ResponsivePadding.all(context),
            children: _buildFormFields(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    final fields = EntryTypes.getFields(_selectedType);
    final widgets = <Widget>[];

    if (!_isEditing) {
      widgets.add(_buildTypeSelector());
      widgets.add(const SizedBox(height: 24));
    }

    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      widgets.add(_buildField(field));
      if (i < fields.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }

    widgets.add(const SizedBox(height: 8));
    if (_hasPasswordField()) {
      widgets.add(_buildPasswordStrengthIndicator());
    }

    widgets.add(const SizedBox(height: 32));
    widgets.add(
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveEntry,
          child: Text(_isEditing ? '更新' : '保存'),
        ),
      ),
    );

    if (!_isEditing && _hasPasswordField()) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PasswordGeneratorScreen(),
                ),
              ).then((password) {
                if (password != null) {
                  final pwController = _getPasswordController();
                  if (pwController != null) {
                    pwController.text = password;
                    setState(() {});
                  }
                }
              });
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('高级密码生成器'),
          ),
        ),
      );
    }

    return widgets;
  }

  bool _hasPasswordField() {
    final fields = EntryTypes.getFields(_selectedType);
    return fields.any((f) => f.fieldType == EntryFieldType.password);
  }

  TextEditingController? _getPasswordController() {
    final fields = EntryTypes.getFields(_selectedType);
    for (final field in fields) {
      if (field.fieldType == EntryFieldType.password || field.isSensitive) {
        return _controllers[field.key];
      }
    }
    return _controllers['password'];
  }

  Widget _buildField(EntryFieldConfig field) {
    final controller = _controllers[field.key];
    if (controller == null) return const SizedBox.shrink();

    final isSensitive = field.isSensitive;
    final isMultiline = field.fieldType == EntryFieldType.multiline;
    final isObscure = isSensitive && !isMultiline && (_obscureFields[field.key] ?? true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          maxLines: isMultiline ? 4 : 1,
          keyboardType: _getKeyboardType(field.fieldType),
          inputFormatters: _getInputFormatters(field.fieldType),
          decoration: InputDecoration(
            labelText: field.required ? '${field.label} *' : field.label,
            hintText: isMultiline && isSensitive ? '${field.hint}（敏感信息，请注意保存）' : field.hint,
            prefixIcon: Icon(field.icon),
            suffixIcon: isSensitive && !isMultiline
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isObscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.muted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureFields[field.key] = !isObscure;
                          });
                        },
                      ),
                      if (field.fieldType == EntryFieldType.password)
                        IconButton(
                          icon: const Icon(Icons.casino, color: AppColors.accent),
                          tooltip: '生成密码',
                          onPressed: () {
                            final password = PasswordGenerator.generate(length: 16);
                            controller.text = password;
                            setState(() {});
                          },
                        ),
                    ],
                  )
                : isMultiline && isSensitive
                    ? const Tooltip(
                        message: '此为敏感信息',
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.security, color: AppColors.warning, size: 20),
                        ),
                      )
                    : null,
            alignLabelWithHint: isMultiline,
          ),
          validator: field.required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入${field.label}';
                  }
                  return null;
                }
              : null,
          onChanged: (_) {
            if (field.fieldType == EntryFieldType.password) {
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  TextInputType _getKeyboardType(EntryFieldType type) {
    switch (type) {
      case EntryFieldType.email:
        return TextInputType.emailAddress;
      case EntryFieldType.url:
        return TextInputType.url;
      case EntryFieldType.phone:
        return TextInputType.phone;
      case EntryFieldType.number:
        return TextInputType.number;
      case EntryFieldType.multiline:
        return TextInputType.multiline;
      case EntryFieldType.cardNumber:
        return TextInputType.number;
      case EntryFieldType.cvv:
      case EntryFieldType.pin:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? _getInputFormatters(EntryFieldType type) {
    switch (type) {
      case EntryFieldType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case EntryFieldType.cardNumber:
        return [
          FilteringTextInputFormatter.digitsOnly,
          _CardNumberFormatter(),
          LengthLimitingTextInputFormatter(19),
        ];
      case EntryFieldType.cvv:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ];
      case EntryFieldType.pin:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ];
      default:
        return null;
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<VaultProvider>();
    final fields = EntryTypes.getFields(_selectedType);

    if (_isEditing) {
      final updated = widget.entry!;
      for (final field in fields) {
        final value = _controllers[field.key]?.text ?? '';
        updated.setField(field.key, value);
      }
      updated.updatedAt = DateTime.now();
      await provider.updateEntry(updated);
    } else {
      final newEntry = PasswordEntry(
        type: _selectedType,
        title: _controllers['title']?.text ?? '',
      );
      for (final field in fields) {
        final value = _controllers[field.key]?.text ?? '';
        newEntry.setField(field.key, value);
      }
      await provider.addEntry(newEntry);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildTypeSelector() {
    final allTypes = EntryType.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '条目类型',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 5 : 4;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: allTypes.map((type) {
                return _buildTypeChip(type);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeChip(EntryType type) {
    final config = EntryTypes.getConfig(type);
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => _onTypeChanged(type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? config.color.withOpacity(0.15)
              : AppColors.bg3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? config.color : AppColors.rule,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              config.icon,
              color: isSelected ? config.color : AppColors.muted,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              config.label,
              style: TextStyle(
                color: isSelected ? config.color : AppColors.muted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final pwController = _getPasswordController();
    final password = pwController?.text ?? '';
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = PasswordGenerator.calculateStrength(password);
    final label = PasswordGenerator.getStrengthLabel(strength);
    final color = _getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '密码强度',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength,
            backgroundColor: AppColors.rule,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.3) return AppColors.error;
    if (strength < 0.5) return AppColors.warning;
    if (strength < 0.7) return AppColors.accent2;
    if (strength < 0.9) return const Color(0xFF84cc16);
    return AppColors.success;
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

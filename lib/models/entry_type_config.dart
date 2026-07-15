import 'package:flutter/material.dart';
import 'password_entry.dart';

enum EntryFieldType {
  text,
  password,
  email,
  url,
  phone,
  number,
  date,
  multiline,
  cardNumber,
  cvv,
  pin,
}

class EntryFieldConfig {
  final String key;
  final String label;
  final String hint;
  final IconData icon;
  final EntryFieldType fieldType;
  final bool required;
  final bool isSensitive;
  final bool isPrimary;
  final bool showInList;

  const EntryFieldConfig({
    required this.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.fieldType = EntryFieldType.text,
    this.required = false,
    this.isSensitive = false,
    this.isPrimary = false,
    this.showInList = false,
  });
}

class EntryTypeConfig {
  final EntryType type;
  final String label;
  final IconData icon;
  final Color color;
  final List<EntryFieldConfig> fields;

  const EntryTypeConfig({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    required this.fields,
  });
}

class EntryTypes {
  static const Map<EntryType, EntryTypeConfig> configs = {
    EntryType.login: EntryTypeConfig(
      type: EntryType.login,
      label: '登录',
      icon: Icons.login_rounded,
      color: Color(0xFF2dd4bf),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '标题',
          hint: '例如：GitHub、微信',
          icon: Icons.title,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'username',
          label: '用户名/邮箱',
          hint: '输入用户名或邮箱地址',
          icon: Icons.person_outline,
          fieldType: EntryFieldType.email,
          showInList: true,
        ),
        EntryFieldConfig(
          key: 'password',
          label: '密码',
          hint: '输入密码',
          icon: Icons.lock_outline,
          fieldType: EntryFieldType.password,
          isSensitive: true,
        ),
        EntryFieldConfig(
          key: 'url',
          label: '网址',
          hint: 'https://example.com',
          icon: Icons.link,
          fieldType: EntryFieldType.url,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
    EntryType.card: EntryTypeConfig(
      type: EntryType.card,
      label: '银行卡',
      icon: Icons.credit_card,
      color: Color(0xFFf59e0b),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '卡片名称',
          hint: '例如：招商银行信用卡',
          icon: Icons.title,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'cardHolder',
          label: '持卡人',
          hint: '持卡人姓名',
          icon: Icons.person_outline,
          showInList: true,
        ),
        EntryFieldConfig(
          key: 'cardNumber',
          label: '卡号',
          hint: '银行卡号',
          icon: Icons.credit_card_outlined,
          fieldType: EntryFieldType.cardNumber,
        ),
        EntryFieldConfig(
          key: 'expiryDate',
          label: '有效期',
          hint: 'MM/YY',
          icon: Icons.date_range,
        ),
        EntryFieldConfig(
          key: 'cvv',
          label: 'CVV',
          hint: '安全码',
          icon: Icons.security,
          fieldType: EntryFieldType.cvv,
          isSensitive: true,
        ),
        EntryFieldConfig(
          key: 'pin',
          label: 'PIN码',
          hint: '取款密码',
          icon: Icons.password,
          fieldType: EntryFieldType.pin,
          isSensitive: true,
        ),
        EntryFieldConfig(
          key: 'bankName',
          label: '银行名称',
          hint: '发卡银行',
          icon: Icons.account_balance,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
    EntryType.note: EntryTypeConfig(
      type: EntryType.note,
      label: '安全笔记',
      icon: Icons.note_alt_outlined,
      color: Color(0xFF818cf8),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '标题',
          hint: '笔记标题',
          icon: Icons.title,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'content',
          label: '内容',
          hint: '输入笔记内容',
          icon: Icons.edit_note,
          fieldType: EntryFieldType.multiline,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
    EntryType.identity: EntryTypeConfig(
      type: EntryType.identity,
      label: '身份信息',
      icon: Icons.person_outline,
      color: Color(0xFF22c55e),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '名称',
          hint: '例如：身份证、护照',
          icon: Icons.title,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'fullName',
          label: '姓名',
          hint: '真实姓名',
          icon: Icons.badge_outlined,
          showInList: true,
        ),
        EntryFieldConfig(
          key: 'idNumber',
          label: '证件号码',
          hint: '身份证/护照号',
          icon: Icons.numbers,
        ),
        EntryFieldConfig(
          key: 'gender',
          label: '性别',
          hint: '男/女',
          icon: Icons.people_outline,
        ),
        EntryFieldConfig(
          key: 'birthday',
          label: '出生日期',
          hint: 'YYYY-MM-DD',
          icon: Icons.cake_outlined,
          fieldType: EntryFieldType.date,
        ),
        EntryFieldConfig(
          key: 'address',
          label: '地址',
          hint: '居住地址',
          icon: Icons.location_on_outlined,
          fieldType: EntryFieldType.multiline,
        ),
        EntryFieldConfig(
          key: 'phone',
          label: '电话',
          hint: '联系电话',
          icon: Icons.phone_outlined,
          fieldType: EntryFieldType.phone,
        ),
        EntryFieldConfig(
          key: 'email',
          label: '邮箱',
          hint: '电子邮箱',
          icon: Icons.email_outlined,
          fieldType: EntryFieldType.email,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
    EntryType.email: EntryTypeConfig(
      type: EntryType.email,
      label: '邮箱',
      icon: Icons.email_outlined,
      color: Color(0xFFef4444),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '标题',
          hint: '例如：Gmail、QQ邮箱',
          icon: Icons.title,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'email',
          label: '邮箱地址',
          hint: 'example@domain.com',
          icon: Icons.alternate_email,
          fieldType: EntryFieldType.email,
          showInList: true,
        ),
        EntryFieldConfig(
          key: 'password',
          label: '密码',
          hint: '邮箱密码/授权码',
          icon: Icons.lock_outline,
          fieldType: EntryFieldType.password,
          isSensitive: true,
        ),
        EntryFieldConfig(
          key: 'imapServer',
          label: 'IMAP服务器',
          hint: 'imap.example.com',
          icon: Icons.dns_outlined,
        ),
        EntryFieldConfig(
          key: 'smtpServer',
          label: 'SMTP服务器',
          hint: 'smtp.example.com',
          icon: Icons.send_outlined,
        ),
        EntryFieldConfig(
          key: 'recoveryEmail',
          label: '备用邮箱',
          hint: '恢复邮箱地址',
          icon: Icons.restore,
        ),
        EntryFieldConfig(
          key: 'recoveryPhone',
          label: '绑定手机',
          hint: '绑定的手机号',
          icon: Icons.phone_outlined,
          fieldType: EntryFieldType.phone,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
    EntryType.wifi: EntryTypeConfig(
      type: EntryType.wifi,
      label: 'Wi-Fi',
      icon: Icons.wifi,
      color: Color(0xFF06b6d4),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '网络名称',
          hint: 'Wi-Fi名称(SSID)',
          icon: Icons.wifi_tethering,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'password',
          label: '密码',
          hint: 'Wi-Fi密码',
          icon: Icons.lock_outline,
          fieldType: EntryFieldType.password,
          isSensitive: true,
          showInList: true,
        ),
        EntryFieldConfig(
          key: 'securityType',
          label: '加密方式',
          hint: 'WPA3/WPA2/WEP',
          icon: Icons.security,
        ),
        EntryFieldConfig(
          key: 'bssid',
          label: 'BSSID',
          hint: '路由器MAC地址',
          icon: Icons.router_outlined,
        ),
        EntryFieldConfig(
          key: 'location',
          label: '位置',
          hint: '例如：家里、公司',
          icon: Icons.location_on_outlined,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
    EntryType.server: EntryTypeConfig(
      type: EntryType.server,
      label: '服务器',
      icon: Icons.dns_outlined,
      color: Color(0xFF8b5cf6),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '服务器名称',
          hint: '例如：生产服务器',
          icon: Icons.title,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'host',
          label: '主机地址',
          hint: 'IP或域名',
          icon: Icons.computer_outlined,
          showInList: true,
        ),
        EntryFieldConfig(
          key: 'port',
          label: '端口',
          hint: '端口号',
          icon: Icons.settings_ethernet,
          fieldType: EntryFieldType.number,
        ),
        EntryFieldConfig(
          key: 'username',
          label: '用户名',
          hint: '登录用户名',
          icon: Icons.person_outline,
        ),
        EntryFieldConfig(
          key: 'password',
          label: '密码',
          hint: '登录密码',
          icon: Icons.lock_outline,
          fieldType: EntryFieldType.password,
          isSensitive: true,
        ),
        EntryFieldConfig(
          key: 'protocol',
          label: '协议',
          hint: 'SSH/FTP/SFTP等',
          icon: Icons.api_outlined,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
    EntryType.software: EntryTypeConfig(
      type: EntryType.software,
      label: '软件许可证',
      icon: Icons.key,
      color: Color(0xFFec4899),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '软件名称',
          hint: '例如：Office、Photoshop',
          icon: Icons.title,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'licenseKey',
          label: '许可证密钥',
          hint: '产品密钥',
          icon: Icons.vpn_key_outlined,
          isSensitive: true,
          showInList: true,
        ),
        EntryFieldConfig(
          key: 'version',
          label: '版本',
          hint: '软件版本',
          icon: Icons.info_outline,
        ),
        EntryFieldConfig(
          key: 'email',
          label: '注册邮箱',
          hint: '注册用邮箱',
          icon: Icons.email_outlined,
          fieldType: EntryFieldType.email,
        ),
        EntryFieldConfig(
          key: 'purchaseDate',
          label: '购买日期',
          hint: 'YYYY-MM-DD',
          icon: Icons.shopping_cart_outlined,
          fieldType: EntryFieldType.date,
        ),
        EntryFieldConfig(
          key: 'expiryDate',
          label: '到期日期',
          hint: 'YYYY-MM-DD',
          icon: Icons.event_busy_outlined,
          fieldType: EntryFieldType.date,
        ),
        EntryFieldConfig(
          key: 'downloadUrl',
          label: '下载地址',
          hint: '软件下载链接',
          icon: Icons.download_outlined,
          fieldType: EntryFieldType.url,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
    EntryType.database: EntryTypeConfig(
      type: EntryType.database,
      label: '数据库',
      icon: Icons.storage_outlined,
      color: Color(0xFF14b8a6),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '数据库名称',
          hint: '例如：生产数据库',
          icon: Icons.title,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'host',
          label: '主机',
          hint: '数据库主机地址',
          icon: Icons.dns_outlined,
          showInList: true,
        ),
        EntryFieldConfig(
          key: 'port',
          label: '端口',
          hint: '端口号',
          icon: Icons.settings_ethernet,
          fieldType: EntryFieldType.number,
        ),
        EntryFieldConfig(
          key: 'database',
          label: '数据库名',
          hint: 'database name',
          icon: Icons.data_object_outlined,
        ),
        EntryFieldConfig(
          key: 'username',
          label: '用户名',
          hint: '数据库用户名',
          icon: Icons.person_outline,
        ),
        EntryFieldConfig(
          key: 'password',
          label: '密码',
          hint: '数据库密码',
          icon: Icons.lock_outline,
          fieldType: EntryFieldType.password,
          isSensitive: true,
        ),
        EntryFieldConfig(
          key: 'dbType',
          label: '类型',
          hint: 'MySQL/PostgreSQL/Redis等',
          icon: Icons.schema_outlined,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
    EntryType.ssh: EntryTypeConfig(
      type: EntryType.ssh,
      label: 'SSH密钥',
      icon: Icons.keyboard_command_key_outlined,
      color: Color(0xFFf97316),
      fields: [
        EntryFieldConfig(
          key: 'title',
          label: '名称',
          hint: '例如：GitHub SSH Key',
          icon: Icons.title,
          required: true,
          isPrimary: true,
        ),
        EntryFieldConfig(
          key: 'host',
          label: '主机',
          hint: '服务器地址',
          icon: Icons.computer_outlined,
          showInList: true,
        ),
        EntryFieldConfig(
          key: 'username',
          label: '用户名',
          hint: '登录用户名',
          icon: Icons.person_outline,
        ),
        EntryFieldConfig(
          key: 'passphrase',
          label: '密语',
          hint: '密钥密码（如有）',
          icon: Icons.lock_outline,
          fieldType: EntryFieldType.password,
          isSensitive: true,
        ),
        EntryFieldConfig(
          key: 'publicKey',
          label: '公钥',
          hint: 'SSH Public Key',
          icon: Icons.vpn_key_outlined,
          fieldType: EntryFieldType.multiline,
        ),
        EntryFieldConfig(
          key: 'privateKey',
          label: '私钥',
          hint: 'SSH Private Key（请加密保存）',
          icon: Icons.key_off_outlined,
          fieldType: EntryFieldType.multiline,
          isSensitive: true,
        ),
        EntryFieldConfig(
          key: 'notes',
          label: '备注',
          hint: '添加额外信息',
          icon: Icons.note_outlined,
          fieldType: EntryFieldType.multiline,
        ),
      ],
    ),
  };

  static EntryTypeConfig getConfig(EntryType type) {
    return configs[type] ?? configs[EntryType.login]!;
  }

  static IconData getIcon(EntryType type) => getConfig(type).icon;
  static Color getColor(EntryType type) => getConfig(type).color;
  static String getLabel(EntryType type) => getConfig(type).label;
  static List<EntryFieldConfig> getFields(EntryType type) => getConfig(type).fields;
}

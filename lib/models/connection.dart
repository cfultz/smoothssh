class Connection {
  final String id;
  final String label;
  final String host;
  final int port;
  final String identityId;
  final int usageCount;
  final String group;

  Connection({
    required this.id,
    required this.label,
    required this.host,
    this.port = 22,
    required this.identityId,
    this.usageCount = 0,
    this.group = 'Default',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'host': host,
    'port': port,
    'identityId': identityId,
    'usageCount': usageCount,
    'group': group,
  };

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
    id: json['id'],
    label: json['label'],
    host: json['host'],
    port: json['port'] ?? 22,
    identityId: json['identityId'],
    usageCount: json['usageCount'] ?? 0,
    group: json['group'] ?? 'Default',
  );
}
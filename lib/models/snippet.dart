class Snippet {
  final String id;
  final String label;
  final String command;
  final bool autoEnter; 

  Snippet({
    required this.id,
    required this.label,
    required this.command,
    this.autoEnter = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'command': command,
    'autoEnter': autoEnter,
  };

  factory Snippet.fromJson(Map<String, dynamic> json) => Snippet(
    id: json['id'],
    label: json['label'],
    command: json['command'],
    autoEnter: json['autoEnter'] ?? true,
  );
}
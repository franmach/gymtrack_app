import 'package:flutter/material.dart';

import 'package:gymtrack_app/screens/admin/users/users_admin_screen.dart';
// import 'package:gymtrack_app/screens/admin/templates/routine_templates_screen.dart';


class AdminHubScreen extends StatelessWidget {
const AdminHubScreen({super.key});


@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Panel de Administración')),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
_AdminCard(
icon: Icons.people_outline,
title: 'Gestión de usuarios',
subtitle: 'Altas, bajas y modificaciones',
onTap: () {

Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersAdminScreen()));
_comingSoon(context);
},
),
const SizedBox(height: 12),
_AdminCard(
icon: Icons.fitness_center,
title: 'Plantillas de rutinas',
subtitle: 'Crear, duplicar, editar y eliminar',
onTap: () {
// Navegación provisional: al implementar la pantalla, descomentar
// Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutineTemplatesScreen()));
_comingSoon(context);
},
),
],
),
);
}


void _comingSoon(BuildContext context) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Esta sección se habilitará en el siguiente paso.')),
);
}
}


class _AdminCard extends StatelessWidget {
final IconData icon;
final String title;
final String subtitle;
final VoidCallback onTap;


const _AdminCard({
required this.icon,
required this.title,
required this.subtitle,
required this.onTap,
});


@override
Widget build(BuildContext context) {
return Card(
elevation: 2,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: ListTile(
leading: CircleAvatar(
radius: 22,
child: Icon(icon),
),
title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
subtitle: Text(subtitle),
trailing: const Icon(Icons.chevron_right),
onTap: onTap,
),
);
}
}
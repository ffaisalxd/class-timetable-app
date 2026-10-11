import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../theme/app_theme.dart';
import '../widgets/pill_tag.dart';
import '../widgets/glass_card.dart';
import '../widgets/modern_ui.dart';

import 'add_user_page.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() =>
      _ManageUsersPageState();
}

class _ManageUsersPageState
    extends State<ManageUsersPage> {
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  late final Stream<QuerySnapshot>
  _usersStream;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _colorForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.accent;

      case 'lecturer':
        return AppColors.primary;

      default:
        return const Color(
          0xFF5B6EE1,
        );
    }
  }

  void _confirmDeleteUser(
      BuildContext context,
      String uid,
      String name,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            title:
            const Text('Delete User'),
            content: Text(
              'This will permanently delete '
                  '"$name"\'s account. '
                  'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      dialogContext,
                    ),
                child:
                const Text('Cancel'),
              ),

              ElevatedButton(
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.error,
                ),
                onPressed: () async {
                  Navigator.pop(
                    dialogContext,
                  );

                  try {
                    final callable =
                    FirebaseFunctions
                        .instance
                        .httpsCallable(
                      'deleteUserAccount',
                    );

                    await callable.call(
                      {
                        'uid': uid,
                      },
                    );
                  } on FirebaseFunctionsException
                  catch (e) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.message ??
                              'Failed to delete user',
                        ),
                      ),
                    );
                  }
                },
                child:
                const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();

    _usersStream =
        FirebaseFirestore.instance
            .collection('users')
            .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernHero(
          eyebrow: 'Administration',
          title: 'Manage Users',
          subtitle:
          'Students, lecturers and system administrators',
          trailing:
          _AdminHeaderAction(
            icon: Icons
                .person_add_alt_1_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const AddUserPage(),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: SafeArea(
            top: false,
            child: StreamBuilder<
                QuerySnapshot>(
              stream: _usersStream,
              builder:
                  (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Something went wrong: '
                          '${snapshot.error}',
                    ),
                  );
                }

                if (snapshot
                    .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                final docs =
                    snapshot.data?.docs ??
                        [];

                final query =
                _searchQuery
                    .trim()
                    .toLowerCase();

                final filteredDocs =
                docs.where((doc) {
                  final data =
                  doc.data()
                  as Map<String,
                      dynamic>;

                  final name =
                  (data['name'] ??
                      '')
                      .toString()
                      .toLowerCase();

                  final email =
                  (data['email'] ??
                      '')
                      .toString()
                      .toLowerCase();

                  final role =
                  (data['role'] ??
                      '')
                      .toString()
                      .toLowerCase();

                  final programme =
                  (data['programmeCode'] ??
                      '')
                      .toString()
                      .toLowerCase();

                  return query.isEmpty ||
                      name.contains(query) ||
                      email
                          .contains(query) ||
                      role.contains(query) ||
                      programme
                          .contains(query);
                }).toList();

                return ListView(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    20,
                    20,
                    20,
                    100,
                  ),
                  children: [
                    TextField(
                      controller:
                      _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery =
                              value;
                        });
                      },
                      decoration:
                      InputDecoration(
                        hintText:
                        'Search name, email, role or programme',
                        prefixIcon:
                        const Icon(
                          Icons
                              .search_rounded,
                        ),
                        suffixIcon:
                        _searchQuery
                            .isEmpty
                            ? null
                            : IconButton(
                          onPressed:
                              () {
                            _searchController
                                .clear();

                            setState(
                                  () {
                                _searchQuery =
                                '';
                              },
                            );
                          },
                          icon:
                          const Icon(
                            Icons
                                .close_rounded,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    if (docs.isEmpty)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 80,
                        ),
                        child: Center(
                          child: Text(
                            'No users found.',
                            style:
                            TextStyle(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      )
                    else if (filteredDocs
                        .isEmpty)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 80,
                        ),
                        child: Center(
                          child: Text(
                            'No matching users found.',
                            style:
                            TextStyle(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filteredDocs.map(
                            (doc) {
                          final data =
                          doc.data()
                          as Map<
                              String,
                              dynamic>;

                          final name =
                          (data['name'] ??
                              'Unknown')
                              .toString();

                          final email =
                          (data['email'] ??
                              '')
                              .toString();

                          final role =
                          (data['role'] ??
                              'student')
                              .toString();

                          final programme =
                          (data['programmeCode'] ??
                              '')
                              .toString();

                          final color =
                          _colorForRole(
                            role,
                          );

                          return GlassCard(
                            margin:
                            const EdgeInsets
                                .only(
                              bottom: 14,
                            ),
                            padding:
                            const EdgeInsets
                                .all(
                              18,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                  color
                                      .withValues(
                                    alpha:
                                    0.18,
                                  ),
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0]
                                        .toUpperCase()
                                        : '?',
                                    style:
                                    TextStyle(
                                      color:
                                      color,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 14,
                                ),

                                Expanded(
                                  child:
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        name,
                                        style:
                                        const TextStyle(
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                          fontSize:
                                          15,
                                          color:
                                          AppColors
                                              .textPrimary,
                                        ),
                                      ),

                                      const SizedBox(
                                        height:
                                        2,
                                      ),

                                      Text(
                                        email,
                                        style:
                                        const TextStyle(
                                          color:
                                          AppColors
                                              .textSecondary,
                                          fontSize:
                                          13,
                                        ),
                                      ),

                                      if (programme
                                          .isNotEmpty) ...[
                                        const SizedBox(
                                          height:
                                          2,
                                        ),
                                        Text(
                                          programme,
                                          style:
                                          const TextStyle(
                                            color:
                                            AppColors
                                                .textSecondary,
                                            fontSize:
                                            11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                PillTag(
                                  label: role
                                      .toUpperCase(),
                                  color:
                                  color,
                                ),

                                const SizedBox(
                                  width: 4,
                                ),

                                IconButton(
                                  tooltip:
                                  'Delete user',
                                  onPressed: () =>
                                      _confirmDeleteUser(
                                        context,
                                        doc.id,
                                        name,
                                      ),
                                  icon:
                                  const Icon(
                                    Icons
                                        .delete_outline,
                                    color:
                                    AppColors
                                        .error,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminHeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AdminHeaderAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(15),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white
              .withValues(
            alpha: .12,
          ),
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          border: Border.all(
            color: Colors.white
                .withValues(
              alpha: .13,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}
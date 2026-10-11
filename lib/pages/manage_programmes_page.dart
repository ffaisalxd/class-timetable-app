import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/programme.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_dialog.dart';
import '../widgets/modern_ui.dart';

import 'programme_form_page.dart';

class ManageProgrammesPage
    extends StatefulWidget {
  const ManageProgrammesPage({
    super.key,
  });

  @override
  State<ManageProgrammesPage>
  createState() =>
      _ManageProgrammesPageState();
}

class _ManageProgrammesPageState
    extends State<ManageProgrammesPage> {
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  late final Stream<QuerySnapshot>
  _programmesStream;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
      BuildContext context,
      Programme programme,
      ) async {
    final confirmed =
    await showConfirmDialog(
      context: context,
      title: 'Delete Programme',
      message:
      'Remove "${programme.code} - ${programme.name}"? '
          'This won\'t delete any classes already tagged with it.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline,
      iconColor: AppColors.error,
      isDanger: true,
    );

    if (!confirmed) return;

    await FirebaseFirestore.instance
        .collection('programmes')
        .doc(programme.id)
        .delete();
  }

  @override
  void initState() {
    super.initState();

    _programmesStream =
        FirebaseFirestore.instance
            .collection('programmes')
            .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernHero(
          eyebrow: 'Administration',
          title: 'Programmes',
          subtitle:
          'Manage available study programmes',
          trailing:
          _ProgrammeHeaderAction(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ProgrammeFormPage(),
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
              stream: _programmesStream,
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

                final programmes = docs
                    .map(
                      (doc) =>
                      Programme.fromMap(
                        doc.data()
                        as Map<String,
                            dynamic>,
                        id: doc.id,
                      ),
                )
                    .toList();

                final query =
                _searchQuery
                    .trim()
                    .toLowerCase();

                final filteredProgrammes =
                programmes.where(
                      (programme) {
                    if (query.isEmpty) {
                      return true;
                    }

                    return programme.code
                        .toLowerCase()
                        .contains(
                      query,
                    ) ||
                        programme.name
                            .toLowerCase()
                            .contains(
                          query,
                        );
                  },
                ).toList();

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
                        'Search programme code or name',
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

                    if (programmes.isEmpty)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 80,
                        ),
                        child: Center(
                          child: Text(
                            'No programmes yet. Tap + to add one.',
                            textAlign:
                            TextAlign.center,
                            style:
                            TextStyle(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      )
                    else if (filteredProgrammes
                        .isEmpty)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 80,
                        ),
                        child: Center(
                          child: Text(
                            'No matching programmes found.',
                            style:
                            TextStyle(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filteredProgrammes
                          .map(
                            (programme) =>
                            GlassCard(
                              margin:
                              const EdgeInsets
                                  .only(
                                bottom: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration:
                                    BoxDecoration(
                                      color: AppColors
                                          .primary
                                          .withValues(
                                        alpha:
                                        0.18,
                                      ),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        12,
                                      ),
                                    ),
                                    child:
                                    const Icon(
                                      Icons
                                          .school_outlined,
                                      color:
                                      AppColors
                                          .primary,
                                      size: 22,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 14,
                                  ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          programme
                                              .code,
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
                                          height: 2,
                                        ),

                                        Text(
                                          programme
                                              .name,
                                          style:
                                          const TextStyle(
                                            color:
                                            AppColors
                                                .textSecondary,
                                            fontSize:
                                            13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    tooltip:
                                    'Edit programme',
                                    onPressed:
                                        () {
                                      Navigator
                                          .push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                              ProgrammeFormPage(
                                                existingProgramme:
                                                programme,
                                              ),
                                        ),
                                      );
                                    },
                                    icon:
                                    const Icon(
                                      Icons
                                          .edit_outlined,
                                      color:
                                      AppColors
                                          .textSecondary,
                                      size: 20,
                                    ),
                                  ),

                                  IconButton(
                                    tooltip:
                                    'Delete programme',
                                    onPressed:
                                        () =>
                                        _confirmDelete(
                                          context,
                                          programme,
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
                            ),
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

class _ProgrammeHeaderAction
    extends StatelessWidget {
  final VoidCallback onTap;

  const _ProgrammeHeaderAction({
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
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}
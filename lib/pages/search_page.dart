import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/class_session.dart';
import '../theme/app_theme.dart';
import '../utils/subject_colors.dart';
import '../utils/current_user_programme.dart';
import '../widgets/modern_ui.dart';

import 'class_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() =>
      _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController =
  TextEditingController();

  String _query = '';

  bool _isLoading = true;
  String? _error;

  Stream<QuerySnapshot>? _classesStream;

  @override
  void initState() {
    super.initState();
    _prepareSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _prepareSearch() async {
    try {
      final enrollment =
      await getCurrentUserEnrollment();

      if (!isEnrollmentComplete(enrollment)) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _error =
          'Your programme, semester, or section is not set up yet. '
              'Please contact an admin.';
        });

        return;
      }

      final stream = FirebaseFirestore.instance
          .collection('classes')
          .where(
        'programmeCode',
        isEqualTo:
        enrollment.programmeCode,
      )
          .where(
        'semester',
        isEqualTo:
        enrollment.semester,
      )
          .where(
        'section',
        isEqualTo:
        enrollment.section,
      )
          .snapshots();

      if (!mounted) return;

      setState(() {
        _classesStream = stream;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Failed to prepare timetable search: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error =
        'Unable to load timetable information.';
      });
    }
  }

  Widget _resultCard(
      BuildContext context,
      ClassSession session,
      ) {
    final color =
    colorForSubject(session.courseName);

    return InkWell(
      borderRadius:
      BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ClassDetailPage(
                  session: session,
                ),
          ),
        );
      },
      child: Container(
        padding:
        const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.glassBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: .11,
                ),
                borderRadius:
                BorderRadius.circular(
                  15,
                ),
              ),
              child: Icon(
                session.classType ==
                    'online'
                    ? Icons
                    .videocam_outlined
                    : Icons
                    .school_outlined,
                color: color,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    session.courseName,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w800,
                      color: AppColors
                          .textPrimary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    session.lecturer,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color: AppColors
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Wrap instead of Row.
                  // This prevents narrow-screen overflow.
                  Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    crossAxisAlignment:
                    WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .calendar_today_outlined,
                            size: 13,
                            color: color,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            session.day,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: color,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons
                                .schedule_rounded,
                            size: 13,
                            color: AppColors
                                .textSecondary,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            '${session.startTime} - '
                                '${session.endTime}',
                            style:
                            const TextStyle(
                              fontSize: 11.5,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              size: 14,
              color:
              AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const ModernHero(
            eyebrow: 'Discover',
            title: 'Search timetable',
            subtitle:
            'Find a class by course or lecturer',
          ),

          Expanded(
            child: Center(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  24,
                ),
                child: Text(
                  _error!,
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color: AppColors
                        .textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ModernHero(
          eyebrow: 'Discover',
          title: 'Search timetable',
          subtitle:
          'Find a class by course name or lecturer',
          bottom: TextField(
            controller:
            _searchController,
            style: const TextStyle(
              color:
              AppColors.textPrimary,
            ),
            decoration:
            InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText:
              'Search your timetable...',
              prefixIcon:
              const Icon(
                Icons.search_rounded,
                color:
                AppColors.primary,
              ),
              suffixIcon:
              _query.isEmpty
                  ? null
                  : IconButton(
                icon:
                const Icon(
                  Icons
                      .close_rounded,
                ),
                onPressed:
                    () {
                  _searchController
                      .clear();

                  setState(() {
                    _query = '';
                  });
                },
              ),
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  18,
                ),
                borderSide:
                BorderSide.none,
              ),
              enabledBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  18,
                ),
                borderSide:
                BorderSide.none,
              ),
            ),

            // This now only changes the local
            // filter. Firebase is NOT restarted.
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
        ),

        Expanded(
          child:
          StreamBuilder<
              QuerySnapshot>(
            // SAME stream instance every rebuild.
            stream:
            _classesStream,

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

              if (!snapshot.hasData) {
                return const Center(
                  child:
                  CircularProgressIndicator(),
                );
              }

              final docs =
                  snapshot.data?.docs ??
                      [];

              final allClasses =
              docs.map((doc) {
                return ClassSession
                    .fromMap(
                  doc.data()
                  as Map<String,
                      dynamic>,
                  id: doc.id,
                );
              }).toList();

              final searchText =
              _query
                  .trim()
                  .toLowerCase();

              final filtered =
              searchText.isEmpty
                  ? allClasses
                  : allClasses.where(
                    (session) {
                  return session
                      .courseName
                      .toLowerCase()
                      .contains(
                    searchText,
                  ) ||
                      session
                          .lecturer
                          .toLowerCase()
                          .contains(
                        searchText,
                      ) ||
                      session
                          .day
                          .toLowerCase()
                          .contains(
                        searchText,
                      );
                },
              ).toList();

              return SafeArea(
                top: false,
                child: ListView(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    20,
                    20,
                    20,
                    108,
                  ),
                  children: [
                    SectionHeading(
                      title: searchText
                          .isEmpty
                          ? 'Your classes'
                          : 'Search results',
                      subtitle:
                      '${filtered.length} '
                          'class${filtered.length == 1 ? '' : 'es'} found',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (filtered
                        .isEmpty)
                      const SurfacePanel(
                        child: Padding(
                          padding:
                          EdgeInsets
                              .symmetric(
                            vertical:
                            28,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .search_off_rounded,
                                size: 36,
                                color:
                                AppColors
                                    .primary,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'No matching classes',
                                style:
                                TextStyle(
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  color: AppColors
                                      .textPrimary,
                                ),
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              Text(
                                'Try another course or lecturer name.',
                                style:
                                TextStyle(
                                  color: AppColors
                                      .textSecondary,
                                  fontSize:
                                  12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtered.map(
                            (session) =>
                            Padding(
                              padding:
                              const EdgeInsets
                                  .only(
                                bottom:
                                10,
                              ),
                              child:
                              _resultCard(
                                context,
                                session,
                              ),
                            ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  initializeApp,
} = require("firebase-admin/app");

const {
  getFirestore,
} = require("firebase-admin/firestore");

const {
  getMessaging,
} = require("firebase-admin/messaging");

const {
  getAuth,
} = require("firebase-admin/auth");

initializeApp();


// ======================================================
// CLASS CANCELLED
// ======================================================

exports.notifyOnClassCancelled =
  onDocumentDeleted(
    "classes/{classId}",
    async (event) => {
      const deletedClass =
        event.data.data();

      const courseName =
        deletedClass.courseName ||
        "A class";

      const programmeCode =
        deletedClass.programmeCode || "";

      const semester =
        deletedClass.semester || 0;

      const section =
        deletedClass.section || 0;

      const day =
        deletedClass.day || "";

      const startTime =
        deletedClass.startTime || "";

      const endTime =
        deletedClass.endTime || "";

      const db = getFirestore();

      let body =
        `${courseName} has been cancelled.`;

      if (
        day &&
        startTime &&
        endTime
      ) {
        body =
          `${courseName} scheduled for ` +
          `${day}, ${startTime} - ${endTime} ` +
          `has been cancelled.`;
      }

      // Save cancellation into Updates & Announcements history
      await db
        .collection("announcements")
        .add({
          type:
            "class_cancelled",

          title:
            "Class Cancelled",

          message:
            body,

          courseId:
            event.params.classId,

          courseName:
            courseName,

          lecturerId:
            deletedClass.lecturerId ||
            "",

          lecturer:
            deletedClass.lecturer ||
            "",

          programmeCode:
            programmeCode,

          semester:
            semester,

          section:
            section,

          createdAt:
            new Date(),
        });

      // Find affected students
      const usersSnapshot =
        await db
          .collection("users")
          .where(
            "role",
            "==",
            "student",
          )
          .where(
            "programmeCode",
            "==",
            programmeCode,
          )
          .where(
            "semester",
            "==",
            semester,
          )
          .where(
            "section",
            "==",
            section,
          )
          .get();

      const tokens = [];

      usersSnapshot.forEach(
        (doc) => {
          const token =
            doc.data().fcmToken;

          if (token) {
            tokens.push(token);
          }
        },
      );

      if (
        tokens.length === 0
      ) {
        console.log(
          "No matching student tokens found.",
        );

        return;
      }

      await sendToTokens({
        tokens,

        title:
          "Class Cancelled",

        body,

        data: {
          type:
            "class_cancelled",

          classId:
            event.params.classId,
        },
      });
    },
  );


// ======================================================
// CLASS UPDATED / RESCHEDULED
// ======================================================

exports.notifyOnClassRescheduled =
  onDocumentUpdated(
    "classes/{classId}",
    async (event) => {
      const before =
        event.data.before.data();

      const after =
        event.data.after.data();

      const scheduleChanged =
        before.day !== after.day ||
        before.startTime !==
          after.startTime ||
        before.endTime !==
          after.endTime ||
        before.room !==
          after.room;

      const formatChanged =
        before.classType !==
        after.classType;

      if (
        !scheduleChanged &&
        !formatChanged
      ) {
        return;
      }

      const db =
        getFirestore();

      let title;
      let body;
      let updateType;

      // Only class format changed
      if (
        formatChanged &&
        !scheduleChanged
      ) {
        title =
          "Class Format Updated";

        updateType =
          "class_format_updated";

        if (
          after.classType ===
          "online"
        ) {
          body =
            `${after.courseName} will now be ` +
            `conducted online from ` +
            `${after.startTime} to ${after.endTime}.`;
        } else {
          body =
            `${after.courseName} will now be ` +
            `held in ${after.room} from ` +
            `${after.startTime} to ${after.endTime}.`;
        }
      } else {
        // Day, time, room or multiple fields changed
        title =
          "Class Rescheduled";

        updateType =
          "class_rescheduled";

        if (
          after.classType ===
          "online"
        ) {
          body =
            `${after.courseName} has been rescheduled to ` +
            `${after.day}, ` +
            `${after.startTime} - ${after.endTime} online.`;
        } else {
          body =
            `${after.courseName} has been rescheduled to ` +
            `${after.day}, ` +
            `${after.startTime} - ${after.endTime} ` +
            `in ${after.room}.`;
        }
      }

      // Save update into Updates & Announcements history
      await db
        .collection("announcements")
        .add({
          type:
            updateType,

          title:
            title,

          message:
            body,

          courseId:
            event.params.classId,

          courseName:
            after.courseName || "",

          lecturerId:
            after.lecturerId || "",

          lecturer:
            after.lecturer || "",

          programmeCode:
            after.programmeCode || "",

          semester:
            after.semester || 0,

          section:
            after.section || 0,

          createdAt:
            new Date(),
        });

      // Find affected students
      const usersSnapshot =
        await db
          .collection("users")
          .where(
            "role",
            "==",
            "student",
          )
          .where(
            "programmeCode",
            "==",
            after.programmeCode || "",
          )
          .where(
            "semester",
            "==",
            after.semester || 0,
          )
          .where(
            "section",
            "==",
            after.section || 0,
          )
          .get();

      const tokens = [];

      usersSnapshot.forEach(
        (doc) => {
          const token =
            doc.data().fcmToken;

          if (token) {
            tokens.push(token);
          }
        },
      );

      if (
        tokens.length === 0
      ) {
        console.log(
          "No matching student tokens found.",
        );

        return;
      }

      await sendToTokens({
        tokens,

        title,

        body,

        data: {
          type:
            updateType,

          classId:
            event.params.classId,
        },
      });
    },
  );


// ======================================================
// LECTURER ANNOUNCEMENT
// ======================================================

exports.notifyOnAnnouncement =
  onDocumentCreated(
    "announcements/{announcementId}",
    async (event) => {
      const snapshot =
        event.data;

      if (!snapshot) {
        return;
      }

      const announcement =
        snapshot.data();

      // Old announcement records without a type
      // are treated as normal lecturer announcements.
      const type =
        announcement.type ||
        "announcement";

      // IMPORTANT:
      // Cancellation / reschedule / format history
      // is already handled by its own Cloud Function.
      // Do not send another notification.
      if (
        type !==
        "announcement"
      ) {
        console.log(
          `Skipping duplicate FCM for history record: ${type}`,
        );

        return;
      }

      const programmeCode =
        announcement.programmeCode || "";

      const semester =
        announcement.semester || 0;

      const section =
        announcement.section || 0;

      const db =
        getFirestore();

      const usersSnapshot =
        await db
          .collection("users")
          .where(
            "role",
            "==",
            "student",
          )
          .where(
            "programmeCode",
            "==",
            programmeCode,
          )
          .where(
            "semester",
            "==",
            semester,
          )
          .where(
            "section",
            "==",
            section,
          )
          .get();

      const tokens = [];

      usersSnapshot.forEach(
        (doc) => {
          const token =
            doc.data().fcmToken;

          if (token) {
            tokens.push(token);
          }
        },
      );

      if (
        tokens.length === 0
      ) {
        console.log(
          "No matching student tokens found for announcement.",
        );

        return;
      }

      await sendToTokens({
        tokens,

        title:
          announcement.title ||
          "New Announcement",

        body:
          announcement.message ||
          "A lecturer has posted a new announcement.",

        data: {
          type:
            "announcement",

          announcementId:
            event.params
              .announcementId,

          courseId:
            announcement.courseId ||
            "",

          courseName:
            announcement.courseName ||
            "",
        },
      });
    },
  );


// ======================================================
// ADMIN DELETE USER
// ======================================================

exports.deleteUserAccount =
  onCall(
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "You must be logged in.",
        );
      }

      const db =
        getFirestore();

      const callerDoc =
        await db
          .collection("users")
          .doc(
            request.auth.uid,
          )
          .get();

      const callerRole =
        callerDoc.data()?.role;

      if (
        callerRole !==
        "admin"
      ) {
        throw new HttpsError(
          "permission-denied",
          "Only admins can delete users.",
        );
      }

      const targetUid =
        request.data.uid;

      if (!targetUid) {
        throw new HttpsError(
          "invalid-argument",
          "Missing user id to delete.",
        );
      }

      if (
        targetUid ===
        request.auth.uid
      ) {
        throw new HttpsError(
          "failed-precondition",
          "You cannot delete your own account.",
        );
      }

      await getAuth()
        .deleteUser(
          targetUid,
        );

      await db
        .collection("users")
        .doc(targetUid)
        .delete();

      return {
        success: true,
      };
    },
  );


// ======================================================
// FCM HELPER
// ======================================================

async function sendToTokens({
  tokens,
  title,
  body,
  data = {},
}) {
  const uniqueTokens =
    [...new Set(tokens)];

  const chunks = [];

  for (
    let i = 0;
    i < uniqueTokens.length;
    i += 500
  ) {
    chunks.push(
      uniqueTokens.slice(
        i,
        i + 500,
      ),
    );
  }

  for (
    const tokenChunk
    of chunks
  ) {
    const response =
      await getMessaging()
        .sendEachForMulticast({
          tokens:
            tokenChunk,

          notification: {
            title,
            body,
          },

          data,

          android: {
            priority:
              "high",
          },
        });

    console.log(
      `${title}: ` +
      `${response.successCount} succeeded, ` +
      `${response.failureCount} failed.`,
    );
  }
}
import { Type } from 'typebox';
import { FEEDBACK_CATEGORIES, FEEDBACK_STATUSES } from '../constants/enums.js';
import { Nullable, Text, Timestamp, Uuid, errorResponses } from './common.schema.js';

export const FeedbackCategorySchema = Type.Enum(FEEDBACK_CATEGORIES);
export const FeedbackStatusSchema = Type.Enum(FEEDBACK_STATUSES);

export const SendFeedbackBody = Type.Object(
  {
    category: Type.Optional(FeedbackCategorySchema),
    message: Text(2000),
    rating: Type.Optional(Type.Integer({ minimum: 1, maximum: 5, description: 'Optional 1–5 stars.' })),
    platform: Type.Optional(Type.String({ maxLength: 20, description: 'e.g. android, ios, web.' })),
    appVersion: Type.Optional(Type.String({ maxLength: 40 })),
  },
  { additionalProperties: false },
);

/** What the sender gets back. */
export const Feedback = Type.Object({
  id: Uuid,
  category: FeedbackCategorySchema,
  rating: Nullable(Type.Integer()),
  message: Type.String(),
  status: FeedbackStatusSchema,
  createdAt: Timestamp,
});

/** What the superadmin dashboard sees. */
export const AdminFeedback = Type.Object({
  ...Feedback.properties,
  platform: Nullable(Type.String()),
  appVersion: Nullable(Type.String()),
  adminNote: Type.String(),
  resolvedAt: Nullable(Timestamp),
  updatedAt: Timestamp,
  user: Nullable(
    Type.Object({
      id: Uuid,
      name: Type.String(),
      email: Type.String(),
      avatarUrl: Type.String(),
    }),
  ),
});

export const UpdateFeedbackBody = Type.Object(
  {
    status: Type.Optional(FeedbackStatusSchema),
    adminNote: Type.Optional(Type.String({ maxLength: 1000 })),
  },
  { additionalProperties: false, minProperties: 1 },
);

export const feedbackSchemas = {
  send: {
    tags: ['Feedback'],
    summary: 'Send feedback about the app',
    description: 'Shown to the superadmin team in the web dashboard.',
    body: SendFeedbackBody,
    response: { 201: Feedback, ...errorResponses(400, 401, 429) },
  },
};

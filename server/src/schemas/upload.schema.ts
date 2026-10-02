import { Type } from 'typebox';
import { IdParams, NoContent, Nullable, Uuid, errorResponses } from './common.schema.js';

export const UPLOAD_PURPOSES = ['avatar', 'rideCover', 'post', 'groupCover', 'other'] as const;

export const UploadResult = Type.Object({
  id: Uuid,
  url: Type.String({ description: 'Absolute URL; use it as avatarUrl / imageUrl / coverImageUrl.' }),
  contentType: Type.String(),
  sizeBytes: Type.Integer(),
  purpose: Nullable(Type.Enum(UPLOAD_PURPOSES)),
});

const tags = ['Uploads'];

export const uploadSchemas = {
  upload: {
    tags,
    summary: 'Upload an image',
    description:
      'multipart/form-data with a `file` field (JPEG, PNG, WebP or GIF; type is detected from the bytes) and an optional ' +
      '`purpose` field (avatar, rideCover, post, groupCover). Returns the public URL to store on the profile, ride, post or group.',
    consumes: ['multipart/form-data'],
    response: { 201: UploadResult, ...errorResponses(400, 401, 413, 415) },
  },
  remove: { tags, summary: 'Delete one of my uploads', params: IdParams, response: { 204: NoContent, ...errorResponses(401, 404) } },
};

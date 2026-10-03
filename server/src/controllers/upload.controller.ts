import { currentUser } from '../middlewares/authenticate.js';
import { UPLOAD_PURPOSES, type uploadSchemas } from '../schemas/upload.schema.js';
import type { UploadPurpose, UploadService } from '../services/upload.service.js';
import type { Rep, Req } from '../types/http.js';
import { badRequest } from '../utils/errors.js';

type S = typeof uploadSchemas;

export class UploadController {
  constructor(private readonly uploads: UploadService) {}

  upload = async (request: Req<S['upload']>, reply: Rep<S['upload']>) => {
    if (!request.isMultipart())
      throw badRequest('Send the image as multipart/form-data with a `file` field.', 'NOT_MULTIPART');
    const file = await request.file();
    if (!file) throw badRequest('The `file` field is missing.', 'FILE_REQUIRED');
    const data = await file.toBuffer();
    const purposeField = file.fields.purpose;
    const purposeValue =
      purposeField && !Array.isArray(purposeField) && purposeField.type === 'field'
        ? String(purposeField.value)
        : undefined;
    if (purposeValue !== undefined && !(UPLOAD_PURPOSES as readonly string[]).includes(purposeValue)) {
      throw badRequest(`purpose must be one of ${UPLOAD_PURPOSES.join(', ')}.`, 'VALIDATION_ERROR');
    }
    const result = await this.uploads.upload(
      currentUser(request).id,
      data,
      (purposeValue as UploadPurpose | undefined) ?? null,
    );
    return reply.status(201).send(result);
  };

  remove = async (request: Req<S['remove']>, reply: Rep<S['remove']>) => {
    await this.uploads.remove(currentUser(request).id, request.params.id);
    return reply.status(204).send();
  };
}

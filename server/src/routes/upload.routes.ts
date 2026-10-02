import { mkdir } from 'node:fs/promises';
import multipart from '@fastify/multipart';
import fastifyStatic from '@fastify/static';
import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { UploadController } from '../controllers/upload.controller.js';
import { markPublic } from '../middlewares/docs.js';
import { uploadSchemas as s } from '../schemas/upload.schema.js';

/** POST/DELETE /api/v1/uploads and public GET /uploads/* (the files themselves). */
const uploadRoutes: FastifyPluginAsyncTypebox = async (app) => {
  const { dir, maxBytes } = app.config.uploads;
  await mkdir(dir, { recursive: true });

  await app.register(async (api) => {
    await api.register(multipart, { limits: { fileSize: maxBytes, files: 1, fields: 5, parts: 6 } });
    const c = new UploadController(api.services.upload);
    api.post('/api/v1/uploads', { schema: s.upload, bodyLimit: maxBytes + 64 * 1024 }, c.upload);
    api.delete('/api/v1/uploads/:id', { schema: s.remove }, c.remove);
  });

  // File names are random UUIDs and never change, so they can be cached forever.
  await app.register(async (files) => {
    files.addHook('onRoute', markPublic);
    await files.register(fastifyStatic, {
      root: dir,
      prefix: '/uploads/',
      decorateReply: false,
      index: false,
      list: false,
      dotfiles: 'deny',
      immutable: true,
      maxAge: '365d',
      schemaHide: true,
    });
  });
};

export default uploadRoutes;

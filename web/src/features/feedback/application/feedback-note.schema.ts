import { z } from 'zod';

export const ADMIN_NOTE_MAX = 1000;

export const adminNoteSchema = z
  .string()
  .max(ADMIN_NOTE_MAX, `Keep the note under ${ADMIN_NOTE_MAX} characters.`);

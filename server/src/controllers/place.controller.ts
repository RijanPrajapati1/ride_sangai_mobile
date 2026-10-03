import { currentUser } from '../middlewares/authenticate.js';
import type { placeSchemas } from '../schemas/place.schema.js';
import type { PlaceService, Point } from '../services/place.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof placeSchemas;

function point(query: { lat?: number; lng?: number }): Point | null {
  return query.lat !== undefined && query.lng !== undefined ? { lat: query.lat, lng: query.lng } : null;
}

export class PlaceController {
  constructor(private readonly places: PlaceService) {}

  nearby = async (request: Req<S['nearby']>) => this.places.nearby(currentUser(request).id, request.query);

  list = async (request: Req<S['list']>) => this.places.list(currentUser(request).id, request.query);

  create = async (request: Req<S['create']>, reply: Rep<S['create']>) =>
    reply.status(201).send(await this.places.create(currentUser(request), request.body));

  get = async (request: Req<S['get']>) => this.places.get(request.params.id, currentUser(request).id, point(request.query));

  update = async (request: Req<S['update']>) => this.places.update(currentUser(request), request.params.id, request.body);

  remove = async (request: Req<S['remove']>, reply: Rep<S['remove']>) => {
    await this.places.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  save = async (request: Req<S['save']>) => this.places.save(currentUser(request).id, request.params.id);

  unsave = async (request: Req<S['unsave']>) => this.places.unsave(currentUser(request).id, request.params.id);

  saved = async (request: Req<S['saved']>) => this.places.saved(currentUser(request).id, request.query);

  byAuthor = async (request: Req<S['byAuthor']>) =>
    this.places.list(currentUser(request).id, { ...request.query, sort: 'newest', authorId: request.params.id });

  reviews = async (request: Req<S['reviews']>) => this.places.reviews(request.params.id, currentUser(request).id, request.query);

  review = async (request: Req<S['review']>, reply: Rep<S['review']>) => {
    const { review, created } = await this.places.review(currentUser(request), request.params.id, request.body);
    return reply.status(created ? 201 : 200).send(review);
  };

  removeReview = async (request: Req<S['removeReview']>, reply: Rep<S['removeReview']>) => {
    await this.places.removeReview(currentUser(request).id, request.params.id);
    return reply.status(204).send();
  };
}

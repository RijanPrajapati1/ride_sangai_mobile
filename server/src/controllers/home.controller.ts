import { currentUser } from '../middlewares/authenticate.js';
import type { homeSchemas } from '../schemas/home.schema.js';
import type { HomeService } from '../services/home.service.js';
import type { Req } from '../types/http.js';

type S = typeof homeSchemas;

export class HomeController {
  constructor(private readonly home: HomeService) {}

  get = async (request: Req<S['home']>) => {
    const { category, lat, lng } = request.query;
    const location = lat !== undefined && lng !== undefined ? { lat, lng } : null;
    return this.home.home(currentUser(request), category ?? 'cycling', location);
  };

  badges = async (request: Req<S['badges']>) => this.home.badges(currentUser(request).id);

  banners = async (request: Req<S['banners']>) => ({
    items: await this.home.listBanners(request.query.category),
  });

  meta = async () => this.home.meta();
}

import { currentUser } from '../middlewares/authenticate.js';
import type { rideSchemas } from '../schemas/ride.schema.js';
import type { RideService } from '../services/ride.service.js';
import type { Rep, Req } from '../types/http.js';

type S = typeof rideSchemas;

export class RideController {
  constructor(private readonly rides: RideService) {}

  discover = async (request: Req<S['discover']>) => {
    const { from, to, ...rest } = request.query;
    return this.rides.discover(currentUser(request).id, {
      ...rest,
      ...(from ? { from: new Date(from) } : {}),
      ...(to ? { to: new Date(to) } : {}),
    });
  };

  create = async (request: Req<S['create']>, reply: Rep<S['create']>) =>
    reply.status(201).send(await this.rides.create(currentUser(request), request.body));

  get = async (request: Req<S['get']>) => this.rides.get(request.params.id, currentUser(request).id);

  update = async (request: Req<S['update']>) => this.rides.update(currentUser(request), request.params.id, request.body);

  remove = async (request: Req<S['remove']>, reply: Rep<S['remove']>) => {
    await this.rides.remove(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  participants = async (request: Req<S['participants']>) => this.rides.participants(request.params.id, request.query);

  join = async (request: Req<S['join']>, reply: Rep<S['join']>) =>
    reply.status(201).send(await this.rides.requestToJoin(currentUser(request), request.params.id, request.body?.message));

  leave = async (request: Req<S['leave']>, reply: Rep<S['leave']>) => {
    await this.rides.leave(currentUser(request), request.params.id);
    return reply.status(204).send();
  };

  rideRequests = async (request: Req<S['rideRequests']>) =>
    this.rides.requestsForRide(currentUser(request), request.params.id, request.query);

  myRides = async (request: Req<S['myRides']>) => this.rides.mine(currentUser(request).id, request.query);

  inbox = async (request: Req<S['inbox']>) => this.rides.inbox(currentUser(request).id, request.query);

  byOrganizer = async (request: Req<S['byOrganizer']>) =>
    this.rides.byOrganizer(request.params.id, currentUser(request).id, request.query);

  approve = async (request: Req<S['approve']>) => this.rides.approve(currentUser(request), request.params.id);

  decline = async (request: Req<S['decline']>) =>
    this.rides.decline(currentUser(request), request.params.id, request.body?.reason);
}

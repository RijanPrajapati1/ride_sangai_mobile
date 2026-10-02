/**
 * Demo data mirroring the mobile app's dummy data (the *LocalDataSource classes in mobile/lib),
 * so the app shows the same riders, rides, posts, chats and groups once it is
 * connected to this API.
 *
 *   npm run db:seed        (skips if the database already has users)
 *
 * Logins (the same ones the app's demo uses):
 *   demo@bikersync.app / biker123   → Alex Shrestha (rider; "Try Demo Login")
 *   admin@gmail.com    / Test@1234  → Admin
 *   <firstname>@bikersync.app / biker123 → every other rider (aarav@, priya@, …)
 *
 * Deliberate differences from the dummy data:
 *   - "Ring Road Endurance Loop" (Alex's ride with the join requests) is in the
 *     future, so the organizer flow (approve/decline) can be tried.
 *   - Counters (likes, followers, members) come from real rows, so they are
 *     smaller than the dummy's hard-coded numbers.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { loadConfig, loadDotEnv } from '../src/config/env.js';
import { RIDE_TYPE_CATEGORY, type ExperienceLevel, type RideDifficulty, type RideType } from '../src/constants/enums.js';
import { createPrisma } from '../src/db/prisma.js';
import { PasswordHasher } from '../src/utils/password.js';

loadDotEnv();
const config = loadConfig();
const prisma = createPrisma(config.db, 'ride-sangai-seed');

const texts = JSON.parse(readFileSync(fileURLToPath(new URL('./seed-data/texts.json', import.meta.url)), 'utf8')) as {
  rideDescriptions: Record<string, string>;
  bios: Record<string, string>;
  posts: Record<string, string>;
  messages: Record<string, string>;
};

const NOW = Date.now();
const MIN = 60_000;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;
const ago = (ms: number) => new Date(NOW - ms);
/** `days` from today at hh:mm Nepal time (UTC+05:45), like the app's `at()` helper. */
function at(days: number, hour: number, minute: number): Date {
  const npt = new Date(NOW + (5 * 60 + 45) * MIN);
  const date = Date.UTC(npt.getUTCFullYear(), npt.getUTCMonth(), npt.getUTCDate() + days, hour, minute);
  return new Date(date - (5 * 60 + 45) * MIN);
}
const avatar = (img: number) => `https://i.pravatar.cc/150?img=${img}`;
const picsum = (seed: string, w = 900, h = 600) => `https://picsum.photos/seed/${seed}/${w}/${h}`;

// --- People (mobile/lib/core/dummy/dummy_people.dart + user_local_datasource.dart) ---

interface Person {
  key: string;
  bioKey: string;
  name: string;
  img: number;
  email: string;
  location: string;
  level: ExperienceLevel;
  type: RideType;
  interests: string[];
}

const PEOPLE: Person[] = [
  { key: 'u_001', bioKey: 'me', name: 'Alex Shrestha', img: 12, email: 'demo@bikersync.app', location: 'Kathmandu, Nepal', level: 'intermediate', type: 'road', interests: ['Hill Climbs', 'Road Cycling', 'Photography', 'Coffee Rides'] },
  { key: 'u_002', bioKey: 'aarav', name: 'Aarav Poudel', img: 13, email: 'aarav@bikersync.app', location: 'Kathmandu, Nepal', level: 'advanced', type: 'social', interests: ['Group Rides', 'Heritage Tours', 'Endurance'] },
  { key: 'u_003', bioKey: 'priya', name: 'Priya Gurung', img: 32, email: 'priya@bikersync.app', location: 'Bhaktapur, Nepal', level: 'intermediate', type: 'touring', interests: ['Heritage Tours', 'Gravel', 'Trail Photography'] },
  { key: 'u_004', bioKey: 'bibek', name: 'Bibek Tamang', img: 15, email: 'bibek@bikersync.app', location: 'Kathmandu, Nepal', level: 'beginner', type: 'nightRide', interests: ['Night Rides', 'City Loops'] },
  { key: 'u_005', bioKey: 'anita', name: 'Anita Magar', img: 45, email: 'anita@bikersync.app', location: 'Budhanilkantha, Nepal', level: 'advanced', type: 'mountain', interests: ['Mountain Biking', 'Trail Running', 'Wildlife'] },
  { key: 'u_006', bioKey: 'suresh', name: 'Suresh Thapa', img: 18, email: 'suresh@bikersync.app', location: 'Bhaktapur, Nepal', level: 'pro', type: 'hillClimb', interests: ['Hill Climbs', 'Endurance', 'Bike Maintenance'] },
  { key: 'u_007', bioKey: 'kabita', name: 'Kabita Lama', img: 47, email: 'kabita@bikersync.app', location: 'Lalitpur, Nepal', level: 'intermediate', type: 'social', interests: ['Social Rides', 'Coffee Rides'] },
  { key: 'u_008', bioKey: 'nischal', name: 'Nischal Karki', img: 22, email: 'nischal@bikersync.app', location: 'Thankot, Nepal', level: 'advanced', type: 'hillClimb', interests: ['Hill Climbs', 'Gravel'] },
  { key: 'u_009', bioKey: 'roshani', name: 'Roshani Basnet', img: 48, email: 'roshani@bikersync.app', location: 'Banepa, Nepal', level: 'intermediate', type: 'gravel', interests: ['Gravel', 'Bikepacking'] },
  { key: 'u_010', bioKey: 'dipesh', name: 'Dipesh Shahi', img: 25, email: 'dipesh@bikersync.app', location: 'Lalitpur, Nepal', level: 'pro', type: 'mountain', interests: ['Mountain Biking', 'Trail Building'] },
  { key: 'u_011', bioKey: 'sabina', name: 'Sabina Rai', img: 44, email: 'sabina@bikersync.app', location: 'Kirtipur, Nepal', level: 'beginner', type: 'touring', interests: ['Heritage Tours', 'Photography'] },
];

// [follower, following]
const FOLLOWS: Array<[string, string]> = [
  ['u_001', 'u_002'], ['u_001', 'u_005'], ['u_002', 'u_001'], ['u_009', 'u_001'], ['u_007', 'u_001'],
  ['u_003', 'u_006'], ['u_008', 'u_006'], ['u_010', 'u_006'], ['u_002', 'u_006'], ['u_005', 'u_010'],
  ['u_011', 'u_003'], ['u_004', 'u_007'], ['u_009', 'u_008'],
];

// --- Rides (ride_local_datasource.dart) -------------------------------------------

interface SeedRide {
  key: string;
  title: string;
  type: RideType;
  difficulty: RideDifficulty;
  date: Date;
  meetingPoint: string;
  distanceKm: number;
  durationMinutes: number;
  organizer: string;
  max: number;
  requirements: string[];
  participants: string[];
  image: string;
}

const RIDES: SeedRide[] = [
  { key: 'r_001', title: 'Kathmandu Sunrise Ride', type: 'social', difficulty: 'easy', date: at(2, 5, 30), meetingPoint: 'Ratna Park, Kathmandu', distanceKm: 18, durationMinutes: 75, organizer: 'u_002', max: 25, requirements: ['Helmet', 'Front & rear lights', 'Water bottle'], participants: ['u_003', 'u_004', 'u_007'], image: 'ktm-sunrise' },
  { key: 'r_002', title: 'Bhaktapur Heritage Loop', type: 'touring', difficulty: 'easy', date: at(4, 7, 0), meetingPoint: 'Durbar Square, Bhaktapur', distanceKm: 22, durationMinutes: 100, organizer: 'u_003', max: 20, requirements: ['Helmet', 'Comfortable saddle', 'Camera optional'], participants: ['u_006'], image: 'bhaktapur-loop' },
  { key: 'r_003', title: 'Nagarkot Weekend Climb', type: 'hillClimb', difficulty: 'hard', date: at(6, 5, 0), meetingPoint: 'Bhaktapur Bus Park', distanceKm: 52, durationMinutes: 240, organizer: 'u_006', max: 30, requirements: ['Road/gravel bike', 'Helmet', 'Spare tube & pump', 'Nutrition for 4h+'], participants: ['u_008', 'u_010', 'u_005', 'u_001'], image: 'nagarkot-climb' },
  { key: 'r_004', title: 'Lalitpur Evening Spin', type: 'social', difficulty: 'easy', date: at(1, 17, 30), meetingPoint: 'Patan Durbar Square', distanceKm: 15, durationMinutes: 60, organizer: 'u_007', max: 18, requirements: ['Rear light', 'Reflective vest recommended'], participants: ['u_009', 'u_011'], image: 'lalitpur-spin' },
  { key: 'r_005', title: 'Godavari Hills Challenge', type: 'mountain', difficulty: 'hard', date: at(9, 6, 0), meetingPoint: 'Godavari Botanical Garden Gate', distanceKm: 34, durationMinutes: 210, organizer: 'u_010', max: 15, requirements: ['Full-suspension or hardtail MTB', 'Helmet', 'Knee pads recommended'], participants: ['u_004'], image: 'godavari-hills' },
  { key: 'r_006', title: 'Shivapuri Forest Trail', type: 'mountain', difficulty: 'moderate', date: at(12, 6, 30), meetingPoint: 'Shivapuri Park Entrance, Sundarijal', distanceKm: 28, durationMinutes: 180, organizer: 'u_005', max: 20, requirements: ['MTB or gravel bike', 'Park entry fee', 'Packed lunch'], participants: ['u_007'], image: 'shivapuri-trail' },
  { key: 'r_007', title: 'Chandragiri Hill Climb', type: 'hillClimb', difficulty: 'hard', date: at(15, 5, 45), meetingPoint: 'Thankot Chowk', distanceKm: 24, durationMinutes: 150, organizer: 'u_008', max: 12, requirements: ['Low gearing recommended', 'Helmet', 'Windbreaker for the descent'], participants: ['u_003'], image: 'chandragiri-climb' },
  { key: 'r_008', title: 'Dhulikhel Sunrise Gravel', type: 'gravel', difficulty: 'moderate', date: at(18, 5, 0), meetingPoint: 'Banepa Bus Stand', distanceKm: 40, durationMinutes: 200, organizer: 'u_009', max: 16, requirements: ['Gravel/MTB tyres 35mm+', 'Helmet', 'Spare tube'], participants: ['u_011', 'u_006'], image: 'dhulikhel-gravel' },
  { key: 'r_009', title: 'Thamel Night Ride', type: 'nightRide', difficulty: 'easy', date: at(3, 20, 0), meetingPoint: 'Thamel Chowk', distanceKm: 12, durationMinutes: 55, organizer: 'u_004', max: 25, requirements: ['Front & rear lights (mandatory)', 'Helmet'], participants: ['u_005'], image: 'thamel-night' },
  { key: 'r_010', title: 'Kirtipur Heritage Circuit', type: 'touring', difficulty: 'easy', date: at(7, 6, 45), meetingPoint: 'Kirtipur Bus Park', distanceKm: 20, durationMinutes: 90, organizer: 'u_011', max: 20, requirements: ['Helmet', 'Water bottle'], participants: ['u_010'], image: 'kirtipur-circuit' },
  { key: 'r_011', title: 'Ring Road Endurance Loop', type: 'road', difficulty: 'moderate', date: at(5, 6, 0), meetingPoint: 'Koteshwor Chowk', distanceKm: 27, durationMinutes: 95, organizer: 'u_001', max: 20, requirements: ['Helmet', 'Water bottle'], participants: ['u_003', 'u_007'], image: 'ring-road-loop' },
  { key: 'r_012', title: 'Budhanilkantha Foothill Ride', type: 'road', difficulty: 'moderate', date: ago(12 * DAY), meetingPoint: 'Narayanthan Chowk', distanceKm: 19, durationMinutes: 80, organizer: 'u_002', max: 20, requirements: ['Helmet'], participants: ['u_001'], image: 'budhanilkantha' },
  { key: 'r_101', title: 'Ghorepani Poon Hill Trek', type: 'multiDayTrek', difficulty: 'moderate', date: at(18, 5, 0), meetingPoint: 'Pokhara Baglung Bus Park', distanceKm: 38, durationMinutes: 4320, organizer: 'u_006', max: 14, requirements: ['Trekking poles', 'Warm layers', 'Tea house booking confirmed'], participants: ['u_005', 'u_009'], image: 'poonhill-trek' },
  { key: 'r_102', title: 'Mardi Himal Base Camp Trek', type: 'multiDayTrek', difficulty: 'hard', date: at(30, 5, 30), meetingPoint: 'Pokhara Lakeside', distanceKm: 46, durationMinutes: 5760, organizer: 'u_005', max: 10, requirements: ['Trekking poles', 'Down jacket', 'Headlamp'], participants: ['u_006'], image: 'mardi-himal-trek' },
  { key: 'r_103', title: 'Langtang Valley Trek', type: 'multiDayTrek', difficulty: 'hard', date: at(45, 5, 0), meetingPoint: 'Syabrubesi Bus Park', distanceKm: 77, durationMinutes: 10080, organizer: 'u_006', max: 12, requirements: ['Trekking permit (TIMS)', 'Sleeping bag', 'Water purification tablets'], participants: ['u_002', 'u_005'], image: 'langtang-trek' },
  { key: 'r_104', title: 'Chisapani–Nagarkot Ridge Trek', type: 'summitTrek', difficulty: 'moderate', date: at(10, 6, 0), meetingPoint: 'Sundarijal Gate', distanceKm: 32, durationMinutes: 2880, organizer: 'u_002', max: 16, requirements: ['Trekking poles', 'Rain jacket'], participants: ['u_007'], image: 'chisapani-nagarkot-trek' },
  { key: 'r_105', title: 'Phulchowki Hill Hike', type: 'dayHike', difficulty: 'moderate', date: at(6, 6, 30), meetingPoint: 'Godavari Botanical Garden Gate', distanceKm: 16, durationMinutes: 300, organizer: 'u_011', max: 20, requirements: ['Trekking shoes', 'Water bottle'], participants: ['u_010'], image: 'phulchowki-hike' },
  { key: 'r_106', title: 'Nagarjun Forest Hike', type: 'natureWalk', difficulty: 'easy', date: at(3, 7, 0), meetingPoint: 'Nagarjun Gate, Balaju', distanceKm: 8, durationMinutes: 150, organizer: 'u_007', max: 25, requirements: ['Park entry fee', 'Water bottle'], participants: ['u_011', 'u_009'], image: 'nagarjun-hike' },
  { key: 'r_107', title: 'Sundarijal to Chisapani Hike', type: 'dayHike', difficulty: 'moderate', date: at(9, 6, 15), meetingPoint: 'Sundarijal Bus Stop', distanceKm: 14, durationMinutes: 360, organizer: 'u_011', max: 18, requirements: ['Park entry fee', 'Trekking shoes', 'Packed lunch'], participants: ['u_007'], image: 'sundarijal-hike' },
  { key: 'r_108', title: 'Champadevi Family Hike', type: 'familyHike', difficulty: 'easy', date: at(4, 7, 30), meetingPoint: 'Pharping Chowk', distanceKm: 9, durationMinutes: 210, organizer: 'u_007', max: 25, requirements: ['Water bottle', 'Snacks'], participants: ['u_011'], image: 'champadevi-hike' },
  { key: 'r_109', title: 'Kathmandu–Nagarkot Night Cruise', type: 'touringRide', difficulty: 'easy', date: at(7, 17, 30), meetingPoint: 'Bhaktapur Bypass, Bhaktapur', distanceKm: 52, durationMinutes: 150, organizer: 'u_008', max: 20, requirements: ['Riding license', 'Helmet (mandatory)', 'Reflective jacket'], participants: ['u_010'], image: 'nagarkot-night-ride' },
  { key: 'r_110', title: 'Chitwan Highway Run', type: 'touringRide', difficulty: 'moderate', date: at(16, 6, 0), meetingPoint: 'Kalanki Chowk', distanceKm: 320, durationMinutes: 600, organizer: 'u_008', max: 15, requirements: ['Riding license', 'Helmet (mandatory)', 'Full tank'], participants: ['u_010', 'u_002'], image: 'chitwan-ride' },
  { key: 'r_111', title: 'Shivapuri Off-Road Trail Ride', type: 'offRoadRide', difficulty: 'hard', date: at(12, 6, 30), meetingPoint: 'Sundarijal Gate', distanceKm: 45, durationMinutes: 240, organizer: 'u_010', max: 12, requirements: ['Dual-sport or adventure bike', 'Riding gear', 'Park entry fee'], participants: ['u_008'], image: 'shivapuri-offroad-ride' },
  { key: 'r_112', title: 'Mustang Overland Ride', type: 'touringRide', difficulty: 'hard', date: at(50, 5, 0), meetingPoint: 'Pokhara Lakeside', distanceKm: 380, durationMinutes: 4320, organizer: 'u_008', max: 10, requirements: ['Restricted area permit', 'Adventure/touring bike', 'Riding gear'], participants: ['u_010'], image: 'mustang-ride' },
];

// Join requests on Alex's ride (ride_request_local_datasource.dart on intial-design).
const REQUESTS = [
  { user: 'u_009', ride: 'r_011', hoursAgo: 3, status: 'pending', message: 'Training for my first century ride, always looking for group support.' },
  { user: 'u_008', ride: 'r_011', hoursAgo: 6, status: 'pending', message: 'Ridden the ring road a dozen times, happy to help pace the group.' },
  { user: 'u_011', ride: 'r_011', hoursAgo: 20, status: 'pending', message: 'New to endurance rides but comfortable on the bike, excited to join!' },
  { user: 'u_010', ride: 'r_011', hoursAgo: 30, status: 'approved', message: 'Usually on MTB trails but want to build road endurance for a race.' },
  {
    user: 'u_004',
    ride: 'r_011',
    hoursAgo: 50,
    status: 'declined',
    message: 'Only free in the evenings, might have to leave the group early.',
    declineReason: 'This route needs riders to stay for the full 4-hour loop — hope to see you on a shorter ride soon!',
  },
  // Alex's own pending request (r_004 shows "Requested" in the app).
  { user: 'u_001', ride: 'r_004', hoursAgo: 10, status: 'pending', message: null },
] as const;

// --- Community (community_local_datasource.dart) ---------------------------------

const POSTS = [
  { key: 'p_001', author: 'u_006', hoursAgo: 2, image: 'nagarkot-post', likes: 10 },
  { key: 'p_002', author: 'u_003', hoursAgo: 6, image: 'bhaktapur-post', likes: 8 },
  { key: 'p_003', author: 'u_010', hoursAgo: 11, image: null, likes: 6 },
  { key: 'p_004', author: 'u_007', hoursAgo: 20, image: 'lalitpur-post', likes: 9 },
  { key: 'p_005', author: 'u_009', hoursAgo: 30, image: null, likes: 5 },
  { key: 'p_006', author: 'u_001', hoursAgo: 48, image: 'ring-road-post', likes: 4 },
];

const COMMENTS = [
  { post: 'p_001', author: 'u_008', minutesAgo: 70, text: 'That descent is no joke, nice work!', likes: ['u_006', 'u_002', 'u_005', 'u_010'] },
  { post: 'p_001', author: 'u_001', minutesAgo: 60, text: 'Inspiring! Adding this to my bucket list.', likes: ['u_006'] },
  { post: 'p_002', author: 'u_011', minutesAgo: 300, text: 'The light in that last photo is unreal.', likes: ['u_003', 'u_002'] },
  { post: 'p_004', author: 'u_002', minutesAgo: 19 * 60, text: "This is what it's all about!", likes: ['u_007', 'u_004', 'u_005', 'u_009', 'u_011'] },
  { post: 'p_004', author: 'u_004', minutesAgo: 18 * 60, text: 'Bring them to the night ride next!', likes: ['u_007', 'u_002', 'u_009'] },
  { post: 'p_004', author: 'u_005', minutesAgo: 17 * 60, text: 'Love to see it 🙌', likes: ['u_007'] },
  { post: 'p_005', author: 'u_010', minutesAgo: 28 * 60, text: 'Count me in, what time?', likes: [] },
];

// --- Direct messages (message_local_datasource.dart) -------------------------------

const CONVERSATIONS = [
  {
    key: 'c_001',
    with: 'u_002',
    // Alex has read up to just before m_004 → 2 unread, as in the app.
    meReadMinutesAgo: 59,
    messages: [
      ['m_001', 'u_002', 90], ['m_002', 'u_001', 75], ['m_003', 'u_002', 60],
      ['m_004', 'u_002', 58], ['m_005', 'u_001', 40], ['m_006', 'u_002', 12],
    ],
  },
  { key: 'c_002', with: 'u_006', meReadMinutesAgo: 0, messages: [['m_010', 'u_006', 200], ['m_011', 'u_001', 190], ['m_012', 'u_006', 180]] },
  { key: 'c_003', with: 'u_003', meReadMinutesAgo: 0, messages: [['m_020', 'u_003', 1560]] },
  { key: 'c_004', with: 'u_005', meReadMinutesAgo: 2881, messages: [['m_030', 'u_005', 2880]] },
  { key: 'c_005', with: 'u_007', meReadMinutesAgo: 0, messages: [['m_040', 'u_007', 5760]] },
] as const;

// --- Groups (group_local_datasource.dart on intial-design) -----------------------------

const GROUPS = [
  { key: 'g_001', name: 'Kathmandu Riders', owner: 'u_002', daysAgo: 420, cover: 'kathmandu-riders', members: ['u_001', 'u_009', 'u_003'], description: "The valley's largest road cycling crew — sunrise rides, ring road loops, and monthly meetups." },
  { key: 'g_002', name: 'Pulsar Bike Riders Nepal', owner: 'u_006', daysAgo: 610, cover: 'pulsar-bike-riders', members: ['u_008', 'u_010', 'u_002', 'u_004'], description: 'For Pulsar owners and motorbike touring fans — highway runs, maintenance tips, and group rides.' },
  { key: 'g_003', name: 'Trail Blazers MTB', owner: 'u_008', daysAgo: 260, cover: 'trail-blazers-mtb', members: ['u_001'], description: 'Mountain bikers chasing singletrack and technical descents around the valley rim.' },
  { key: 'g_004', name: 'Himalayan Hikers Club', owner: 'u_005', daysAgo: 190, cover: 'himalayan-hikers', members: ['u_009', 'u_006'], description: 'Weekend treks, acclimatization hikes, and trip planning for the hills around Kathmandu.' },
  { key: 'g_005', name: 'Weekend Warriors', owner: 'u_007', daysAgo: 75, cover: 'weekend-warriors', members: [], description: 'Casual, no-drop rides for anyone who just wants good company and a coffee stop.' },
];

const GROUP_MESSAGES = [
  { group: 'g_001', sender: 'u_002', minutesAgo: 240, text: "Sunrise ride this Saturday, Ratna Park, 5:30am. Who's in?" },
  { group: 'g_001', sender: 'u_009', minutesAgo: 210, text: 'Count me in! Bringing a friend too.' },
  { group: 'g_001', sender: 'u_001', minutesAgo: 180, text: 'Same, see everyone there!' },
  { group: 'g_003', sender: 'u_008', minutesAgo: 500, text: 'Shivapuri trail is in great shape after the rain, way less dust.' },
  { group: 'g_003', sender: 'u_001', minutesAgo: 480, text: 'Good to know, been meaning to get back up there.' },
];

// --- Notifications for Alex (notification_local_datasource.dart) -------------------------

const NOTIFICATIONS = [
  { type: 'requestApproved', title: 'Request approved', body: 'Suresh Thapa approved your request to join Nagarkot Weekend Climb.', minutesAgo: 25, actor: 'u_006', read: false, entity: ['ride', 'r_003'] },
  { type: 'newMessage', title: 'New message', body: "Aarav Poudel sent you a message about Saturday's ride.", minutesAgo: 60, actor: 'u_002', read: false, entity: ['conversation', 'c_001'] },
  { type: 'rideReminder', title: 'Ride starting soon', body: "Lalitpur Evening Spin starts tomorrow. Don't forget your helmet!", minutesAgo: 140, actor: null, read: false, entity: ['ride', 'r_004'] },
  { type: 'newFollower', title: 'New follower', body: 'Roshani Basnet started following you.', minutesAgo: 320, actor: 'u_009', read: true, entity: ['user', 'u_009'] },
  { type: 'like', title: 'New like', body: 'Kabita Lama liked your post.', minutesAgo: 480, actor: 'u_007', read: true, entity: ['post', 'p_006'] },
  { type: 'comment', title: 'New comment', body: 'Bibek Tamang commented on your ride photo.', minutesAgo: 600, actor: 'u_004', read: true, entity: ['post', 'p_006'] },
  { type: 'rideUpdated', title: 'Ride updated', body: 'The meeting point for Shivapuri Forest Trail has changed.', minutesAgo: 1400, actor: null, read: true, entity: ['ride', 'r_006'] },
  { type: 'requestDeclined', title: 'Request declined', body: "Your request to join Godavari Hills Challenge was declined — it's full.", minutesAgo: 2100, actor: null, read: true, entity: ['ride', 'r_005'] },
] as const;

const SAFETY_TIPS = {
  cycling: 'Always wear a certified helmet and run lights after dark.',
  trekking: 'Check the weather and share your route before high-altitude treks.',
  hiking: 'Carry enough water and let someone know your hiking plan.',
  riding: 'Wear a certified helmet and check your bike before long rides.',
} as const;
const NOUNS = {
  cycling: ['Ride', 'Rides'],
  trekking: ['Trek', 'Treks'],
  hiking: ['Hike', 'Hikes'],
  riding: ['Ride', 'Rides'],
} as const;

async function main(): Promise<void> {
  if ((await prisma.user.count()) > 0) {
    console.log('Database already has users — skipping seed (run `npm run db:reset` for a fresh demo database).');
    return;
  }
  const passwords = new PasswordHasher(config.auth.hash);
  const riderHash = await passwords.hash('biker123');
  const adminHash = await passwords.hash('Test@1234');

  const ids = new Map<string, string>();
  const id = (key: string) => {
    const value = ids.get(key);
    if (!value) throw new Error(`Unknown seed key ${key}`);
    return value;
  };

  await prisma.$transaction(
    async (tx) => {
      // Users and preferences
      for (const p of PEOPLE) {
        const user = await tx.user.create({
          data: {
            email: p.email,
            passwordHash: riderHash,
            name: p.name,
            avatarUrl: avatar(p.img),
            bio: texts.bios[p.bioKey] ?? '',
            location: p.location,
            experienceLevel: p.level,
            preferredRideType: p.type,
            interests: p.interests,
            createdAt: ago(400 * DAY),
            preferences: { create: {} },
          },
          select: { id: true },
        });
        ids.set(p.key, user.id);
      }
      const admin = await tx.user.create({
        data: { email: 'admin@gmail.com', passwordHash: adminHash, name: 'Admin', role: 'admin', preferences: { create: {} } },
        select: { id: true },
      });
      ids.set('admin_001', admin.id);

      await tx.follow.createMany({
        data: FOLLOWS.map(([follower, following], i) => ({ followerId: id(follower), followingId: id(following), createdAt: ago((30 - i) * DAY) })),
      });

      // Rides, participants and requests
      let seq = 0;
      for (const r of RIDES) {
        const ride = await tx.ride.create({
          data: {
            organizerId: id(r.organizer),
            title: r.title,
            description: texts.rideDescriptions[r.key] ?? r.title,
            rideType: r.type,
            category: RIDE_TYPE_CATEGORY[r.type],
            difficulty: r.difficulty,
            startsAt: r.date,
            meetingPoint: r.meetingPoint,
            distanceKm: r.distanceKm,
            durationMinutes: r.durationMinutes,
            maxParticipants: r.max,
            requirements: r.requirements,
            imageUrl: picsum(r.image),
            createdAt: ago(40 * DAY),
          },
          select: { id: true },
        });
        ids.set(r.key, ride.id);
        for (const participant of r.participants) {
          seq += 1;
          const joinedAt = new Date(Math.min(r.date.getTime() - (1 + seq) * DAY, NOW - seq * HOUR));
          await tx.rideRequest.create({
            data: {
              rideId: ride.id,
              userId: id(participant),
              status: 'approved',
              requestedAt: new Date(joinedAt.getTime() - 6 * HOUR),
              decidedAt: joinedAt,
              decidedById: id(r.organizer),
            },
          });
        }
      }
      for (const q of REQUESTS) {
        const requestedAt = ago(q.hoursAgo * HOUR);
        const decided = q.status !== 'pending';
        await tx.rideRequest.create({
          data: {
            rideId: id(q.ride),
            userId: id(q.user),
            status: q.status,
            message: q.message,
            declineReason: 'declineReason' in q ? q.declineReason : null,
            requestedAt,
            decidedAt: decided ? new Date(requestedAt.getTime() + HOUR) : null,
            decidedById: decided ? id(RIDES.find((r) => r.key === q.ride)!.organizer) : null,
          },
        });
      }

      // Posts, likes, comments
      const others = PEOPLE.map((p) => p.key).filter((key) => key !== 'u_001');
      for (const post of POSTS) {
        const created = await tx.post.create({
          data: {
            authorId: id(post.author),
            text: texts.posts[post.key] ?? '',
            imageUrl: post.image ? picsum(post.image, 800, 600) : null,
            createdAt: ago(post.hoursAgo * HOUR),
          },
          select: { id: true },
        });
        ids.set(post.key, created.id);
        // Alex has liked p_001 only, as in the app; other likes come from the rest of the cast.
        const likers = [...(post.key === 'p_001' ? ['u_001'] : []), ...others.filter((key) => key !== post.author)].slice(0, post.likes);
        await tx.postLike.createMany({ data: likers.map((key) => ({ postId: created.id, userId: id(key) })) });
      }
      for (const c of COMMENTS) {
        const comment = await tx.comment.create({
          data: { postId: id(c.post), authorId: id(c.author), text: c.text, createdAt: ago(c.minutesAgo * MIN) },
          select: { id: true },
        });
        await tx.commentLike.createMany({ data: c.likes.map((key) => ({ commentId: comment.id, userId: id(key) })) });
      }

      // Conversations and messages
      for (const c of CONVERSATIONS) {
        const [a, b] = [id('u_001'), id(c.with)].sort();
        const firstAt = Math.max(...c.messages.map(([, , minutes]) => minutes));
        const conversation = await tx.conversation.create({
          data: { userAId: a!, userBId: b!, createdAt: ago((firstAt + 1) * MIN), lastMessageAt: ago((firstAt + 1) * MIN) },
          select: { id: true },
        });
        ids.set(c.key, conversation.id);
        await tx.conversationParticipant.createMany({
          data: [
            { conversationId: conversation.id, userId: id('u_001'), lastReadAt: ago(c.meReadMinutesAgo * MIN) },
            { conversationId: conversation.id, userId: id(c.with), lastReadAt: new Date(NOW) },
          ],
        });
        for (const [key, sender, minutes] of c.messages) {
          await tx.message.create({
            data: { conversationId: conversation.id, senderId: id(sender), text: texts.messages[key] ?? '…', createdAt: ago(minutes * MIN) },
          });
        }
      }

      // Groups, members, group chat
      for (const g of GROUPS) {
        const createdAt = ago(g.daysAgo * DAY);
        const group = await tx.group.create({
          data: { ownerId: id(g.owner), name: g.name, description: g.description, coverImageUrl: picsum(g.cover), createdAt },
          select: { id: true },
        });
        ids.set(g.key, group.id);
        await tx.groupMember.createMany({
          data: [
            { groupId: group.id, userId: id(g.owner), role: 'owner', joinedAt: createdAt },
            ...g.members.map((key, i) => ({ groupId: group.id, userId: id(key), joinedAt: new Date(createdAt.getTime() + (i + 1) * 7 * DAY) })),
          ],
        });
      }
      for (const m of GROUP_MESSAGES) {
        await tx.groupMessage.create({ data: { groupId: id(m.group), senderId: id(m.sender), text: m.text, createdAt: ago(m.minutesAgo * MIN) } });
      }

      // Alex's notifications
      for (const n of NOTIFICATIONS) {
        const createdAt = ago(n.minutesAgo * MIN);
        await tx.notification.create({
          data: {
            recipientId: id('u_001'),
            type: n.type,
            title: n.title,
            body: n.body,
            actorId: n.actor ? id(n.actor) : null,
            entityType: n.entity[0],
            entityId: id(n.entity[1]),
            readAt: n.read ? new Date(createdAt.getTime() + 30 * MIN) : null,
            createdAt,
          },
        });
      }

      // Home carousel (home_banner_carousel.dart)
      let order = 0;
      for (const category of ['cycling', 'trekking', 'hiking', 'riding'] as const) {
        const [singular, noun] = NOUNS[category];
        await tx.banner.createMany({
          data: [
            { category, title: 'Ride with friends', subtitle: `Invite friends to Biker Sync and plan your next ${singular.toLowerCase()} together.`, ctaLabel: 'Invite friends', icon: 'group_add_outlined', theme: 'primary', sortOrder: order++ },
            { category, title: "This week's challenge", subtitle: `Join 3 ${noun.toLowerCase()} this week to earn the Explorer badge.`, ctaLabel: 'View challenge', icon: 'emoji_events_outlined', theme: 'secondary', sortOrder: order++ },
            { category, title: 'Safety first', subtitle: SAFETY_TIPS[category], ctaLabel: 'Read safety tips', icon: 'health_and_safety_outlined', theme: 'success', sortOrder: order++ },
          ],
        });
      }
    },
    { timeout: 120_000, maxWait: 10_000 },
  );

  const counts = {
    users: await prisma.user.count(),
    rides: await prisma.ride.count(),
    rideRequests: await prisma.rideRequest.count(),
    posts: await prisma.post.count(),
    conversations: await prisma.conversation.count(),
    groups: await prisma.group.count(),
    notifications: await prisma.notification.count(),
    banners: await prisma.banner.count(),
  };
  console.log('Seeded demo data:', counts);
  console.log('Log in as demo@bikersync.app / biker123 (rider) or admin@gmail.com / Test@1234 (admin).');
}

main()
  .catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());

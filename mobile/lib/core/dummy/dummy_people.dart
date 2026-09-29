/// Shared cast of dummy riders used across local data sources so the same
/// person (name + avatar) shows up consistently in rides, messages, and the
/// community feed. Not consumed outside the data layer.
class DummyPerson {
  final String id;
  final String name;
  final String avatarUrl;

  const DummyPerson(this.id, this.name, this.avatarUrl);
}

class DummyPeople {
  DummyPeople._();

  static const me = DummyPerson('u_001', 'Alex Shrestha', 'https://i.pravatar.cc/150?img=12');

  static const aarav = DummyPerson('u_002', 'Aarav Poudel', 'https://i.pravatar.cc/150?img=13');
  static const priya = DummyPerson('u_003', 'Priya Gurung', 'https://i.pravatar.cc/150?img=32');
  static const bibek = DummyPerson('u_004', 'Bibek Tamang', 'https://i.pravatar.cc/150?img=15');
  static const anita = DummyPerson('u_005', 'Anita Magar', 'https://i.pravatar.cc/150?img=45');
  static const suresh = DummyPerson('u_006', 'Suresh Thapa', 'https://i.pravatar.cc/150?img=18');
  static const kabita = DummyPerson('u_007', 'Kabita Lama', 'https://i.pravatar.cc/150?img=47');
  static const nischal = DummyPerson('u_008', 'Nischal Karki', 'https://i.pravatar.cc/150?img=22');
  static const roshani = DummyPerson('u_009', 'Roshani Basnet', 'https://i.pravatar.cc/150?img=48');
  static const dipesh = DummyPerson('u_010', 'Dipesh Shahi', 'https://i.pravatar.cc/150?img=25');
  static const sabina = DummyPerson('u_011', 'Sabina Rai', 'https://i.pravatar.cc/150?img=44');

  static const List<DummyPerson> all = [
    me, aarav, priya, bibek, anita, suresh, kabita, nischal, roshani, dipesh, sabina,
  ];

  static DummyPerson byId(String id) => all.firstWhere((p) => p.id == id, orElse: () => me);
}

import 'package:tic_tac_toe.server/api.dart';
import 'package:fixnum/fixnum.dart';

class AuthService {
  // TODO(kharland): Delete or delegate to database when it exists.
  static final _VALID_USERS = <Int64>[JONAH.id, MATAN.id, KENDAL.id, HARRY.id];

  bool isUserValid(Int64 userId) => _VALID_USERS.contains(userId);
}

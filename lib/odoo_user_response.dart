import 'odoo_api_connector.dart';

class AuthenticateCallback {
  bool isSuccess = false;
  late OdooResponse _response;
  String? _newSessionId;

  AuthenticateCallback(bool isSuccess, OdooResponse response, String? newSessionId) {
    this.isSuccess = isSuccess;
    _response = response;
    _newSessionId = newSessionId;
  }

  String? getSessionId() {
    return this._newSessionId;
  }

  OdooUser getUser() {
    return OdooUser().parse(_response, _newSessionId);
  }

  Map? getError() {
    return !this.isSuccess ? this._response.getError() : null;
  }


}

class OdooUser {
  var name, sessionId, uid, database, username, companyId, partnerId;
  var lang, tz;

  OdooUser parse(OdooResponse response, String? sessionId) {
    if (!response.hasError()) {
      this.sessionId = sessionId;
      Map data = response.getResult();
      name = data['name'];
      uid = data['uid'];
      database = data['db'];
      username = data['username'];
      companyId = data['company_id'];
      partnerId = data['partner_id'];
      lang = data['user_context']['lang'];
      tz = data['user_context']['tz'];
    }
    return this;
  }

  @override
  String toString() {
    var map = {
      "name": name,
      "uid": uid,
      "partner_id": partnerId,
      "company_id": companyId,
      "username": username,
      "lang": lang,
      "timezone": tz,
      "database": database,
      "session_id": sessionId
    };
    return map.toString();
  }
}

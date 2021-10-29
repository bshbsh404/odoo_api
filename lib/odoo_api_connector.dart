import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'odoo_version.dart';

abstract class OdooConnector {
  late http.Client _client;
  late String _serverURL;
  Map<String, String> _headers = {};
  bool _debugRPC = false;
  OdooVersion odooVersion = new OdooVersion();
  List _databases = [];
  String? _sessionId;

  OdooConnector(String serverURL) {
    this._serverURL = serverURL;
    _client = http.Client();
  }

  void setSessionId(String sessionId) {
    _sessionId = sessionId;
  }

  // connect to odoo and set version and databases
  Future<OdooVersion> connect() async {
    odooVersion = await getVersionInfo();
    _databases = await getDatabases();
    return odooVersion;
  }

  // get version of odoo
  Future<OdooVersion> getVersionInfo() async {
    var url = createPath("/web/webclient/version_info");
    final response = await callRequest(url, createPayload({}));
    odooVersion = OdooVersion().parse(response);
    return odooVersion;
  }

  Future<List> getDatabases() async {
    if (odooVersion.getMajorVersion() == null) {
      odooVersion = await getVersionInfo();
    }
    String url = getServerURL();
    var params = {};
    if (odooVersion.getMajorVersion() == 9) {
      url = createPath("/jsonrpc");
      params["method"] = "list";
      params["service"] = "db";
      params["args"] = [];
    } else if (odooVersion.getMajorVersion() >= 10) {
      url = createPath("/web/database/list");
      params["context"] = {};
    } else {
      url = createPath("/web/database/get_list");
      params["context"] = {};
    }
    final response = await callRequest(url, createPayload(params));
    _databases = response.getResult();
    return _databases;
  }

  void debugRPC(bool debug) {
    _debugRPC = debug;
  }

  String getServerURL() {
    return _serverURL;
  }

  String createPath(String path) {
    return _serverURL + path;
  }

  Map createPayload(Map params) {
    return {
      "jsonrpc": "2.0",
      "method": "call",
      "params": params,
      "id": new Uuid().v1()
    };
  }

  Future<OdooResponse> callRequest(String url, Map payload) async {
    var body = json.encode(payload);
    _headers["Content-type"] = "application/json";
    if (_sessionId != null) {
      _headers['Cookie'] = "session_id=" + _sessionId!;
    }
    if (_debugRPC) {
      print("-------------------------------------------");
      print("REQUEST: $url");
      print("PAYLOD : $payload");
      print("HEADERS: $_headers");
      print("-------------------------------------------");
    }
    final response = await _client.post(Uri.parse(url), body: body, headers: _headers);
    var sessionId = _updateCookies(response);
    if (_debugRPC) {
      print("============================================");
      print("STATUS_C: ${response.statusCode}");
      print("RESPONSE: ${response.body}");
      print("============================================");
    }
    return new OdooResponse(
        json.decode(response.body), response.statusCode, sessionId);
  }

  _updateCookies(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      String cookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
      _headers['Cookie'] = cookie;
      if (index > -1) {
        return cookie.split("=")[1];
      }
    }
    return null;
  }
}

class OdooResponse {
  var _result, _statusCode, _sessionId;

  OdooResponse(Map result, int statusCode, String? newSessionId) {
    _result = result;
    _statusCode = statusCode;
    _sessionId = newSessionId;
  }

  bool hasError() {
    return _result['error'] != null;
  }

  Map getError() {
    return _result['error'];
  }

  String? getSessionId() {
    return _sessionId;
  }

  String? getErrorMessage() {
    if (hasError()) {
      return _result['error']['message'];
    }
    return null;
  }

  int getStatusCode() {
    return _statusCode;
  }

  dynamic getResult() {
    return _result['result'];
  }
}

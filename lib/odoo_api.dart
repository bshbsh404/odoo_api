library odoo_api;

import 'dart:async';

import 'odoo_api_connector.dart';
import 'odoo_user_response.dart';

class OdooClient extends OdooConnector {
  OdooClient(String serverURL) : super(serverURL);

  // Get session information
  Future<OdooResponse> getSessionInfo() async {
    var url = createPath("/web/session/get_session_info");
    return await callRequest(url, createPayload({}));
  }

  // Authenticate user
  Future<AuthenticateCallback> authenticate(
      String username, String password, String database) async {
    var url = createPath("/web/session/authenticate");
    var params = {
      "db": database,
      "login": username,
      "password": password,
      "context": {}
    };
    final response = await callRequest(url, createPayload(params));
    final session = await getSessionInfo();
    return new AuthenticateCallback(
        !response.hasError(), response, session.getSessionId());
  }

  // Read records with given ids and fields
  Future<OdooResponse> read(String model, List<int> ids, List<String> fields,
      {dynamic kwargs, Map? context}) async {
    return await callKW(model, "read", [ids, fields],
        kwargs: kwargs, context: context);
  }

  // Search and read based on domain filters
  Future<OdooResponse> searchRead(
      String model, List domain, List<String> fields,
      {int offset = 0, int limit = 0, String order = "create_date"}) async {
    var url = createPath("/web/dataset/search_read");
    var params = {
      "model": model,
      "fields": fields,
      "domain": domain,
      "context": {},
      "offset": offset,
      "limit": limit,
      "sort": order
    };
    return await callRequest(url, createPayload(params));
  }

  // Call any model method with arguments
  Future<OdooResponse> callKW(String model, String method, List args,
      {dynamic kwargs, Map? context}) async {
    kwargs = kwargs == null ? {} : kwargs;
    context = context == null ? {} : context;
    var url = createPath("/web/dataset/call_kw/" + model + "/" + method);
    var params = {
      "model": model,
      "method": method,
      "args": args,
      "kwargs": kwargs,
      "context": context
    };
    return await callRequest(url, createPayload(params));
  }

  // Create new record for model
  Future<OdooResponse> create(String model, Map values) async {
    return await callKW(model, "create", [values]);
  }

  // Write record with ids and values
  Future<OdooResponse> write(String model, List<int> ids, Map values) async {
    return await callKW(model, "write", [ids, values]);
  }

  // Remove record from system
  Future<OdooResponse> unlink(String model, List<int> ids) async {
    return await callKW(model, "unlink", [ids]);
  }

  // Call json controller
  Future<OdooResponse> callController(String path, Map params) async {
    return await callRequest(createPath(path), createPayload(params));
  }
}

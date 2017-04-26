//
//  WebHandlers.swift
//  Perfect-OAuth2-Server
//
//  Created by Jonathan Guthrie on 2017-02-06.
//
//

import PerfectHTTP
import PerfectSession
import PerfectCrypto
import PerfectSessionPostgreSQL


class JSONHandlers {

	public static func logout(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			if let _ = request.session?.token {
				PostgresSessions().destroy(request, response)
				request.session = PerfectSession()
				response.request.session = PerfectSession()
			}
			_ = try? response.setBody(json: ["msg":"logout_success"])
			response.completed()
		}
	}

	// POST request for register form
	static func register(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			if let i = request.session?.userid, !i.isEmpty {
				_ = try? response.setBody(json: ["msg":"Already logged in"])
				response.completed()
				return
			}


			if let postBody = request.postBodyString, !postBody.isEmpty {
				do {
					let postBodyJSON = try postBody.jsonDecode() as? [String: String] ?? [String: String]()
					if let u = postBodyJSON["username"], !u.isEmpty,
						let e = postBodyJSON["email"], !e.isEmpty {
						let err = Account.register(u, e, .provisional)
						if err != .noError {
							Handlers.error(request, response, error: "Registration Error: \(err)", code: .badRequest)
							return
						} else {
							_ = try response.setBody(json: ["error":"Registration Success", "msg":"Check your email for an email from us. It contains instructions to complete your signup!"])
							response.completed()
							return
						}
					} else {
						Handlers.error(request, response, error: "Please supply a username and password", code: .badRequest)
						return
					}
				} catch {
					Handlers.error(request, response, error: "Invalid JSON", code: .badRequest)
					return
				}
			} else {
				Handlers.error(request, response, error: "Registration Error: Insufficient Data", code: .badRequest)
				return
			}

		}
	}

	// POST request for login form
	static func login(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			if let i = request.session?.userid, !i.isEmpty {
				_ = try? response.setBody(json: ["msg":"Already logged in"])
				response.completed()
				return
			}


			if let postBody = request.postBodyString, !postBody.isEmpty {
				do {
					let postBodyJSON = try postBody.jsonDecode() as? [String: String] ?? [String: String]()
					if let u = postBodyJSON["username"], !u.isEmpty,
						let p = postBodyJSON["password"], !p.isEmpty {

						do{
							let acc = try Account.login(u, p)
							request.session?.userid = acc.id
							_ = try response.setBody(json: ["error":"Login Success"])
							response.completed()
							return
						} catch {
							Handlers.error(request, response, error: "Login Failure", code: .badRequest)
							return
						}
					} else {
						Handlers.error(request, response, error: "Please supply a username and password", code: .badRequest)
						return
					}
				} catch {
					Handlers.error(request, response, error: "Invalid JSON", code: .badRequest)
					return
				}
			} else {
				Handlers.error(request, response, error: "Login Error: Insufficient Data", code: .badRequest)
				return
			}
		}
	}




	// SESSION request
	// Returns the SessionID and CSRF Token
	// Note that if an "Authorization" Header with a Bearer token is sent
	// this will echo the same session token and provide the Session's CSRF token
	static func session(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			_ = try? response.setBody(json: ["sessionid":request.session?.token, "csrf": request.session?.data["csrf"]])
			response.completed()
		}
	}

}

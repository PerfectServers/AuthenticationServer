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


class WebHandlers {

	static func main(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			var context: [String : Any] = ["title": "Perfect Authentication Server"]
			if let i = request.session?.userid, !i.isEmpty { context["authenticated"] = true }
			context["csrfToken"] = request.session?.data["csrf"] as? String ?? ""
			response.render(template: "views/index", context: context)
		}
	}
	public static func logout(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			if let _ = request.session?.token {
				PostgresSessions().destroy(request, response)
				request.session = PerfectSession()
				response.request.session = PerfectSession()
			}
			response.redirect(path: "/")
		}
	}


	// Register GET - displays form
	static func register(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			if let i = request.session?.userid, !i.isEmpty { response.redirect(path: "/") }
			let t = request.session?.data["csrf"] as? String ?? ""

			var context: [String : Any] = ["title": "Perfect Authentication Server"]
			context["csrfToken"] = t
			response.render(template: "views/register", context: context)
		}
	}


	// POST request for register form
	static func registerPost(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			if let i = request.session?.userid, !i.isEmpty { response.redirect(path: "/") }
			var context: [String : Any] = ["title": "Perfect Authentication Server"]

			if let u = request.param(name: "username"), !(u as String).isEmpty,
				let e = request.param(name: "email"), !(e as String).isEmpty {
				let err = Account.register(u, e, .provisional)
				if err != .noError {
					print(err)
					context["msg_title"] = "Registration Error."
					context["msg_body"] = "\(err)"
				} else {
					context["msg_title"] = "You are registered."
					context["msg_body"] = "Check your email for an email from us. It contains instructions to complete your signup!"
				}
			} else {

			}
			response.render(template: "views/msg", context: context)
		}
	}

	// POST request for login
	static func login(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			var template = "views/msg" // where it goes to after
			if let i = request.session?.userid, !i.isEmpty { response.redirect(path: "/") }
			var context: [String : Any] = ["title": "Perfect Authentication Server"]
			context["csrfToken"] = request.session?.data["csrf"] as? String ?? ""

			if let u = request.param(name: "username"), !(u as String).isEmpty,
				let p = request.param(name: "password"), !(p as String).isEmpty {
				do {
					let acc = try Account.login(u, p)
					request.session?.userid = acc.id
					context["msg_title"] = "Login Successful."
					context["msg_body"] = ""
					response.redirect(path: "/")
				} catch {
					context["msg_title"] = "Login Error."
					context["msg_body"] = "Username or password incorrect"
					template = "views/index"
				}
			} else {
				context["msg_title"] = "Login Error."
				context["msg_body"] = "Username or password not supplied"
				template = "views/index"
			}
			response.render(template: template, context: context)
		}
	}


	// Verify GET
	static func registerVerify(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			let t = request.session?.data["csrf"] as? String ?? ""
			if let i = request.session?.userid, !i.isEmpty { response.redirect(path: "/") }
			var context: [String : Any] = ["title": "Perfect Authentication Server"]

			if let v = request.urlVariables["passvalidation"], !(v as String).isEmpty {

				let acc = Account(validation: v)

				if acc.id.isEmpty {
					context["msg_title"] = "Account Validation Error."
					context["msg_body"] = ""
					response.render(template: "views/msg", context: context)
					return
				} else {
					context["passvalidation"] = v
					context["csrfToken"] = t
					response.render(template: "views/registerComplete", context: context)
				}
			} else {
				context["msg_title"] = "Account Validation Error."
				context["msg_body"] = "Code not found."
				response.render(template: "views/msg", context: context)
			}
		}
	}


	// registerCompletion
	static func registerCompletion(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			let t = request.session?.data["csrf"] as? String ?? ""
			if let i = request.session?.userid, !i.isEmpty { response.redirect(path: "/") }
			var context: [String : Any] = ["title": "Perfect Authentication Server"]

			if let v = request.param(name: "passvalidation"), !(v as String).isEmpty {

				let acc = Account(validation: v)

				if acc.id.isEmpty {
					context["msg_title"] = "Account Validation Error."
					context["msg_body"] = ""
					response.render(template: "views/msg", context: context)
					return
				} else {

					if let p1 = request.param(name: "p1"), !(p1 as String).isEmpty,
						let p2 = request.param(name: "p2"), !(p2 as String).isEmpty,
						p1 == p2 {

						if let digestBytes = p1.digest(.sha256),
							let hexBytes = digestBytes.encode(.hex),
							let hexBytesStr = String(validatingUTF8: hexBytes) {
							print(hexBytesStr)
							acc.password = hexBytesStr

//							let digestBytes2 = p1.digest(.sha256)
//							let hexBytes2 = digestBytes2?.encode(.hex)
//							let hexBytesStr2 = String(validatingUTF8: hexBytes2!)
//							print(hexBytesStr2)
						}
//						acc.password = BCrypt.hash(password: p1)
						acc.usertype = .standard
						do {
							try acc.save()
							request.session?.userid = acc.id
							context["msg_title"] = "Account Validated and Completed."
							context["msg_body"] = "<p><a class=\"button\" href=\"/\">Click to continue</a></p>"
							response.render(template: "views/msg", context: context)

						} catch {
							print(error)
						}
					} else {
						context["msg_body"] = "<p>Account Validation Error: The passwords must not be empty, and must match.</p>"
						context["passvalidation"] = v
						context["csrfToken"] = t
						response.render(template: "views/registerComplete", context: context)
						return
					}

				}
			} else {
				context["msg_title"] = "Account Validation Error."
				context["msg_body"] = "Code not found."
				response.render(template: "views/msg", context: context)
			}
		}
	}
}

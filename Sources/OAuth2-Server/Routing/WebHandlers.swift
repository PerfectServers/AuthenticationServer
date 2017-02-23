//
//  WebHandlers.swift
//  Perfect-OAuth2-Server
//
//  Created by Jonathan Guthrie on 2017-02-06.
//
//

import PerfectHTTP
import PerfectSession
import TurnstileCrypto


class WebHandlers {

	static func main(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			var context: [String : Any] = ["title": "Perfect Authentication Server"]
			if let i = request.session?.userid, !i.isEmpty { context["authenticated"] = true }
			response.render(template: "views/index", context: context)
		}
	}
	public static func logout(data: [String:Any]) throws -> RequestHandler {
		return {
			request, response in
			if let _ = request.session?.token {
				MemorySessions.destroy(request, response)
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
						acc.password = BCrypt.hash(password: p1)
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

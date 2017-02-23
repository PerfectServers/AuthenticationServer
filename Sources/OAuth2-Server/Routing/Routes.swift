//
//  WebHandlers.swift
//  Perfect-OAuth2-Server
//
//  Created by Jonathan Guthrie on 2017-02-06.
//
//

import PerfectHTTPServer

func mainRoutes() -> [[String: Any]] {

	var routes: [[String: Any]] = [[String: Any]]()
	routes.append(["method":"get", "uri":"/", "handler":WebHandlers.main])
	routes.append(["method":"get", "uri":"/logout", "handler":WebHandlers.logout])

	routes.append(["method":"get", "uri":"/register", "handler":WebHandlers.register])
	routes.append(["method":"post", "uri":"/register", "handler":WebHandlers.registerPost])
	routes.append(["method":"get", "uri":"/verifyAccount/{passvalidation}", "handler":WebHandlers.registerVerify])
	routes.append(["method":"post", "uri":"/registrationCompletion", "handler":WebHandlers.registerCompletion])

	routes.append(["method":"get", "uri":"/**", "handler":PerfectHTTPServer.HTTPHandler.staticFiles,
	               "documentRoot":"./webroot",
	               "allowResponseFilters":true])

	return routes
}
